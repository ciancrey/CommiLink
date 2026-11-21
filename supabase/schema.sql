-- =====================================================================
-- CommiLink database (Supabase / PostgreSQL)
--
-- HOW TO USE
--   1. Create a free project at https://supabase.com
--   2. Open  SQL Editor  ->  New query, paste this whole file, press Run.
--   3. (For testing) Authentication -> Providers -> Email:
--      turn OFF "Confirm email" so new accounts can sign in right away.
--   4. To make yourself an admin (to resolve disputes), sign up in the app,
--      then run:
--        update public.profiles set role = 'admin'
--        where id = (select id from auth.users where email = 'you@example.com');
--
-- All money moves (hold, release, refund, top-up) happen inside the
-- database functions at the bottom of this file, so the app can never
-- change a balance directly.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- TABLES
-- ---------------------------------------------------------------------

-- One row per user (created automatically when someone signs up).
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null,
  role        text not null default 'client'
              check (role in ('client', 'freelancer', 'admin')),
  headline    text not null default '',          -- e.g. "Graphic Designer"
  avatar_url  text,
  created_at  timestamptz not null default now()
);

-- Wallet balance in whole pesos.
create table if not exists public.wallets (
  user_id     uuid primary key references public.profiles (id) on delete cascade,
  balance     bigint not null default 0 check (balance >= 0),
  updated_at  timestamptz not null default now()
);

-- Services that freelancers post.
create table if not exists public.services (
  id             uuid primary key default gen_random_uuid(),
  freelancer_id  uuid not null references public.profiles (id) on delete cascade,
  title          text not null check (char_length(title) between 5 and 120),
  description    text not null default '',
  category       text not null
                 check (category in ('Design', 'Programming', 'Video', 'Writing')),
  price          integer not null check (price > 0),
  delivery_days  integer not null check (delivery_days between 1 and 90),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

-- Commissions (orders).
create table if not exists public.orders (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid not null references public.profiles (id),
  freelancer_id   uuid not null references public.profiles (id),
  service_id      uuid not null references public.services (id),
  brief           text not null,
  amount          integer not null check (amount > 0),
  status          text not null default 'Requested'
                  check (status in ('Requested', 'In progress', 'Delivered',
                                    'Completed', 'Disputed', 'Refunded')),
  delivery_note   text,
  dispute_reason  text,
  dispute_note    text,
  disputed_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists orders_client_idx on public.orders (client_id);
create index if not exists orders_freelancer_idx on public.orders (freelancer_id);

-- One review per completed order.
create table if not exists public.reviews (
  order_id       uuid primary key references public.orders (id) on delete cascade,
  service_id     uuid not null references public.services (id) on delete cascade,
  client_id      uuid not null references public.profiles (id),
  freelancer_id  uuid not null references public.profiles (id),
  rating         integer not null check (rating between 1 and 5),
  text           text not null default '',
  created_at     timestamptz not null default now()
);

-- Wallet history. Positive = money in, negative = money out.
create table if not exists public.wallet_transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  order_id    uuid references public.orders (id),
  title       text not null,
  subtitle    text not null default '',
  amount      bigint not null,
  created_at  timestamptz not null default now()
);
create index if not exists wallet_txn_user_idx on public.wallet_transactions (user_id, created_at desc);

-- ---------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- Create profile + empty wallet whenever a new auth user signs up.
-- full_name / role / headline come from the sign-up "data" sent by the app.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'client');
begin
  if v_role not in ('client', 'freelancer') then
    v_role := 'client';  -- nobody can sign up as admin
  end if;

  insert into profiles (id, full_name, role, headline)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(new.email, '@', 1)),
    v_role,
    coalesce(new.raw_user_meta_data ->> 'headline', '')
  );
  insert into wallets (user_id, balance) values (new.id, 0);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Stop users from promoting themselves to admin through a normal update.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
as $$
begin
  -- auth.uid() is null when you run SQL yourself in the Supabase dashboard.
  if new.role <> old.role and auth.uid() is not null and not public.is_admin() then
    raise exception 'You cannot change your role';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role
  before update on public.profiles
  for each row execute function public.protect_profile_role();

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY (who can read / write what)
-- ---------------------------------------------------------------------

alter table public.profiles            enable row level security;
alter table public.wallets             enable row level security;
alter table public.services            enable row level security;
alter table public.orders              enable row level security;
alter table public.reviews             enable row level security;
alter table public.wallet_transactions enable row level security;

drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "read own wallet" on public.wallets;
create policy "read own wallet" on public.wallets
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "services readable" on public.services;
create policy "services readable" on public.services
  for select to authenticated
  using (is_active or freelancer_id = auth.uid() or public.is_admin());

