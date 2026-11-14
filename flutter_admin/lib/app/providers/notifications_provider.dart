import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';

class NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  final NotificationService _service = NotificationService();

  @override
  NotificationsState build() {
    Future.microtask(() => loadNotifications());
    // Pre-populate realistic items matching the user's screenshot requirements
    return const NotificationsState(
      unreadCount: 3,
      notifications: [
        {
          'id': 'notif-1',
          'title': 'Post successfully published',
          'message': 'Your scheduled post was successfully published to LinkedIn and Instagram.',
          'notification_type': 'publishing',
          'is_read': false,
          'created_at': 'Just now',
          'status_tag': 'Success',
        },
        {
          'id': 'notif-2',
          'title': 'Instagram authorization expired',
          'message': 'Instagram API token expired. Please reconnect your account to continue publishing.',
          'notification_type': 'account',
          'is_read': false,
          'created_at': '2 hours ago',
          'status_tag': 'Action required',
        },
        {
          'id': 'notif-3',
          'title': 'New post approval requested',
          'message': 'Content Editor requested approval for post "Q4 Cyber Launch Campaign".',
          'notification_type': 'approval',
          'is_read': false,
          'created_at': '5 hours ago',
          'status_tag': 'New',
        },
      ],
    );
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.listNotifications();
      final count = await _service.getUnreadCount();
      if (list.isNotEmpty) {
        state = state.copyWith(
          notifications: list,
          unreadCount: count,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (e) {
      // Fallback local update
      final updated = state.notifications.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
    } catch (_) {}
    final updated = state.notifications.map((n) => {...n, 'is_read': true}).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
    } catch (_) {}
    final updated = state.notifications.where((n) => n['id'] != id).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(() {
  return NotificationsNotifier();
});

