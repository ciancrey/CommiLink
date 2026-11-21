import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service.dart';
import 'social_state.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// DateTime -> "Nov 19"
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

DateTime _date(dynamic v) => DateTime.parse(v as String).toLocal();

/// Friendly error the screens can show in a SnackBar.
class AppException implements Exception {
  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The signed-in user (row from the `profiles` table).
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.headline,
    this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: (m['full_name'] ?? '') as String,
        role: (m['role'] ?? 'client') as String,
        headline: (m['headline'] ?? '') as String,
        avatarUrl: m['avatar_url'] as String?,
      );

  final String id;
  final String fullName;

  /// client, freelancer or admin
  final String role;
  final String headline;
  final String? avatarUrl;

  bool get isClient => role == 'client';
  bool get isFreelancer => role == 'freelancer';
  bool get isAdmin => role == 'admin';

  String get roleLabel {
    if (headline.isNotEmpty) return headline;
    switch (role) {
      case 'freelancer':
        return 'Freelancer';
      case 'admin':
        return 'CommiLink admin';
      default:
        return 'Client';
    }
  }
}

/// A commission (row from the `order_details` database view).
class Order {
  Order({
    required this.id,
    required this.service,
    required this.clientId,
    required this.clientName,
    required this.freelancerId,
    required this.brief,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.deliveryNote,
    this.disputeReason,
    this.disputeNote,
    this.disputedAt,
    this.rating,
    this.review,
    this.disputeNumber,
    this.disputeResponse,
    this.deliveredAt,
    this.resolution,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    return Order(
      id: m['id'] as String,
      service: Service(
        id: m['service_id'] as String,
        freelancerId: m['freelancer_id'] as String,
        freelancerName: (m['freelancer_name'] ?? '') as String,
        role: (m['freelancer_role'] ?? '') as String,
        title: (m['service_title'] ?? '') as String,
        description: (m['service_description'] ?? '') as String,
        category: (m['service_category'] ?? '') as String,
        price: (m['amount'] as num).toInt(),
        deliveryDays: ((m['service_delivery_days'] ?? 0) as num).toInt(),
        rating: 0,
      ),
      clientId: m['client_id'] as String,
      clientName: (m['client_name'] ?? '') as String,
      freelancerId: m['freelancer_id'] as String,
      brief: (m['brief'] ?? '') as String,
      amount: (m['amount'] as num).toInt(),
      createdAt: _date(m['created_at']),
      status: (m['status'] ?? 'Requested') as String,
      deliveryNote: m['delivery_note'] as String?,
      disputeReason: m['dispute_reason'] as String?,
      disputeNote: m['dispute_note'] as String?,
      disputedAt:
          m['disputed_at'] == null ? null : _date(m['disputed_at']),
      rating: (m['review_rating'] as num?)?.toInt(),
      review: m['review_text'] as String?,
      disputeNumber: (m['dispute_number'] as num?)?.toInt(),
      disputeResponse: m['dispute_response'] as String?,
      deliveredAt:
          m['delivered_at'] == null ? null : _date(m['delivered_at']),
      resolution: m['resolution'] as String?,
    );
  }

  final String id;
  final Service service;
  final String clientId;
  final String clientName;
  final String freelancerId;
  final String brief;
  final int amount;
  final DateTime createdAt;

  /// Requested, In progress, Delivered, Completed, Disputed, Refunded
  final String status;

  final String? deliveryNote;
  final String? disputeReason;
  final String? disputeNote;
  final DateTime? disputedAt;
  final int? rating;
  final String? review;

  /// Dispute #DP-xxxx number, the freelancer's reply, and the admin decision.
  final int? disputeNumber;
  final String? disputeResponse;
  final DateTime? deliveredAt;

  /// released or refunded (after an admin decision)
  final String? resolution;

  /// Money for these orders is still held by CommiLink.
  bool get isActive =>
      status == 'Requested' ||
      status == 'In progress' ||
      status == 'Delivered' ||
      status == 'Disputed';
}

/// One line in the wallet history. Positive = money in, negative = money out.
class WalletTxn {
  const WalletTxn({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });

  factory WalletTxn.fromMap(Map<String, dynamic> m) => WalletTxn(
        title: (m['title'] ?? '') as String,
        subtitle: (m['subtitle'] ?? '') as String,
        amount: (m['amount'] as num).toInt(),
        date: _date(m['created_at']),
      );

  final String title;
  final String subtitle;
  final int amount;
  final DateTime date;
}

/// App data, now loaded from Supabase (see supabase/schema.sql).
///
/// Screens listen to the ValueNotifiers below. Every action calls a database
/// function and then reloads, so balances are always the server's numbers.
class AppState {
  AppState._();

  static final AppState instance = AppState._();

  SupabaseClient get _db => Supabase.instance.client;

