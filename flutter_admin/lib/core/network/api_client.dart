import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  String? _accessToken;
  String? _refreshToken;
  String? _activeWorkspaceId;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get activeWorkspaceId => _activeWorkspaceId;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          if (_activeWorkspaceId != null && _activeWorkspaceId!.isNotEmpty) {
            options.headers['X-Workspace-ID'] = _activeWorkspaceId;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Automatic Refresh Token rotation on 401 Unauthorized
          if (error.response?.statusCode == 401 &&
              _refreshToken != null &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            try {
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                // Retry failed request with new access token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_accessToken';
                final cloneReq = await dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              // Token refresh failed, force logout
              clearSession();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api/v1';
    }
    if (!kIsWeb && Platform.isAndroid) {
      // Android Emulator maps host localhost to 10.0.2.2
      return 'http://10.0.2.2:8001/api/v1';
    }
    return 'http://127.0.0.1:8001/api/v1';
  }

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void setActiveWorkspace(String? workspaceId) {
    _activeWorkspaceId = workspaceId;
  }

  void clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _activeWorkspaceId = null;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );
      if (res.statusCode == 200 && res.data != null) {
        _accessToken = res.data['access_token'];
        _refreshToken = res.data['refresh_token'];
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