drop policy if exists "freelancers add services" on public.services;
create policy "freelancers add services" on public.services
  for insert to authenticated
  with check (
    freelancer_id = auth.uid()
    and exists (select 1 from public.profiles where id = auth.uid() and role = 'freelancer')
  );

drop policy if exists "freelancers edit own services" on public.services;
create policy "freelancers edit own services" on public.services
  for update to authenticated
  using (freelancer_id = auth.uid()) with check (freelancer_id = auth.uid());

-- Orders: read-only from the app. Changes go through the functions below.
drop policy if exists "read own orders" on public.orders;
create policy "read own orders" on public.orders
  for select to authenticated
  using (client_id = auth.uid() or freelancer_id = auth.uid() or public.is_admin());

drop policy if exists "reviews readable" on public.reviews;
create policy "reviews readable" on public.reviews
  for select to authenticated using (true);

drop policy if exists "read own transactions" on public.wallet_transactions;
create policy "read own transactions" on public.wallet_transactions
  for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- VIEWS the app reads from (they follow the RLS rules above)
-- ---------------------------------------------------------------------

create or replace view public.service_listings
with (security_invoker = true) as
select
  s.id,
  s.freelancer_id,
  p.full_name                                  as freelancer_name,
  p.headline                                   as role,
  s.title,
  s.description,
  s.category,
  s.price,
  s.delivery_days,
  s.is_active,
  s.created_at,
  coalesce(round(avg(r.rating)::numeric, 1), 0)::float8 as rating,
  count(r.order_id)::int                       as review_count
from public.services s
join public.profiles p on p.id = s.freelancer_id
left join public.reviews r on r.service_id = s.id
group by s.id, p.full_name, p.headline;

create or replace view public.order_details
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

grant select on public.service_listings to authenticated;
grant select on public.order_details to authenticated;

-- ---------------------------------------------------------------------
-- MONEY + ORDER FUNCTIONS (called from the app with supabase.rpc)
-- ---------------------------------------------------------------------

create or replace function public._add_txn(
  p_user uuid, p_order uuid, p_title text, p_subtitle text, p_amount bigint)
returns void
language sql security definer set search_path = public
as $$
  insert into wallet_transactions (user_id, order_id, title, subtitle, amount)
  values (p_user, p_order, p_title, p_subtitle, p_amount);
$$;
revoke all on function public._add_txn(uuid, uuid, text, text, bigint) from public, anon, authenticated;

-- Simulated top-up (MockPay). Replace with a real payment webhook later.
create or replace function public.mock_top_up(p_amount integer)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare v_balance bigint;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  if p_amount is null or p_amount < 100 or p_amount > 100000 then
    raise exception 'Top-up must be between 100 and 100,000';
  end if;

  update wallets set balance = balance + p_amount, updated_at = now()
  where user_id = auth.uid()
  returning balance into v_balance;

  perform _add_txn(auth.uid(), null, 'MockPay top-up', 'Wallet top-up (simulated)', p_amount);
  return v_balance;
end;
$$;