  final ValueNotifier<Profile?> profile = ValueNotifier<Profile?>(null);
  final ValueNotifier<int> balance = ValueNotifier<int>(0);
  final ValueNotifier<List<Service>> services =
      ValueNotifier<List<Service>>([]);
  final ValueNotifier<List<Service>> myServices =
      ValueNotifier<List<Service>>([]);
  final ValueNotifier<List<Order>> orders = ValueNotifier<List<Order>>([]);
  final ValueNotifier<List<WalletTxn>> transactions =
      ValueNotifier<List<WalletTxn>>([]);

  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  String? get _uid => _db.auth.currentUser?.id;

  bool get isSignedIn => _db.auth.currentSession != null;

  String get userName => profile.value?.fullName ?? '';

  // ------------------------------------------------------------------
  // Numbers for the wallet / drawer
  // ------------------------------------------------------------------

  /// Money currently held by CommiLink for my active commissions.
  int get held =>
      orders.value.where((o) => o.isActive).fold(0, (sum, o) => sum + o.amount);

  int get activeCount => orders.value.where((o) => o.isActive).length;

  bool _thisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  /// Paid into commissions this month (refunds subtracted).
  int get spent {
    final month = transactions.value.where((t) => _thisMonth(t.date));
    final paid = month
        .where((t) => t.title == 'Payment held')
        .fold(0, (sum, t) => sum - t.amount);
    final back = month
        .where((t) => t.title == 'Refund')
        .fold(0, (sum, t) => sum + t.amount);
    final total = paid - back;
    return total < 0 ? 0 : total;
  }

  /// Money received from completed commissions this month (freelancers).
  int get earned => transactions.value
      .where((t) => t.title == 'Payment received' && _thisMonth(t.date))
      .fold(0, (sum, t) => sum + t.amount);

  int get refunded => transactions.value
      .where((t) => t.title == 'Refund')
      .fold(0, (sum, t) => sum + t.amount);

  bool canAfford(int amount) => balance.value >= amount;

  Order? findOrder(String id) {
    for (final o in orders.value) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Error handling
  // ------------------------------------------------------------------

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on AuthException catch (e) {
      throw AppException(e.message);
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } on StorageException catch (e) {
      throw AppException('Upload failed: ${e.message}');
    } catch (e) {
      debugPrint('CommiLink error: $e');
      throw AppException(
        'Something went wrong. Check your internet connection and try again.',
      );
    }
  }

  // ------------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------------

  /// Called once on app start. Loads data if the user is still signed in.
  Future<void> init() async {
    if (!isSignedIn) return;
    try {
      await refresh();
      _listenForChanges();
      await SocialState.instance.start();
    } catch (e) {
      debugPrint('CommiLink init error: $e');
    }
  }

  Future<void> signIn(String email, String password) => _guard(() async {
        await _db.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        await refresh();
        _listenForChanges();
        _startSocial();
      });

