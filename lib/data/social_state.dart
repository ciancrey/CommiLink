import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';

/// NEW FILE · Data for Messages, Chat, Alerts, Network and order files.
/// Tables/views used (see supabase/schema_v2.sql):
///   conversations, messages, notifications, order_files,
///   freelancer_directory, storage bucket "order-files".

DateTime _date(dynamic v) => DateTime.parse(v as String).toLocal();

/// "2:33 PM"
String clockTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Chat list style: "2:33 PM", "Yesterday", "Mon", "Nov 19".
String friendlyTime(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return clockTime(d);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
  return shortDate(d);
}

/// Alerts style: "Just now", "2h ago", "Nov 6".
String agoTime(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return shortDate(d);
}

/// "24 MB", "18 KB"
String fileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(bytes > 10 * 1024 * 1024 ? 0 : 1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

String fileType(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? 'FILE' : name.substring(dot + 1).toUpperCase();
}

/// "#DP-0142"
String disputeCode(int? n) => '#DP-${(n ?? 0).toString().padLeft(4, '0')}';

// ---------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------

class OrderFile {
  const OrderFile({
    required this.id,
    required this.orderId,
    required this.uploadedBy,
    required this.kind,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory OrderFile.fromMap(Map<String, dynamic> m) => OrderFile(
        id: m['id'] as String,
        orderId: m['order_id'] as String,
        uploadedBy: m['uploaded_by'] as String,
        kind: m['kind'] as String,
        path: m['path'] as String,
        name: m['name'] as String,
        sizeBytes: ((m['size_bytes'] ?? 0) as num).toInt(),
        createdAt: _date(m['created_at']),
      );

  final String id;
  final String orderId;
  final String uploadedBy;

  /// brief, delivery, chat or dispute
  final String kind;
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdAt;

  String get label => '$name · ${fileSize(sizeBytes)}';
}

class Conversation {
  const Conversation({
    required this.orderId,
    required this.status,
    required this.amount,
    required this.clientId,
    required this.freelancerId,
    required this.clientName,
    required this.freelancerName,
    required this.serviceTitle,
    required this.lastBody,
    required this.lastHasFile,
    required this.lastAt,
    required this.unreadCount,
  });

  factory Conversation.fromMap(Map<String, dynamic> m) => Conversation(
        orderId: m['order_id'] as String,
        status: (m['status'] ?? '') as String,
        amount: ((m['amount'] ?? 0) as num).toInt(),
        clientId: m['client_id'] as String,
        freelancerId: m['freelancer_id'] as String,
        clientName: (m['client_name'] ?? '') as String,
        freelancerName: (m['freelancer_name'] ?? '') as String,
        serviceTitle: (m['service_title'] ?? '') as String,
        lastBody: m['last_body'] as String?,
        lastHasFile: (m['last_has_file'] ?? false) as bool,
        lastAt: _date(m['last_at']),
        unreadCount: ((m['unread_count'] ?? 0) as num).toInt(),
      );

  final String orderId;
  final String status;
  final int amount;
  final String clientId;
  final String freelancerId;
  final String clientName;
  final String freelancerName;
  final String serviceTitle;
  final String? lastBody;
  final bool lastHasFile;
  final DateTime lastAt;
  final int unreadCount;

  /// The other person in the chat, from my point of view.
  String otherName(String? myId) =>
      myId == freelancerId ? clientName : freelancerName;

  String get preview {
    if (lastBody != null && lastBody!.isNotEmpty) return lastBody!;
    if (lastHasFile) return 'Sent a file';
    return 'No messages yet — say hi!';
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.file,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        orderId: m['order_id'] as String,
        senderId: m['sender_id'] as String,
        body: (m['body'] ?? '') as String,
        createdAt: _date(m['created_at']),
        readAt: m['read_at'] == null ? null : _date(m['read_at']),
        file: m['order_files'] == null
            ? null
            : OrderFile.fromMap(m['order_files'] as Map<String, dynamic>),
      );

  final String id;
  final String orderId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final OrderFile? file;
}

class AppAlert {
  const AppAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.readAt,
  });

  factory AppAlert.fromMap(Map<String, dynamic> m) => AppAlert(
        id: m['id'] as String,
        kind: (m['kind'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        orderId: m['order_id'] as String?,
        createdAt: _date(m['created_at']),
        readAt: m['read_at'] == null ? null : _date(m['read_at']),
      );

  final String id;
  final String kind;
  final String title;
  final String body;
  final String? orderId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

class Freelancer {
  const Freelancer({
    required this.id,
    required this.fullName,
    required this.headline,
    required this.rating,
    required this.reviewCount,
    required this.jobsDone,
    required this.categories,
    required this.serviceCount,
    this.avatarUrl,
  });

  factory Freelancer.fromMap(Map<String, dynamic> m) => Freelancer(
        id: m['id'] as String,
        fullName: (m['full_name'] ?? '') as String,
        headline: (m['headline'] ?? '') as String,
        avatarUrl: m['avatar_url'] as String?,
        rating: ((m['rating'] ?? 0) as num).toDouble(),
        reviewCount: ((m['review_count'] ?? 0) as num).toInt(),
        jobsDone: ((m['jobs_done'] ?? 0) as num).toInt(),
        categories: ((m['categories'] ?? const []) as List)
            .map((e) => e.toString())
            .toList(),
        serviceCount: ((m['service_count'] ?? 0) as num).toInt(),
      );

  final String id;
  final String fullName;
  final String headline;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final int jobsDone;
  final List<String> categories;
  final int serviceCount;
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

class SocialState {
  SocialState._();

  static final SocialState instance = SocialState._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get myId => _db.auth.currentUser?.id;

  final ValueNotifier<List<Conversation>> conversations =
      ValueNotifier<List<Conversation>>([]);
  final ValueNotifier<List<AppAlert>> alerts = ValueNotifier<List<AppAlert>>([]);

  /// Bumped whenever a chat message arrives, so open chats can reload.
  final ValueNotifier<int> messageTick = ValueNotifier<int>(0);

  int get unreadAlerts => alerts.value.where((a) => a.isUnread).length;
  int get unreadMessages =>
      conversations.value.fold(0, (sum, c) => sum + c.unreadCount);

  RealtimeChannel? _channel;
  Timer? _debounce;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } on StorageException catch (e) {
      throw AppException('File problem: ${e.message}');
    } catch (e) {
      debugPrint('CommiLink social error: $e');
      throw AppException(
        'Something went wrong. Check your internet connection and try again.',
      );
    }
  }

  /// Called after sign in (from AppState).
  Future<void> start() async {
    await refresh();
    if (_channel != null) return;

    void onChange(PostgresChangePayload p) {
      if (p.table == 'messages') messageTick.value++;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        refresh().catchError((Object e) => debugPrint('Social refresh: $e'));
      });
    }

    _channel = _db
        .channel('social-${myId ?? 'anon'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: onChange,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: onChange,
        )
        .subscribe();
  }

  Future<void> clear() async {
    if (_channel != null) {
      await _db.removeChannel(_channel!);
      _channel = null;
    }
    conversations.value = [];
    alerts.value = [];
  }

  Future<void> refresh() => _guard(() async {
        if (myId == null) return;
        final results = await Future.wait<dynamic>([
          _db.from('conversations').select().order('last_at', ascending: false),
          _db
              .from('notifications')
              .select()
              .order('created_at', ascending: false)
              .limit(100),
        ]);
        conversations.value = (results[0] as List)
            .map((m) => Conversation.fromMap(m as Map<String, dynamic>))
            .toList();
        alerts.value = (results[1] as List)
            .map((m) => AppAlert.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ------------------------------------------------------------- chat

  Future<List<ChatMessage>> loadMessages(String orderId) => _guard(() async {
        final rows = await _db
            .from('messages')
            .select('*, order_files!messages_file_fk(*)')
            .eq('order_id', orderId)
            .order('created_at', ascending: true);
        return (rows as List)
            .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> markChatRead(String orderId) => _guard(() async {
        await _db.rpc('mark_chat_read', params: {'p_order_id': orderId});
        await refresh();
      });

  /// Sends a text message, optionally with a file the user picked.
  Future<void> sendMessage(
    String orderId,
    String text, {
    PlatformFile? file,
  }) =>
      _guard(() async {
        String? fileId;
        if (file != null) {
          final uploaded = await uploadOrderFile(orderId, 'chat', file);
          fileId = uploaded.id;
        }
        await _db.from('messages').insert({
          'order_id': orderId,
          'sender_id': myId,
          'body': text.trim(),
          if (fileId != null) 'file_id': fileId,
        });
      });

  // ------------------------------------------------------------- files

  /// Opens the phone's file picker. Returns null if the user cancels.
  /// Files are limited to 50 MB (Supabase free plan limit).
  Future<PlatformFile?> pickFile({bool imagesOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: imagesOnly ? FileType.image : FileType.any,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.size > 50 * 1024 * 1024) {
      throw AppException('That file is over 50 MB. Please pick a smaller one.');
    }
    if (f.bytes == null) {
      throw AppException('Could not read that file. Try another one.');
    }
    return f;
  }

  Future<OrderFile> uploadOrderFile(
    String orderId,
    String kind,
    PlatformFile file,
  ) =>
      _guard(() async {
        final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final path =
            '$orderId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        await _db.storage.from('order-files').uploadBinary(
              path,
              file.bytes!,
              fileOptions: const FileOptions(upsert: false),
            );
        final row = await _db
            .from('order_files')
            .insert({
              'order_id': orderId,
              'uploaded_by': myId,
              'kind': kind,
              'path': path,
              'name': file.name,
              'size_bytes': file.size,
            })
            .select()
            .single();
        return OrderFile.fromMap(row);
      });

  Future<List<OrderFile>> loadOrderFiles(String orderId) => _guard(() async {
        final rows = await _db
            .from('order_files')
            .select()
            .eq('order_id', orderId)
            .order('created_at', ascending: true);
        return (rows as List)
            .map((m) => OrderFile.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  /// Opens a file in the phone's browser/viewer using a link that
  /// works for 10 minutes (the bucket is private).
  Future<void> openFile(OrderFile file) => _guard(() async {
        final url = await _db.storage
            .from('order-files')
            .createSignedUrl(file.path, 600);
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) throw AppException('No app on this phone can open that file.');
      });

  // ------------------------------------------------------------- alerts

  Future<void> markAllAlertsRead() => _guard(() async {
        await _db.rpc('mark_alerts_read');
        await refresh();
      });

  Future<void> markAlertRead(AppAlert alert) => _guard(() async {
        if (!alert.isUnread) return;
        await _db.rpc('mark_alerts_read', params: {'p_id': alert.id});
        await refresh();
      });

  // ------------------------------------------------------------- network

  Future<List<Freelancer>> loadFreelancers() => _guard(() async {
        final rows = await _db
            .from('freelancer_directory')
            .select()
            .order('rating', ascending: false)
            .order('jobs_done', ascending: false);
        return (rows as List)
            .map((m) => Freelancer.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ------------------------------------------------------------- disputes

  Future<void> respondToDispute(String orderId, String note) =>
      _guard(() async {
        await _db.rpc('respond_dispute', params: {
          'p_order_id': orderId,
          'p_note': note,
        });
        await AppState.instance.refresh();
      });
}
