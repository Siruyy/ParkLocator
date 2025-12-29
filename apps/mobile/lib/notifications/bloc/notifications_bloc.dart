import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/notifications/repository/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required NotificationsRepository notificationsRepository})
      : _notificationsRepository = notificationsRepository,
        super(const NotificationsState()) {
    on<NotificationsFetched>(_onFetched);
    on<NotificationMarkedAsRead>(_onMarkedAsRead);
    on<AllNotificationsMarkedAsRead>(_onAllMarkedAsRead);
  }

  final NotificationsRepository _notificationsRepository;

  Future<void> _onFetched(
    NotificationsFetched event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final notifications = await _notificationsRepository.getNotifications();
      emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: notifications,
      ));
    } catch (_) {
      emit(state.copyWith(status: NotificationsStatus.failure));
    }
  }

  Future<void> _onMarkedAsRead(
    NotificationMarkedAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationsRepository.markAsRead(event.id);
      final notifications = state.notifications.map((n) {
        if (n.id == event.id) {
          // Since Notification is immutable, we can't copyWith unless we add it to the model.
          // But for now, let's just re-fetch or manually construct.
          // Actually, let's just re-fetch to be safe and simple.
          return n; 
        }
        return n;
      }).toList();
      
      // Optimistic update could be done here if we add copyWith to Notification model
      add(NotificationsFetched());
    } catch (_) {
      // Handle error
    }
  }

  Future<void> _onAllMarkedAsRead(
    AllNotificationsMarkedAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationsRepository.markAllAsRead();
      add(NotificationsFetched());
    } catch (_) {
      // Handle error
    }
  }
}