  /// Creates the account. Returns true if the user is signed in right away,
  /// false if Supabase wants them to confirm their email first.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    XFile? photo,
  }) =>
      _guard(() async {
        final res = await _db.auth.signUp(
          email: email.trim(),
          password: password,
          data: {
            'full_name': fullName.trim(),
            'role': role,
            'headline': role == 'freelancer' ? 'Freelancer' : '',
          },
        );

        if (res.session == null) return false; // email confirmation is on

        if (photo != null) {
          try {
            await _uploadAvatar(photo);
          } catch (e) {
            debugPrint('Avatar upload failed: $e');
          }
        }
        await refresh();
        _listenForChanges();
        _startSocial();
        return true;
      });

  Future<void> _uploadAvatar(XFile photo) async {
    final uid = _uid!;
    final bytes = await photo.readAsBytes();
    final path = '$uid/avatar.jpg';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    await _db.from('profiles').update({'avatar_url': url}).eq('id', uid);
  }

  /// Loads chats + alerts in the background (never blocks sign in).
  void _startSocial() {
    SocialState.instance
        .start()
        .catchError((Object e) => debugPrint('Social start error: $e'));
  }

  Future<void> sendPasswordReset(String email) => _guard(() async {
        await _db.auth.resetPasswordForEmail(email.trim());
      });

  Future<void> updateProfile({String? fullName, String? headline}) =>
      _guard(() async {
        final changes = <String, dynamic>{
          if (fullName != null) 'full_name': fullName.trim(),
          if (headline != null) 'headline': headline.trim(),
        };
        if (changes.isEmpty) return;
        await _db.from('profiles').update(changes).eq('id', _uid!);
        await refresh();
      });

  Future<void> signOut() async {
    await SocialState.instance.clear();
    if (_channel != null) {
      await _db.removeChannel(_channel!);
      _channel = null;
    }
    try {
      await _db.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    profile.value = null;
    balance.value = 0;
    services.value = [];
    myServices.value = [];
    orders.value = [];
    transactions.value = [];
  }

  /// Reload when an order or wallet changes on the server
  /// (e.g. the freelancer accepts while the client has the app open).
  void _listenForChanges() {
    if (_channel != null) return;
    void onChange(PostgresChangePayload _) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
        refresh().catchError((Object e) => debugPrint('Refresh error: $e'));
      });
    }

    _channel = _db
        .channel('commilink-${_uid ?? 'anon'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: onChange,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallets',
          callback: onChange,
        )
        .subscribe();
  }

  // ------------------------------------------------------------------
  // Loading data
  // ------------------------------------------------------------------

  Future<void> refresh() => _guard(() async {
        final uid = _uid;
        if (uid == null) return;

        final results = await Future.wait<dynamic>([
          _db.from('profiles').select().eq('id', uid).single(),
          _db.from('wallets').select('balance').eq('user_id', uid).maybeSingle(),
          _db
              .from('service_listings')
              .select()
              .eq('is_active', true)
              .order('created_at', ascending: false),
          _db
              .from('service_listings')
              .select()
              .eq('freelancer_id', uid)
              .order('created_at', ascending: false),
          _db
              .from('order_details')
              .select()
              .order('created_at', ascending: false),
          _db
              .from('wallet_transactions')
              .select()
              .eq('user_id', uid)
              .order('created_at', ascending: false)
              .limit(100),
        ]);

        profile.value = Profile.fromMap(results[0] as Map<String, dynamic>);
        final wallet = results[1] as Map<String, dynamic>?;
        balance.value = ((wallet?['balance'] ?? 0) as num).toInt();
        services.value = (results[2] as List)
            .map((m) => Service.fromMap(m as Map<String, dynamic>))
            .toList();
        myServices.value = (results[3] as List)
            .map((m) => Service.fromMap(m as Map<String, dynamic>))
            .toList();
        orders.value = (results[4] as List)
            .map((m) => Order.fromMap(m as Map<String, dynamic>))
            .toList();
        transactions.value = (results[5] as List)
            .map((m) => WalletTxn.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ------------------------------------------------------------------
  // Wallet + orders (each one is a database function in schema.sql)
  // ------------------------------------------------------------------

  Future<void> _rpc(String fn, [Map<String, dynamic>? params]) =>
      _guard(() async {
        await _db.rpc(fn, params: params);
        await refresh();
      });

  /// MockPay demo top-up (no real money).
  Future<void> topUp(int amount) => _rpc('mock_top_up', {'p_amount': amount});

  /// Takes the payment out of the wallet and creates the order.
  /// Returns the new order id.
  Future<String> placeOrder(Service service, String brief) => _guard(() async {
        final id = await _db.rpc('place_order', params: {
          'p_service_id': service.id,
          'p_brief': brief,
        });
        await refresh();
        return id as String;
      });

  /// Freelancer accepts a new request.
  Future<void> accept(Order order) =>
      _rpc('accept_order', {'p_order_id': order.id});

  /// Client cancels / freelancer declines before work starts. Refunds client.
  Future<void> cancel(Order order) =>
      _rpc('cancel_order', {'p_order_id': order.id});

  /// Freelancer marks the work as delivered.
  Future<void> deliver(Order order, String note) =>
      _rpc('deliver_order', {'p_order_id': order.id, 'p_note': note});

  /// Client confirms the work. The held payment goes to the freelancer.
  Future<void> release(Order order) =>
      _rpc('release_payment', {'p_order_id': order.id});

  /// Client reports a problem. The payment stays on hold.
  Future<void> dispute(Order order, String reason, String note) =>
      _rpc('open_dispute', {
        'p_order_id': order.id,
        'p_reason': reason,
        'p_note': note,
      });

  /// Admin decision on a dispute.
  Future<void> resolveDispute(Order order, {required bool refund}) =>
      _rpc('resolve_dispute', {'p_order_id': order.id, 'p_refund': refund});

  Future<void> submitReview(Order order, int rating, String text) =>
      _rpc('submit_review', {
        'p_order_id': order.id,
        'p_rating': rating,
        'p_text': text,
      });

  // ------------------------------------------------------------------
  // Freelancer services
  // ------------------------------------------------------------------

  Future<void> createService({
    required String title,
    required String description,
    required String category,
    required int price,
    required int deliveryDays,
    List<XFile> images = const [],
  }) =>
      _guard(() async {
        // Upload portfolio images first (public "portfolio" bucket).
        final urls = <String>[];
        for (var i = 0; i < images.length && i < 5; i++) {
          final bytes = await images[i].readAsBytes();
          final path =
              '$_uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _db.storage.from('portfolio').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          urls.add(_db.storage.from('portfolio').getPublicUrl(path));
        }

        await _db.from('services').insert({
          'freelancer_id': _uid,
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          'price': price,
          'delivery_days': deliveryDays,
          'image_urls': urls,
        });
        await refresh();
      });

  Future<void> setServiceActive(Service service, bool active) =>
      _guard(() async {
        await _db
            .from('services')
            .update({'is_active': active}).eq('id', service.id);
        await refresh();
      });
}
