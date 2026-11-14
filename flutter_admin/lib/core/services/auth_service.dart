import 'package:dio/dio.dart';
import '../network/api_client.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final bool emailVerified;
  final bool isSuperAdmin;
  final String? defaultWorkspaceId;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.emailVerified,
    required this.isSuperAdmin,
    this.defaultWorkspaceId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      isSuperAdmin: json['is_super_admin'] ?? false,
      defaultWorkspaceId: json['default_workspace_id'],
    );
  }
}

class WorkspaceInfo {
  final String id;
  final String name;
  final String slug;
  final String role;
  final String status;
  final bool isDefault;

  const WorkspaceInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.status,
    required this.isDefault,
  });

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) {
    return WorkspaceInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      role: json['role'] ?? 'viewer',
      status: json['status'] ?? 'active',
      isDefault: json['is_default'] ?? false,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final List<String> permissions;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.permissions,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    final perms = (json['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: AuthUser.fromJson(userData),
      permissions: perms,
    );
  }
}

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await _client.dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'terms_accepted': true,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    try {
      await _client.dio.post(
        '/auth/verify-email',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<String?> resendVerificationOtp(String email) async {
    try {
      final res = await _client.dio.post('/auth/resend-verification?email=$email');
      return res.data?['dev_verification_otp'] as String?;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final response = AuthResponse.fromJson(res.data);
      _client.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      if (response.user.defaultWorkspaceId != null) {
        _client.setActiveWorkspace(response.user.defaultWorkspaceId);
      }
      return response;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> logout() async {
    try {
      if (_client.refreshToken != null) {
        await _client.dio.post(
          '/auth/logout',
          data: {'refresh_token': _client.refreshToken},
        );
      }
    } catch (_) {
      // Best-effort logout
    } finally {
      _client.clearSession();
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final res = await _client.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return res.data?['dev_reset_otp'] as String?;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _client.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<List<WorkspaceInfo>> listWorkspaces() async {
    try {
      final res = await _client.dio.get('/workspaces');
      final list = (res.data as List<dynamic>?)
              ?.map((e) => WorkspaceInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return list;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> switchWorkspace(String workspaceId) async {
    try {
      final res = await _client.dio.post('/workspaces/switch/$workspaceId');
      _client.setActiveWorkspace(workspaceId);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ??
          data['detail']?.toString() ??
          'An unexpected error occurred.';
    }
    return e.message ?? 'Network connection error. Ensure backend is running.';
  }
}

