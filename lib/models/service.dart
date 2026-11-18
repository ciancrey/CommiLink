/// A service listing posted by a freelancer.
class Service {
  const Service({
    required this.id,
    required this.freelancerName,
    required this.role,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.deliveryDays,
    required this.rating,
  });

  final String id;
  final String freelancerName;
  final String role;
  final String title;
  final String description;
  final String category;
  final int price;
  final int deliveryDays;
  final double rating;

  /// "Ana Dela Cruz" -> "AD"
  String get initials {
    final parts = freelancerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
