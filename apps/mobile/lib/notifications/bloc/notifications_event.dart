part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class NotificationsFetched extends NotificationsEvent {}

class NotificationMarkedAsRead extends NotificationsEvent {
  const NotificationMarkedAsRead(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

class AllNotificationsMarkedAsRead extends NotificationsEvent {}
