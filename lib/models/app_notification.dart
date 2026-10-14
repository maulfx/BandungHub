enum NotificationType {
  welcome,
  itineraryReminder,
  destinationReminder,
  quizReminder,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final DateTime createdTime;
  final NotificationType type;
  final bool isRead;
  final bool isDelivered;
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.createdTime,
    required this.type,
    this.isRead = false,
    this.isDelivered = false,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    DateTime? createdTime,
    NotificationType? type,
    bool? isRead,
    bool? isDelivered,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdTime: createdTime ?? this.createdTime,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
      'createdTime': createdTime.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'payload': payload,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      createdTime: DateTime.parse(map['createdTime'] as String),
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: (map['isRead'] as bool?) ?? false,
      isDelivered: (map['isDelivered'] as bool?) ?? false,
      payload: map['payload'] != null
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : null,
    );
  }
}
