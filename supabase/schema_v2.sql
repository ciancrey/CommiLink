-- =====================================================================
-- CommiLink database · PART 2 (run AFTER schema.sql)
--
-- Adds the backend for the Figma screens 22-27:
--   Messages + Chat      -> messages table (one chat per commission)
--   Alerts               -> notifications table, filled automatically
--   Post a service       -> portfolio images on services
--   Network              -> freelancer_directory view
--   Deliver / attach     -> order_files table + private storage bucket
--   Admin dispute review -> freelancer response + dispute numbers
--
-- Safe to run more than once.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Small changes to existing tables
-- ---------------------------------------------------------------------

-- Figma limits: price 50 - 50,000 pesos, delivery 1 - 60 days.
alter table public.services drop constraint if exists services_price_check;
alter table public.services drop constraint if exists services_price_range;
alter table public.services add constraint services_price_range
  check (price between 50 and 50000) not valid;
alter table public.services drop constraint if exists services_delivery_days_check;
alter table public.services drop constraint if exists services_delivery_range;
alter table public.services add constraint services_delivery_range
  check (delivery_days between 1 and 60) not valid;

-- Portfolio images (public URLs), up to 5.
alter table public.services add column if not exists image_urls text[] not null default '{}';

-- Dispute details for the admin review page.
create sequence if not exists public.dispute_number_seq start 100;
alter table public.orders add column if not exists dispute_number  integer;
alter table public.orders add column if not exists dispute_response text;
alter table public.orders add column if not exists dispute_response_at timestamptz;
alter table public.orders add column if not exists delivered_at    timestamptz;
alter table public.orders add column if not exists resolved_at     timestamptz;
alter table public.orders add column if not exists resolution      text;  -- 'released' | 'refunded'

-- ---------------------------------------------------------------------
-- NEW TABLES
-- ---------------------------------------------------------------------

-- Chat messages. Every chat belongs to one commission (order).
create table if not exists public.messages (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders (id) on delete cascade,
  sender_id   uuid not null references public.profiles (id),
  body        text not null default '',
  file_id     uuid,                       -- optional attachment (order_files.id)
  created_at  timestamptz not null default now(),
  read_at     timestamptz                 -- set when the other person opens the chat
);
create index if not exists messages_order_idx on public.messages (order_id, created_at);

-- Files attached to a commission (reference files, deliveries, chat files).
create table if not exists public.order_files (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references public.orders (id) on delete cascade,
  uploaded_by  uuid not null references public.profiles (id),
  kind         text not null check (kind in ('brief', 'delivery', 'chat', 'dispute')),
  path         text not null,             -- path inside the "order-files" bucket
  name         text not null,
  size_bytes   bigint not null default 0,
  created_at   timestamptz not null default now()
);
create index if not exists order_files_order_idx on public.order_files (order_id);

do $$ begin
  alter table public.messages
    add constraint messages_file_fk foreign key (file_id)
    references public.order_files (id) on delete set null;
exception when duplicate_object then null;
end $$;

-- Alerts. Written only by the database (triggers below).
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        text not null,   -- accepted, delivered, held, topup, dispute, refund, released, request, completed
  title       text not null,
  body        text not null default '',
  order_id    uuid references public.orders (id) on delete cascade,
  created_at  timestamptz not null default now(),
  read_at     timestamptz
);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

grant select, insert on public.messages to authenticated;
grant select, insert on public.order_files to authenticated;
grant select on public.notifications to authenticated;

-- ---------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------

-- Is the signed-in user the client or freelancer on this order (or admin)?
create or replace function public.is_order_member(p_order_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from orders
    where id = p_order_id
      and (client_id = auth.uid() or freelancer_id = auth.uid())
  ) or public.is_admin();
$$;

-- Same check for a storage path "<order_id>/file". Returns false (instead of
-- failing) when the first folder is not an order id.
create or replace function public.can_use_order_path(p_name text)
returns boolean
language plpgsql stable security definer set search_path = public
as $$
declare v_first text := split_part(p_name, '/', 1);
begin
  if v_first !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  return public.is_order_member(v_first::uuid);
end;
$$;
grant execute on function public.can_use_order_path(text) to authenticated;

create or replace function public._notify(
  p_user uuid, p_kind text, p_title text, p_body text, p_order uuid)
returns void
language sql security definer set search_path = public
as $$
  insert into notifications (user_id, kind, title, body, order_id)
  values (p_user, p_kind, p_title, p_body, p_order);
