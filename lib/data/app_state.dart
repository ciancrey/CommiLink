import 'package:flutter/foundation.dart';

import '../models/service.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// DateTime -> "Nov 19"
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// A commission the client has requested.
class Order {
  Order({
    required this.id,
    required this.service,
    required this.brief,
    required this.amount,
    required this.createdAt,
    this.status = 'Requested',
  });

  final String id;
  final Service service;
  final String brief;
  final int amount;
  final DateTime createdAt;

  /// Requested, In progress, Delivered, Completed, Disputed, Refunded
  String status;

  String? deliveryNote;
  String? disputeReason;
  String? disputeNote;
  DateTime? disputedAt;
  int? rating;
  String? review;

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

  final String title;
  final String subtitle;
  final int amount;
  final DateTime date;
}

/// Simple in-memory app state for the demo (resets when the app restarts).
class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final ValueNotifier<int> balance = ValueNotifier<int>(48500);
  final ValueNotifier<List<Order>> orders = ValueNotifier<List<Order>>([]);
  final ValueNotifier<List<WalletTxn>> transactions =
  ValueNotifier<List<WalletTxn>>([]);

  /// Money currently held by CommiLink for active commissions.
  int get held =>
      orders.value.where((o) => o.isActive).fold(0, (sum, o) => sum + o.amount);

  int get activeCount => orders.value.where((o) => o.isActive).length;

  /// Total paid into commissions (refunds not counted).
  int get spent => orders.value
      .where((o) => o.status != 'Refunded')
      .fold(0, (sum, o) => sum + o.amount);

  int get refunded => orders.value
      .where((o) => o.status == 'Refunded')
      .fold(0, (sum, o) => sum + o.amount);

  bool canAfford(int amount) => balance.value >= amount;

  Order? findOrder(String id) {
    for (final o in orders.value) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _notifyOrders() {
    orders.value = [...orders.value];
  }

  void _addTxn(String title, String subtitle, int amount) {
    transactions.value = [
      WalletTxn(
        title: title,
        subtitle: subtitle,
        amount: amount,
        date: DateTime.now(),
      ),
      ...transactions.value,
    ];
  }

  /// Takes the payment out of the wallet and creates the order.
  /// Returns null if the balance is not enough.
  Order? placeOrder(Service service, String brief) {
    if (!canAfford(service.price)) return null;

    balance.value -= service.price;

    final order = Order(
      id: 'o${orders.value.length + 1}',
      service: service,
      brief: brief,
      amount: service.price,
      createdAt: DateTime.now(),
    );
    orders.value = [order, ...orders.value];
    _addTxn('Payment held', service.title, -service.price);
    return order;
  }

  /// MockPay demo top-up.
  void topUp(int amount) {
    balance.value += amount;
    _addTxn('MockPay top-up', 'Wallet top-up (simulated)', amount);
  }

  /// Demo: the freelancer moves the order forward.
  void advance(Order order) {
    if (order.status == 'Requested') {
      order.status = 'In progress';
    } else if (order.status == 'In progress') {
      order.status = 'Delivered';
      order.deliveryNote =
      'Final files are ready. Thank you for ordering! Let me know if '
          'you need any small changes.';
    }
    _notifyOrders();
  }

  /// Client confirms the work. The held payment goes to the freelancer.
  void release(Order order) {
    order.status = 'Completed';
    _notifyOrders();
  }

  /// Client reports a problem. The payment stays on hold.
  void dispute(Order order, String reason, String note) {
    order.status = 'Disputed';
    order.disputeReason = reason;
    order.disputeNote = note;
    order.disputedAt = DateTime.now();
    _notifyOrders();
  }

  /// Demo admin decision on a dispute.
  void resolveDispute(Order order, {required bool refund}) {
    if (refund) {
      order.status = 'Refunded';
      balance.value += order.amount;
      _addTxn('Refund', order.service.title, order.amount);
    } else {
      order.status = 'Completed';
    }
    _notifyOrders();
  }

  void submitReview(Order order, int rating, String text) {
    order.rating = rating;
    order.review = text;
    _notifyOrders();
  }
}