-- Client requests a service. Money is taken from the wallet and held.
create or replace function public.place_order(p_service_id uuid, p_brief text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_service services%rowtype;
  v_balance bigint;
  v_order   uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  if char_length(trim(coalesce(p_brief, ''))) < 10 then
    raise exception 'Please describe your request (at least 10 characters)';
  end if;

  select * into v_service from services where id = p_service_id and is_active;
  if not found then raise exception 'This service is no longer available'; end if;
  if v_service.freelancer_id = auth.uid() then
    raise exception 'You cannot order your own service';
  end if;

  select balance into v_balance from wallets where user_id = auth.uid() for update;
  if v_balance < v_service.price then
    raise exception 'Not enough wallet balance';
  end if;

  update wallets set balance = balance - v_service.price, updated_at = now()
  where user_id = auth.uid();

  insert into orders (client_id, freelancer_id, service_id, brief, amount)
  values (auth.uid(), v_service.freelancer_id, v_service.id, trim(p_brief), v_service.price)
  returning id into v_order;

  perform _add_txn(auth.uid(), v_order, 'Payment held', v_service.title, -v_service.price);
  return v_order;
end;
$$;

-- Freelancer accepts a new request.
create or replace function public.accept_order(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders set status = 'In progress', updated_at = now()
  where id = p_order_id and freelancer_id = auth.uid() and status = 'Requested';
  if not found then raise exception 'Order cannot be accepted'; end if;
end;
$$;

-- Client cancels, or freelancer declines, a request that was not accepted yet.
-- The held money goes back to the client.
create or replace function public.cancel_order(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_order orders%rowtype;
begin
  select * into v_order from orders where id = p_order_id for update;
  if not found
     or v_order.status <> 'Requested'
     or auth.uid() not in (v_order.client_id, v_order.freelancer_id) then
    raise exception 'Order cannot be cancelled';
  end if;

  update orders set status = 'Refunded', updated_at = now() where id = p_order_id;
  update wallets set balance = balance + v_order.amount, updated_at = now()
  where user_id = v_order.client_id;
  perform _add_txn(v_order.client_id, v_order.id, 'Refund',
                   'Request cancelled', v_order.amount);
end;
$$;

-- Freelancer delivers the work.
create or replace function public.deliver_order(p_order_id uuid, p_note text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders
  set status = 'Delivered', delivery_note = nullif(trim(coalesce(p_note, '')), ''),
      updated_at = now()
  where id = p_order_id and freelancer_id = auth.uid() and status = 'In progress';
  if not found then raise exception 'Order cannot be delivered'; end if;
end;
$$;

-- Internal: pay the freelancer for an order.
create or replace function public._pay_freelancer(v_order orders)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_title text;
begin
  select title into v_title from services where id = v_order.service_id;
  update wallets set balance = balance + v_order.amount, updated_at = now()
  where user_id = v_order.freelancer_id;
  perform _add_txn(v_order.freelancer_id, v_order.id, 'Payment received',
                   coalesce(v_title, 'Commission'), v_order.amount);
end;
$$;
revoke all on function public._pay_freelancer(orders) from public, anon, authenticated;

-- Client confirms the work. Held money goes to the freelancer.
create or replace function public.release_payment(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_order orders%rowtype;
begin
  select * into v_order from orders where id = p_order_id for update;
  if not found or v_order.client_id <> auth.uid() or v_order.status <> 'Delivered' then
    raise exception 'Payment cannot be released';
  end if;

  update orders set status = 'Completed', updated_at = now() where id = p_order_id;
  perform _pay_freelancer(v_order);
end;
$$;

-- Client reports a problem. Money stays on hold.
create or replace function public.open_dispute(p_order_id uuid, p_reason text, p_note text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update orders
  set status = 'Disputed', dispute_reason = p_reason, dispute_note = p_note,
      disputed_at = now(), updated_at = now()
  where id = p_order_id and client_id = auth.uid() and status = 'Delivered';
  if not found then raise exception 'This order cannot be reported'; end if;
end;
$$;

-- Admin decides a dispute: refund the client or pay the freelancer.
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
    update orders set status = 'Refunded', updated_at = now() where id = p_order_id;
    update wallets set balance = balance + v_order.amount, updated_at = now()
    where user_id = v_order.client_id;
    perform _add_txn(v_order.client_id, v_order.id, 'Refund',
                     'Dispute decided in your favor', v_order.amount);
  else
    update orders set status = 'Completed', updated_at = now() where id = p_order_id;
    perform _pay_freelancer(v_order);
  end if;
end;
$$;

-- Client leaves a review once the order is completed.
create or replace function public.submit_review(p_order_id uuid, p_rating integer, p_text text)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_order orders%rowtype;
begin
  select * into v_order from orders where id = p_order_id;
  if not found or v_order.client_id <> auth.uid() or v_order.status <> 'Completed' then
    raise exception 'You can only review your completed orders';
  end if;

  insert into reviews (order_id, service_id, client_id, freelancer_id, rating, text)
  values (v_order.id, v_order.service_id, v_order.client_id, v_order.freelancer_id, p_rating,
          coalesce(trim(p_text), ''));
exception when unique_violation then
  raise exception 'You already reviewed this order';
end;
$$;

grant execute on function public.mock_top_up(integer)               to authenticated;
grant execute on function public.place_order(uuid, text)            to authenticated;
grant execute on function public.accept_order(uuid)                 to authenticated;
grant execute on function public.cancel_order(uuid)                 to authenticated;
grant execute on function public.deliver_order(uuid, text)          to authenticated;
grant execute on function public.release_payment(uuid)              to authenticated;
grant execute on function public.open_dispute(uuid, text, text)     to authenticated;
grant execute on function public.resolve_dispute(uuid, boolean)     to authenticated;
grant execute on function public.submit_review(uuid, integer, text) to authenticated;

-- ---------------------------------------------------------------------
-- REALTIME (so the app updates when the other person changes an order)
-- ---------------------------------------------------------------------
do $$
begin
  begin
    alter publication supabase_realtime add table public.orders;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.wallets;
  exception when duplicate_object then null;
  end;
end $$;

-- ---------------------------------------------------------------------
-- STORAGE: profile photos (bucket "avatars", public read)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatar upload own folder" on storage.objects;
create policy "avatar upload own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatar update own folder" on storage.objects;
create policy "avatar update own folder" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
