import 'package:dio/dio.dart';
import '../network/api_client.dart';

class AdminService {
  final ApiClient _client = ApiClient();

  /// Retrieve platform overview KPIs (MRR, ARR, active users, workspaces)
  Future<Map<String, dynamic>> getOverview() async {
    try {
      final res = await _client.dio.get('/api/v1/admin/overview');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load platform overview';
      throw Exception(msg);
    }
  }

  /// List platform users
  Future<List<Map<String, dynamic>>> listUsers({String? search, String? status}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/admin/users',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      if (res.data is List) {
        return (res.data as List).map((u) => Map<String, dynamic>.from(u as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load platform users';
      throw Exception(msg);
    }
  }

  /// Suspend a platform user
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _client.dio.post(
        '/api/v1/admin/users/$userId/suspend',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to suspend user';
      throw Exception(msg);
    }
  }

  /// Reactivate a suspended user
  Future<void> reactivateUser(String userId) async {
    try {
      await _client.dio.post('/api/v1/admin/users/$userId/reactivate');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to reactivate user';
      throw Exception(msg);
    }
  }

  /// List all workspaces
  Future<List<Map<String, dynamic>>> listWorkspaces({String? search}) async {
    try {
      final res = await _client.dio.get(
        '/api/v1/admin/workspaces',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      if (res.data is List) {
        return (res.data as List).map((w) => Map<String, dynamic>.from(w as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load workspaces';
      throw Exception(msg);
    }
  }

  /// Suspend workspace
  Future<void> suspendWorkspace(String workspaceId, String reason) async {
    try {
      await _client.dio.post(
        '/api/v1/admin/workspaces/$workspaceId/suspend',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to suspend workspace';
      throw Exception(msg);
    }
  }

  /// Reactivate workspace
  Future<void> reactivateWorkspace(String workspaceId) async {
    try {
      await _client.dio.post('/api/v1/admin/workspaces/$workspaceId/reactivate');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to reactivate workspace';
      throw Exception(msg);
    }
  }

  /// Get live telemetry for 7 social platforms
  Future<List<Map<String, dynamic>>> getIntegrationHealth() async {
    try {
      final res = await _client.dio.get('/api/v1/admin/integrations/health');
      if (res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load integration health';
      throw Exception(msg);
    }
  }

  /// Get immutable platform audit logs
  Future<List<Map<String, dynamic>>> listAuditLogs() async {
    try {
      final res = await _client.dio.get('/api/v1/admin/audit-logs');
      if (res.data is List) {
        return (res.data as List).map((l) => Map<String, dynamic>.from(l as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load audit logs';
      throw Exception(msg);
    }
  }

  /// Issue gateway refund
  Future<Map<String, dynamic>> issueRefund(String invoiceId, String reason) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/admin/refunds',
        data: {'invoice_id': invoiceId, 'reason': reason},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to process refund';
      throw Exception(msg);
    }
  }
}

