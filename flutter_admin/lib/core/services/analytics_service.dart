import 'package:dio/dio.dart';
import '../network/api_client.dart';

class AnalyticsService {
  final ApiClient _client = ApiClient();

  /// Retrieve workspace overview KPIs and trend chart data
  Future<Map<String, dynamic>> getOverview({String period = 'last_7_days'}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/analytics/overview',
        queryParameters: {'period': period},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load analytics overview';
      throw Exception(msg);
    }
  }

  /// Retrieve per-platform follower, engagement, and post counts
  Future<List<Map<String, dynamic>>> getPlatformAnalytics() async {
    try {
      final res = await _client.dio.get('/api/v1/analytics/platforms');
      final platforms = res.data?['platforms'];
      if (platforms is List) {
        return platforms.map((p) => Map<String, dynamic>.from(p as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load platform analytics';
      throw Exception(msg);
    }
  }

  /// Retrieve historical metric snapshots for a specific connected account
  Future<Map<String, dynamic>> getAccountAnalytics(String accountId) async {
    try {
      final res = await _client.dio.get('/api/v1/analytics/accounts/$accountId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load account analytics';
      throw Exception(msg);
    }
  }

  /// Retrieve metrics for an individual published post across platform targets
  Future<Map<String, dynamic>> getPostAnalytics(String postId) async {
    try {
      final res = await _client.dio.get('/api/v1/analytics/posts/$postId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load post analytics';
      throw Exception(msg);
    }
  }

  /// Trigger manual sync of social platform metrics
  Future<Map<String, dynamic>> syncAnalytics() async {
    try {
      final res = await _client.dio.post('/api/v1/analytics/sync');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to synchronize analytics';
      throw Exception(msg);
    }
  }

  /// Export CSV performance report
  Future<String> exportReportCsv() async {
    try {
      final res = await _client.dio.post(
        '/api/v1/analytics/reports/export',
        options: Options(responseType: ResponseType.plain),
      );
      return res.data.toString();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to export CSV report';
      throw Exception(msg);
    }
  }
}

