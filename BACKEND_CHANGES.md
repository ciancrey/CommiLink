# Backend + database changes (Supabase)

## Setup (once)
1. Create a project at https://supabase.com
2. SQL Editor -> paste `supabase/schema.sql` -> Run
3. Authentication -> Providers -> Email: turn OFF "Confirm email" while testing
4. Project Settings -> API: copy Project URL + anon key into `lib/config/supabase_config.dart`
5. Android Studio: open pubspec.yaml -> click "Pub get", then run the app
6. Make an admin: `update public.profiles set role='admin' where id=(select id from auth.users where email='you@example.com');`

## New files
- supabase/schema.sql - all tables, security rules, money functions, storage bucket
- lib/config/supabase_config.dart - Supabase URL + key
- lib/screens/my_services_screen.dart - NEW PAGE: freelancer's services (show/hide)
- lib/screens/post_service_screen.dart - NEW PAGE: freelancer posts a service

## Changed files
- pubspec.yaml - added supabase_flutter
- android/app/src/main/AndroidManifest.xml - INTERNET permission
- lib/main.dart - connects to Supabase, keeps you signed in
- lib/data/app_state.dart - rewritten: loads/saves everything in Supabase
- lib/models/service.dart - freelancerId, reviewCount, isActive, fromMap
- lib/screens/sign_in_screen.dart - real login, forgot password; demo chips removed; goes to MainShell (was placeholder)
- lib/screens/create_account_screen.dart - real sign up + photo upload
- lib/screens/home_screen.dart - real services + user name, pull to refresh
- lib/screens/orders_screen.dart - real orders, client/freelancer/admin text
- lib/screens/order_detail_screen.dart - role-based buttons (accept/decline/deliver/release/report/cancel/admin resolve)
- lib/screens/request_commission_screen.dart - real order + top-up
- lib/screens/wallet_screen.dart - real top-up, earned stat for freelancers
- lib/screens/main_shell.dart, lib/widgets/app_drawer.dart - real name/role, My services, real sign out
- lib/widgets/service_card.dart, lib/screens/freelancer_profile_screen.dart - real rating/review count

## No longer used (safe to delete)
- lib/data/sample_services.dart
- lib/screens/home_placeholder_screen.dart

## Build fixes (made while running the app)
- lib/config/supabase_config.dart - filled in the CommiLink Supabase project URL + anon key
- android/gradle.properties - removed a Windows-only Java path (org.gradle.java.home=C:/...)
- android/gradle/wrapper/gradle-wrapper.properties - Gradle 8.10.2 -> 9.1.0 (needed for Java 25)
- android/settings.gradle - Android Gradle Plugin 8.7.0 -> 8.13.0, Kotlin 2.0.21 -> 2.2.20
- android/app/build.gradle - Java 1.8 -> 17, kotlinOptions -> kotlin.compilerOptions
- pubspec.yaml - google_fonts ^6.3.0 -> ^6.3.2 (6.3.0 does not compile on newer Flutter)
- supabase/schema.sql - explicit table permissions (the project has auto API access off)

## Round 2 · Figma screens 22-27 + their backend
Database: run `supabase/schema_v2.sql` AFTER `schema.sql` (already run on the CommiLink project).
- New tables: messages (chat per commission), notifications (alerts, written automatically by
  triggers), order_files (attachments). New views: conversations, freelancer_directory.
- New storage buckets: order-files (private, only the order's client/freelancer/admin) and
  portfolio (public images).
- services: image_urls (portfolio), price 50-50,000, delivery 1-60 days (Figma limits).
- orders: dispute_number (#DP-0100...), dispute_response, delivered_at, resolved_at, resolution.
- New functions: mark_chat_read, mark_alerts_read, respond_dispute; deliver/open/resolve dispute updated.

New pages
- lib/screens/messages_screen.dart   - 22 Messages (Messages tab)
- lib/screens/chat_screen.dart       - 23 Chat (live messages + file attachments)
- lib/screens/alerts_screen.dart     - 24 Alerts (Alerts tab, mark all as read)
- lib/screens/network_screen.dart    - 26 Network (Network tab, filters + search)
- lib/screens/admin_dispute_screen.dart - 27 Admin dispute review

New code
- lib/data/social_state.dart   - data for chat, alerts, files, network, dispute replies
- lib/widgets/initials_avatar.dart, lib/widgets/round_icon_button.dart

Changed
- lib/screens/post_service_screen.dart - rebuilt to match 25 (portfolio images, dropdown, limits)
- lib/screens/order_detail_screen.dart  - chat button, "Accepted" step, attached files,
  Deliver sheet with files (16), "Accept request" / "Decline & refund client" (14),
  "Mark as delivered" (15), freelancer reply to a dispute, admin "Review dispute" button
- lib/screens/request_commission_screen.dart - "Add reference files" now uploads files
- lib/screens/main_shell.dart + lib/widgets/app_bottom_nav.dart - real Network/Messages/Alerts
  tabs, unread dots
- lib/screens/orders_screen.dart - "Disputed" filter
- lib/screens/freelancer_profile_screen.dart - shows real portfolio images
- lib/data/app_state.dart, lib/models/service.dart - new fields + portfolio upload
- lib/widgets/app_top_bar.dart - optional right-side button
- pubspec.yaml - file_picker, url_launcher
- android/app/src/main/AndroidManifest.xml - lets the app open file links

- lib/screens/home_screen.dart - tapping the avatar on Home opens the side drawer
