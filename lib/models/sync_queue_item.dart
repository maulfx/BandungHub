import 'dart:convert';

/// Enum representing the kind of action queued while offline
enum SyncActionType {
  createReview,
  likeReview,
  createItinerary,
  updateItinerary,
  deleteItinerary,
  toggleBookmark,
}

/// Enum representing sync status of the item
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// Model for items stored in the offline sync queue
class SyncQueueItem {
  final String id;
  final SyncActionType actionType;
  final String targetId;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final SyncStatus status;
  final int retryCount;
  final String? errorMessage;

  const SyncQueueItem({
    required this.id,
    required this.actionType,
    required this.targetId,
    required this.payload,
    required this.queuedAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Human readable title for Indonesian UI
  String get displayTitle {
    switch (actionType) {
      case SyncActionType.createReview:
        final destName = payload['destinationName'] ?? targetId;
        return 'Ulasan Baru: $destName';
      case SyncActionType.likeReview:
        return 'Sukai Ulasan ($targetId)';
      case SyncActionType.createItinerary:
        final title = payload['title'] ?? 'Itinerary Baru';
        return 'Buat Rencana: $title';
      case SyncActionType.updateItinerary:
        final title = payload['title'] ?? targetId;
        return 'Perbarui Rencana: $title';
      case SyncActionType.deleteItinerary:
        return 'Hapus Rencana: $targetId';
      case SyncActionType.toggleBookmark:
        final isFav = payload['isFavorite'] == true;
        return isFav ? 'Simpan Favorit: $targetId' : 'Hapus Favorit: $targetId';
    }
  }

  /// Human readable label for sync status
  String get statusLabel {
    switch (status) {
      case SyncStatus.pending:
        return 'Menunggu Sinyal';
      case SyncStatus.syncing:
        return 'Sedang Sinkronisasi';
      case SyncStatus.synced:
        return 'Tersinkronisasi';
      case SyncStatus.failed:
        return 'Gagal Sinkron';
    }
  }

  SyncQueueItem copyWith({
    String? id,
    SyncActionType? actionType,
    String? targetId,
    Map<String, dynamic>? payload,
    DateTime? queuedAt,
    SyncStatus? status,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType.name,
      'targetId': targetId,
      'payload': payload,
      'queuedAt': queuedAt.toIso8601String(),
      'status': status.name,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      actionType: SyncActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => SyncActionType.createReview,
      ),
      targetId: map['targetId'] as String? ?? '',
      payload: map['payload'] is Map<String, dynamic>
          ? map['payload'] as Map<String, dynamic>
          : (map['payload'] != null
              ? Map<String, dynamic>.from(map['payload'] as Map)
              : {}),
      queuedAt: map['queuedAt'] != null
          ? DateTime.tryParse(map['queuedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: SyncStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SyncQueueItem.fromJson(String source) =>
      SyncQueueItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
