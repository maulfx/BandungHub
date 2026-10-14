import 'dart:convert';

import 'destination.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Destination> recommendedDestinations;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.recommendedDestinations = const [],
    this.isError = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'recommendedDestinations': recommendedDestinations
          .map((d) => d.toMap())
          .toList(),
      'isError': isError,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id:
          map['id'] as String? ??
          'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      recommendedDestinations:
          (map['recommendedDestinations'] as List<dynamic>?)
              ?.map((item) => Destination.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      isError: map['isError'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
