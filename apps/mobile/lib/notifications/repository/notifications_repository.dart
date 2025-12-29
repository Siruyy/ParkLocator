import 'package:mobile/api/api.dart' as api;

class NotificationsRepository {
  NotificationsRepository({required api.ApiClient apiClient})
      : _apiClient = apiClient;

  final api.ApiClient _apiClient;

  Future<List<api.Notification>> getNotifications() async {
    return _apiClient.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    return _apiClient.markNotificationAsRead(id);
  }

  Future<void> markAllAsRead() async {
    return _apiClient.markAllNotificationsAsRead();
  }
}
