part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
  });

  final NotificationsStatus status;
  final List<api.Notification> notifications;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<api.Notification>? notifications,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object> get props => [status, notifications];
}