$$;
revoke all on function public._notify(uuid, text, text, text, uuid) from public, anon, authenticated;

create or replace function public._peso(p_amount bigint)
returns text language sql immutable
as $$ select '₱' || to_char(p_amount, 'FM999,999,999') || '.00' $$;

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------

alter table public.messages      enable row level security;
alter table public.order_files   enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "read order messages" on public.messages;
create policy "read order messages" on public.messages
  for select to authenticated using (public.is_order_member(order_id));

drop policy if exists "send order messages" on public.messages;
create policy "send order messages" on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_order_member(order_id));

drop policy if exists "read order files" on public.order_files;
create policy "read order files" on public.order_files
  for select to authenticated using (public.is_order_member(order_id));

drop policy if exists "add order files" on public.order_files;
create policy "add order files" on public.order_files
  for insert to authenticated
  with check (uploaded_by = auth.uid() and public.is_order_member(order_id));

drop policy if exists "read own notifications" on public.notifications;
create policy "read own notifications" on public.notifications
  for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- VIEWS
-- ---------------------------------------------------------------------

-- Updated: services now include portfolio images.
-- (drop first because the column list changes)
drop view if exists public.service_listings;
create view public.service_listings
with (security_invoker = true) as
select
  s.id,
  s.freelancer_id,
  p.full_name                                  as freelancer_name,
  p.headline                                   as role,
  p.avatar_url                                 as freelancer_avatar,
  s.title,
  s.description,
  s.category,
  s.price,
  s.delivery_days,
  s.is_active,
  s.image_urls,
  s.created_at,
  coalesce(round(avg(r.rating)::numeric, 1), 0)::float8 as rating,
  count(r.order_id)::int                       as review_count
from public.services s
join public.profiles p on p.id = s.freelancer_id
left join public.reviews r on r.service_id = s.id
group by s.id, p.full_name, p.headline, p.avatar_url;
grant select on public.service_listings to authenticated;

-- Updated: orders now include dispute + delivery details and the
-- number of unread chat messages for the signed-in user.
drop view if exists public.order_details;
create view public.order_details
with (security_invoker = true) as
select
  o.*,
  c.full_name      as client_name,
  f.full_name      as freelancer_name,
  f.headline       as freelancer_role,
  s.title          as service_title,
  s.description    as service_description,
  s.category       as service_category,
  s.delivery_days  as service_delivery_days,
  r.rating         as review_rating,
  r.text           as review_text
from public.orders o
join public.profiles c on c.id = o.client_id
join public.profiles f on f.id = o.freelancer_id
join public.services s on s.id = o.service_id
left join public.reviews r on r.order_id = o.id;
grant select on public.order_details to authenticated;

-- Messages tab: one row per commission chat, with the last message.
create or replace view public.conversations
with (security_invoker = true) as
select
  o.id                                   as order_id,
  o.status,
  o.amount,
  o.client_id,
  o.freelancer_id,
  c.full_name                            as client_name,
  f.full_name                            as freelancer_name,
  s.title                                as service_title,
  s.category                             as service_category,
  lm.body                                as last_body,
  lm.sender_id                           as last_sender_id,
  lm.has_file                            as last_has_file,
  coalesce(lm.created_at, o.created_at)  as last_at,
  (select count(*) from public.messages m
     where m.order_id = o.id and m.sender_id <> auth.uid() and m.read_at is null)::int
                                         as unread_count
from public.orders o
join public.profiles c on c.id = o.client_id
join public.profiles f on f.id = o.freelancer_id
join public.services s on s.id = o.service_id
left join lateral (
  select m.body, m.sender_id, m.created_at, (m.file_id is not null) as has_file
  from public.messages m
  where m.order_id = o.id
  order by m.created_at desc
  limit 1
) lm on true;
grant select on public.conversations to authenticated;

-- Network tab: every freelancer with rating, finished jobs and categories.
-- Completed-job count (security definer so everyone sees the real number,
-- not just orders they are part of).
create or replace function public.completed_jobs(p_freelancer uuid)
returns integer
language sql stable security definer set search_path = public
as $$
  select count(*)::int from orders where freelancer_id = p_freelancer and status = 'Completed';
$$;
grant execute on function public.completed_jobs(uuid) to authenticated;

