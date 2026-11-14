import 'package:dio/dio.dart';
import '../network/api_client.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  /// Fetch workspace notifications
  Future<List<Map<String, dynamic>>> listNotifications({bool unreadOnly = false}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/notifications',
        queryParameters: unreadOnly ? {'unread_only': true} : null,
      );
      if (res.data is List) {
        return (res.data as List).map((n) => Map<String, dynamic>.from(n as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load notifications';
      throw Exception(msg);
    }
  }

  /// Get total unread count for badge display
  Future<int> getUnreadCount() async {
    try {
      final res = await _client.dio.get('/api/v1/notifications/unread-count');
      return (res.data?['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException {
      return 0;
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.dio.patch('/api/v1/notifications/$notificationId/read');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to mark notification as read';
      throw Exception(msg);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _client.dio.post('/api/v1/notifications/read-all');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to mark all as read';
      throw Exception(msg);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.dio.delete('/api/v1/notifications/$notificationId');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to delete notification';
      throw Exception(msg);
    }
  }

  /// Fetch user preferences
  Future<List<Map<String, dynamic>>> getPreferences() async {
    try {
      final res = await _client.dio.get('/api/v1/notifications/preferences');
      if (res.data is List) {
        return (res.data as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load notification preferences';
      throw Exception(msg);
    }
  }

  /// Update a notification preference
  Future<void> updatePreference(String channel, String category, bool isEnabled) async {
    try {
      await _client.dio.patch(
        '/api/v1/notifications/preferences',
        data: {
          'channel': channel,
          'category': category,
          'is_enabled': isEnabled,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update preference';
      throw Exception(msg);
    }
  }
}

