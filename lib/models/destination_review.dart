class DestinationReview {
  final String id;
  final String destinationId;
  final String userName;
  final String? userAvatarUrl;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;
  final List<String> photoUrls;
  final int likesCount;
  final bool isLikedByMe;

  const DestinationReview({
    required this.id,
    required this.destinationId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.photoUrls = const [],
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  DestinationReview copyWith({
    String? id,
    String? destinationId,
    String? userName,
    String? userAvatarUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    List<String>? photoUrls,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return DestinationReview(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      photoUrls: photoUrls ?? this.photoUrls,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinationId': destinationId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'photoUrls': photoUrls,
      'likesCount': likesCount,
      'isLikedByMe': isLikedByMe,
    };
  }

  factory DestinationReview.fromMap(Map<String, dynamic> map) {
    return DestinationReview(
      id: map['id'] as String,
      destinationId: map['destinationId'] as String,
      userName: map['userName'] as String? ?? 'Wisatawan Bandung',
      userAvatarUrl: map['userAvatarUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      photoUrls: (map['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: map['isLikedByMe'] as bool? ?? false,
    );
  }
}