create or replace view public.freelancer_directory
with (security_invoker = true) as
select
  p.id,
  p.full_name,
  p.headline,
  p.avatar_url,
  coalesce((select round(avg(r.rating)::numeric, 1)::float8
              from public.reviews r where r.freelancer_id = p.id), 0) as rating,
  (select count(*) from public.reviews r where r.freelancer_id = p.id)::int as review_count,
  public.completed_jobs(p.id)                                             as jobs_done,
  coalesce((select array_agg(distinct s.category) from public.services s
              where s.freelancer_id = p.id and s.is_active), '{}')       as categories,
  (select count(*) from public.services s
     where s.freelancer_id = p.id and s.is_active)::int                  as service_count
from public.profiles p
where p.role = 'freelancer';
grant select on public.freelancer_directory to authenticated;

-- ---------------------------------------------------------------------
-- FUNCTIONS the app calls
-- ---------------------------------------------------------------------

-- Mark the other person's messages in a chat as read.
create or replace function public.mark_chat_read(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_order_member(p_order_id) then raise exception 'Not allowed'; end if;
  update messages set read_at = now()
  where order_id = p_order_id and sender_id <> auth.uid() and read_at is null;
end;
$$;

create or replace function public.mark_alerts_read(p_id uuid default null)
returns void
language sql security definer set search_path = public
as $$
  update notifications set read_at = now()
  where user_id = auth.uid() and read_at is null and (p_id is null or id = p_id);
$$;

-- Freelancer answers a dispute (shown on the admin review page).
create or replace function public.respond_dispute(p_order_id uuid, p_note text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders
  set dispute_response = nullif(trim(coalesce(p_note, '')), ''),
      dispute_response_at = now(), updated_at = now()
  where id = p_order_id and freelancer_id = auth.uid() and status = 'Disputed';
  if not found then raise exception 'You can only reply to an open dispute on your order'; end if;
end;
$$;

-- Replace: deliver also records the delivery time.
create or replace function public.deliver_order(p_order_id uuid, p_note text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders
  set status = 'Delivered', delivery_note = nullif(trim(coalesce(p_note, '')), ''),
      delivered_at = now(), updated_at = now()
  where id = p_order_id and freelancer_id = auth.uid() and status = 'In progress';
  if not found then raise exception 'Order cannot be delivered'; end if;
end;
$$;

-- Replace: opening a dispute gives it a number (#DP-0142).
create or replace function public.open_dispute(p_order_id uuid, p_reason text, p_note text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders
  set status = 'Disputed', dispute_reason = p_reason, dispute_note = p_note,
      disputed_at = now(), updated_at = now(),
      dispute_number = coalesce(dispute_number, nextval('dispute_number_seq')::int)
  where id = p_order_id and client_id = auth.uid() and status = 'Delivered';
  if not found then raise exception 'This order cannot be reported'; end if;
end;
$$;

-- Replace: resolving a dispute records the decision.
create or replace function public.resolve_dispute(p_order_id uuid, p_refund boolean)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_order orders%rowtype;
begin
  if not public.is_admin() then raise exception 'Only admins can resolve disputes'; end if;

  select * into v_order from orders where id = p_order_id for update;
  if not found or v_order.status <> 'Disputed' then
    raise exception 'Order is not in dispute';
  end if;

  if p_refund then
    update orders set status = 'Refunded', resolution = 'refunded',
                      resolved_at = now(), updated_at = now()
    where id = p_order_id;
    update wallets set balance = balance + v_order.amount, updated_at = now()
    where user_id = v_order.client_id;
    perform _add_txn(v_order.client_id, v_order.id, 'Refund',
                     'Dispute decided in your favor', v_order.amount);
  else
    update orders set status = 'Completed', resolution = 'released',
                      resolved_at = now(), updated_at = now()
    where id = p_order_id;
    perform _pay_freelancer(v_order);
  end if;
end;
$$;

grant execute on function public.mark_chat_read(uuid)          to authenticated;
grant execute on function public.mark_alerts_read(uuid)        to authenticated;
grant execute on function public.respond_dispute(uuid, text)   to authenticated;
grant execute on function public.is_order_member(uuid)         to authenticated;

-- ---------------------------------------------------------------------
-- AUTOMATIC ALERTS
-- ---------------------------------------------------------------------

create or replace function public.order_alerts()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_title  text;
  v_client text;
  v_free   text;
  v_admin  uuid;
begin
  select title into v_title from services where id = new.service_id;
  select full_name into v_client from profiles where id = new.client_id;
  select full_name into v_free from profiles where id = new.freelancer_id;

  if tg_op = 'INSERT' then
    perform _notify(new.freelancer_id, 'request', 'New request',
      v_client || ' requested “' || v_title || '”. ' || _peso(new.amount) || ' is held by CommiLink.', new.id);
    perform _notify(new.client_id, 'held', 'Payment held',
      _peso(new.amount) || ' is now held by CommiLink until you confirm the work.', new.id);
    return new;
  end if;

  if new.status is not distinct from old.status then return new; end if;

  if new.status = 'In progress' then
    perform _notify(new.client_id, 'accepted', 'Request accepted',
      v_free || ' accepted “' || v_title || '”.', new.id);
  elsif new.status = 'Delivered' then
    perform _notify(new.client_id, 'delivered', 'Work delivered',
      v_free || ' delivered your commission. Confirm within 3 days to release ' || _peso(new.amount) || '.', new.id);
  elsif new.status = 'Completed' then
    perform _notify(new.freelancer_id, 'released', 'Payment released',
      _peso(new.amount) || ' for “' || v_title || '” was added to your wallet.', new.id);
    if old.status = 'Disputed' then
      perform _notify(new.client_id, 'dispute', 'Dispute resolved',
        'CommiLink resolved dispute #DP-' || lpad(coalesce(new.dispute_number, 0)::text, 4, '0')
        || ' — the payment was released to ' || v_free || '.', new.id);
    end if;
  elsif new.status = 'Disputed' then
    perform _notify(new.freelancer_id, 'dispute', 'Problem reported',
      v_client || ' reported a problem: ' || coalesce(new.dispute_reason, '') || '. Reply from the commission page.', new.id);
    for v_admin in select id from profiles where role = 'admin' loop
      perform _notify(v_admin, 'dispute', 'New dispute #DP-' || lpad(coalesce(new.dispute_number, 0)::text, 4, '0'),
        v_client || ' vs ' || v_free || ' · ' || _peso(new.amount) || ' on hold.', new.id);
    end loop;
  elsif new.status = 'Refunded' then
    if old.status = 'Disputed' then
      perform _notify(new.client_id, 'refund', 'Dispute resolved',
        'CommiLink resolved dispute #DP-' || lpad(coalesce(new.dispute_number, 0)::text, 4, '0')
        || ' — a full refund was issued.', new.id);
      perform _notify(new.freelancer_id, 'dispute', 'Dispute resolved',
        'CommiLink refunded the client for “' || v_title || '”.', new.id);
    else
      perform _notify(new.client_id, 'refund', 'Request cancelled',
        _peso(new.amount) || ' was returned to your wallet.', new.id);
      perform _notify(new.freelancer_id, 'refund', 'Request cancelled',
        '“' || v_title || '” was cancelled before it started.', new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_alerts on public.orders;
create trigger orders_alerts
  after insert or update of status on public.orders
  for each row execute function public.order_alerts();

create or replace function public.topup_alerts()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.title = 'MockPay top-up' then
    perform _notify(new.user_id, 'topup', 'Top-up successful',
      _peso(new.amount) || ' was added to your wallet via MockPay.', null);
  end if;
  return new;
end;
$$;

drop trigger if exists wallet_txn_alerts on public.wallet_transactions;
create trigger wallet_txn_alerts
  after insert on public.wallet_transactions
  for each row execute function public.topup_alerts();

-- ---------------------------------------------------------------------
-- REALTIME
-- ---------------------------------------------------------------------
do $$
begin
  begin alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null; end;
end $$;

-- ---------------------------------------------------------------------
-- STORAGE
--   order-files : PRIVATE. Path = <order_id>/<file>. Only the client,
--                 freelancer and admins of that order can read/upload.
--   portfolio   : public images. Path = <user_id>/<file>.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('order-files', 'order-files', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('portfolio', 'portfolio', true)
on conflict (id) do nothing;

drop policy if exists "order files upload" on storage.objects;
create policy "order files upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'order-files' and public.can_use_order_path(name));

drop policy if exists "order files read" on storage.objects;
create policy "order files read" on storage.objects
  for select to authenticated
  using (bucket_id = 'order-files' and public.can_use_order_path(name));

drop policy if exists "portfolio upload own folder" on storage.objects;
create policy "portfolio upload own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text);
