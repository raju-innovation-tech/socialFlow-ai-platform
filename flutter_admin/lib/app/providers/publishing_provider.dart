import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/publishing_service.dart';

class PublishingState {
  final List<dynamic> posts;
  final List<dynamic> queueItems;
  final List<dynamic> calendarEvents;
  final List<dynamic> historyItems;
  final List<dynamic> failedItems;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PublishingState({
    this.posts = const [],
    this.queueItems = const [],
    this.calendarEvents = const [],
    this.historyItems = const [],
    this.failedItems = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PublishingState copyWith({
    List<dynamic>? posts,
    List<dynamic>? queueItems,
    List<dynamic>? calendarEvents,
    List<dynamic>? historyItems,
    List<dynamic>? failedItems,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return PublishingState(
      posts: posts ?? this.posts,
      queueItems: queueItems ?? this.queueItems,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      historyItems: historyItems ?? this.historyItems,
      failedItems: failedItems ?? this.failedItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class PublishingNotifier extends Notifier<PublishingState> {
  final PublishingService _service = PublishingService();

  @override
  PublishingState build() {
    return const PublishingState();
  }

  Future<void> loadPosts({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.listPosts(status: status);
      state = state.copyWith(posts: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadQueue() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getQueue();
      state = state.copyWith(queueItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadCalendar({DateTime? start, DateTime? end}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getCalendar(start: start, end: end);
      state = state.copyWith(calendarEvents: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getHistory();
      state = state.copyWith(historyItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadFailed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getFailedTargets();
      state = state.copyWith(failedItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Map<String, dynamic>?> createPost({
    required String content,
    String? title,
    String contentType = "text",
    DateTime? scheduledAt,
    List<String>? targetAccountIds,
    List<Map<String, dynamic>>? variants,
    List<String>? mediaAssetIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _service.createPost(
        content: content,
        title: title,
        contentType: contentType,
        scheduledAt: scheduledAt,
        targetAccountIds: targetAccountIds,
        variants: variants,
        mediaAssetIds: mediaAssetIds,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Post created successfully',
      );
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> publishNow(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _service.publishNow(postId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Publishing completed: ${res['overall_status']}',
      );
      await loadQueue();
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> schedulePost(String postId, DateTime scheduledAt, {String timezone = "UTC"}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.schedulePost(postId: postId, scheduledAt: scheduledAt, timezone: timezone);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Post scheduled successfully',
      );
      await loadQueue();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> cancelSchedule(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelSchedule(postId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Scheduled post cancelled and returned to draft',
      );
      await loadQueue();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> duplicatePost(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.duplicatePost(postId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Post duplicated to new draft',
      );
      await loadPosts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> retryTarget(String postId, String targetId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.retryTarget(postId, targetId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Target retried successfully',
      );
      await loadFailed();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final publishingProvider =
    NotifierProvider<PublishingNotifier, PublishingState>(() {
  return PublishingNotifier();
});

