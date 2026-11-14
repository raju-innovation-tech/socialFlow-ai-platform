import 'package:dio/dio.dart';
import '../network/api_client.dart';

class PublishingService {
  final ApiClient _client = ApiClient();

  /// Create a new post in the active workspace
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? title,
    String contentType = "text",
    DateTime? scheduledAt,
    List<String>? targetAccountIds,
    List<Map<String, dynamic>>? variants,
    List<String>? mediaAssetIds,
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/posts',
        data: {
          'title': title,
          'content': content,
          'content_type': contentType,
          'workspace_id': _client.activeWorkspaceId ?? '',
          'scheduled_at': scheduledAt?.toUtc().toIsoformat(),
          if (targetAccountIds != null) 'target_account_ids': targetAccountIds,
          if (variants != null) 'variants': variants,
          if (mediaAssetIds != null) 'media_asset_ids': mediaAssetIds,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.response?.data?['message'] ?? 'Failed to create post';
      throw Exception(msg);
    }
  }

  /// List posts with optional status filter
  Future<List<dynamic>> listPosts({String? status, int skip = 0, int limit = 50}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/posts',
        queryParameters: {
          if (status != null) 'status': status,
          'skip': skip,
          'limit': limit,
        },
      );
      return res.data is List ? res.data as List<dynamic> : [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load posts';
      throw Exception(msg);
    }
  }

  /// Get single post details including targets and variants
  Future<Map<String, dynamic>> getPost(String postId) async {
    try {
      final res = await _client.dio.get('/api/v1/posts/$postId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load post';
      throw Exception(msg);
    }
  }

  /// Duplicate an existing post to a new draft
  Future<Map<String, dynamic>> duplicatePost(String postId) async {
    try {
      final res = await _client.dio.post('/api/v1/posts/$postId/duplicate');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to duplicate post';
      throw Exception(msg);
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _client.dio.delete('/api/v1/posts/$postId');
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to delete post';
      throw Exception(msg);
    }
  }

  /// Publish post immediately across all configured social accounts
  Future<Map<String, dynamic>> publishNow(String postId) async {
    try {
      final res = await _client.dio.post('/api/v1/posts/$postId/publish');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['detail'] ?? 'Publishing failed';
      throw Exception(msg);
    }
  }

  /// Schedule post for a future date and time
  Future<Map<String, dynamic>> schedulePost({
    required String postId,
    required DateTime scheduledAt,
    String timezone = "UTC",
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/posts/$postId/schedule',
        data: {
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'timezone': timezone,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['detail'] ?? 'Scheduling failed';
      throw Exception(msg);
    }
  }

  /// Cancel a scheduled post
  Future<Map<String, dynamic>> cancelSchedule(String postId) async {
    try {
      final res = await _client.dio.post('/api/v1/posts/$postId/cancel');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['detail'] ?? 'Failed to cancel schedule';
      throw Exception(msg);
    }
  }

  /// Get live publishing status for a post
  Future<Map<String, dynamic>> getPublishingStatus(String postId) async {
    try {
      final res = await _client.dio.get('/api/v1/posts/$postId/publishing-status');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to get publishing status';
      throw Exception(msg);
    }
  }

  /// Validate content across selected platforms
  Future<Map<String, dynamic>> validateContent({
    required String content,
    required List<String> platforms,
    Map<String, String>? variants,
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/posts/validate',
        data: {
          'content': content,
          'platforms': platforms,
          if (variants != null) 'variants': variants,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Validation failed';
      throw Exception(msg);
    }
  }

  /// Fetch calendar events
  Future<List<dynamic>> getCalendar({DateTime? start, DateTime? end}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/publishing/calendar',
        queryParameters: {
          if (start != null) 'start_date': start.toUtc().toIso8601String(),
          if (end != null) 'end_date': end.toUtc().toIso8601String(),
        },
      );
      return res.data is List ? res.data as List<dynamic> : [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load calendar';
      throw Exception(msg);
    }
  }

  /// Fetch active publishing queue
  Future<List<dynamic>> getQueue() async {
    try {
      final res = await _client.dio.get('/api/v1/publishing/queue');
      return res.data is List ? res.data as List<dynamic> : [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load queue';
      throw Exception(msg);
    }
  }

  /// Fetch publishing execution history
  Future<List<dynamic>> getHistory({int skip = 0, int limit = 50}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/publishing/history',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return res.data is List ? res.data as List<dynamic> : [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load history';
      throw Exception(msg);
    }
  }

  /// Fetch failed publishing targets
  Future<List<dynamic>> getFailedTargets() async {
    try {
      final res = await _client.dio.get('/api/v1/publishing/failed');
      return res.data is List ? res.data as List<dynamic> : [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load failed targets';
      throw Exception(msg);
    }
  }

  /// Retry an individual target
  Future<Map<String, dynamic>> retryTarget(String postId, String targetId) async {
    try {
      final res = await _client.dio.post('/api/v1/posts/$postId/targets/$targetId/retry');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['detail'] ?? 'Retry failed';
      throw Exception(msg);
    }
  }
}

extension DateTimeExtension on DateTime {
  String toIsoformat() => toUtc().toIso8601String();
}

