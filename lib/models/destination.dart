import 'package:latlong2/latlong.dart';

class Destination {
  final String id;
  final String name;
  final String description;
  final String category; // Alam, Kuliner, Sejarah, Keluarga, Hiburan
  final String address;
  final double latitude;
  final double longitude;
  final double estimatedPrice;
  final String operationalHours;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final List<String> tags;

  const Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedPrice,
    required this.operationalHours,
    required this.imageUrl,
    this.rating = 4.5,
    this.reviewCount = 120,
    this.isVerified = true,
    this.tags = const [],
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimated_price': estimatedPrice,
      'operational_hours': operationalHours,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'is_verified': isVerified ? 1 : 0,
      'tags': tags.join(','),
    };
  }

  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Alam',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.9175,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 107.6191,
      estimatedPrice: (map['estimated_price'] as num?)?.toDouble() ?? 0.0,
      operationalHours: map['operational_hours'] ?? 'Setiap hari 08:00 - 17:00',
      imageUrl: map['image_url'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      isVerified: map['is_verified'] == 1 || map['is_verified'] == true,
      tags: map['tags'] is String
          ? (map['tags'] as String)
                .split(',')
                .where((t) => t.trim().isNotEmpty)
                .toList()
          : (map['tags'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
    );
  }

  factory Destination.fromJson(Map<String, dynamic> json) =>
      Destination.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  Destination copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    double? estimatedPrice,
    String? operationalHours,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    List<String>? tags,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      operationalHours: operationalHours ?? this.operationalHours,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
    );
  }
}
