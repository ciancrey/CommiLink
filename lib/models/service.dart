/// A service listing posted by a freelancer.
class Service {
  const Service({
    required this.id,
    this.freelancerId = '',
    required this.freelancerName,
    required this.role,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.deliveryDays,
    required this.rating,
    this.reviewCount = 0,
    this.isActive = true,
    this.imageUrls = const [],
    this.freelancerAvatar,
  });

  /// Builds a Service from a row of the `service_listings` database view.
  factory Service.fromMap(Map<String, dynamic> m) {
    return Service(
      id: m['id'] as String,
      freelancerId: m['freelancer_id'] as String,
      freelancerName: (m['freelancer_name'] ?? '') as String,
      role: (m['role'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      price: (m['price'] as num).toInt(),
      deliveryDays: (m['delivery_days'] as num).toInt(),
      rating: ((m['rating'] ?? 0) as num).toDouble(),
      reviewCount: ((m['review_count'] ?? 0) as num).toInt(),
      isActive: (m['is_active'] ?? true) as bool,
      imageUrls: ((m['image_urls'] ?? const []) as List)
          .map((e) => e.toString())
          .toList(),
      freelancerAvatar: m['freelancer_avatar'] as String?,
    );
  }

  final String id;
  final String freelancerId;
  final String freelancerName;
  final String role;
  final String title;
  final String description;
  final String category;
  final int price;
  final int deliveryDays;
  final double rating;
  final int reviewCount;
  final bool isActive;

  /// Portfolio images (public URLs) added in "Post a service".
  final List<String> imageUrls;
  final String? freelancerAvatar;

  /// "Ana Dela Cruz" -> "AD"
  String get initials => initialsOf(freelancerName);
}

/// "Ana Dela Cruz" -> "AD". Safe for empty names.
String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}
