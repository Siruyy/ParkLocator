import 'package:equatable/equatable.dart';

enum NotificationType {
  success,
  info,
  warning,
  error,
}

class Notification extends Equatable {
  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: _parseType(json['type'] as String),
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'success':
        return NotificationType.success;
      case 'warning':
        return NotificationType.warning;
      case 'error':
        return NotificationType.error;
      case 'info':
      default:
        return NotificationType.info;
    }
  }

  @override
  List<Object> get props => [id, title, message, type, isRead, createdAt];
}
