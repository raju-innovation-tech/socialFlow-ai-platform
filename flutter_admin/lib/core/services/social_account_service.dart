import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/social_account.dart';

class SocialAccountService {
  final ApiClient _client = ApiClient();

  /// List all connected social accounts for current active workspace
  Future<List<SocialAccount>> listAccounts() async {
    try {
      final res = await _client.dio.get('/api/v1/social-accounts');
      if (res.data is List) {
        return (res.data as List)
            .map((item) => SocialAccount.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load social accounts';
      throw Exception(msg);
    }
  }

  /// Get details of a single connected social account
  Future<SocialAccount> getAccount(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/social-accounts/$id');
      return SocialAccount.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to load account details';
      throw Exception(msg);
    }
  }

  /// Disconnect a social account
  Future<void> disconnectAccount(String id) async {
    try {
      await _client.dio.delete('/api/v1/social-accounts/$id');
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to disconnect account';
      throw Exception(msg);
    }
  }

  /// Trigger live sync of account metrics and profile information
  Future<Map<String, dynamic>> syncAccount(String id) async {
    try {
      final res = await _client.dio.post('/api/v1/social-accounts/$id/sync');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Sync failed';
      throw Exception(msg);
    }
  }

  /// Trigger token reconnection / refresh
  Future<Map<String, dynamic>> reconnectAccount(String id) async {
    try {
      final res = await _client.dio.post('/api/v1/social-accounts/$id/reconnect');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Reconnect failed';
      throw Exception(msg);
    }
  }

  /// Fetch granted scopes & capabilities for account
  Future<Map<String, dynamic>> getPermissions(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/social-accounts/$id/permissions');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to fetch permissions';
      throw Exception(msg);
    }
  }

  /// Initiate OAuth2 authorization URL generation for a platform
  Future<Map<String, dynamic>> getAuthUrl(String platform) async {
    try {
      final res = await _client.dio.get('/api/v1/integrations/$platform/authorize');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to generate OAuth URL';
      throw Exception(msg);
    }
  }

  /// Connect Telegram Bot
  Future<Map<String, dynamic>> connectTelegram({
    required String botToken,
    String? chatId,
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/integrations/telegram/connect-bot',
        data: {
          'bot_token': botToken,
          if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Telegram connection failed';
      throw Exception(msg);
    }
  }

  /// Onboard WhatsApp Meta Cloud API
  Future<Map<String, dynamic>> onboardWhatsApp({
    required String phoneNumberId,
    required String wabaId,
    required String accessToken,
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/integrations/whatsapp/onboard',
        data: {
          'phone_number_id': phoneNumberId,
          'waba_id': wabaId,
          'access_token': accessToken,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'WhatsApp onboarding failed';
      throw Exception(msg);
    }
  }

  /// Fetch platform capabilities matrix
  Future<List<dynamic>> getCapabilities() async {
    try {
      final res = await _client.dio.get('/api/v1/integrations/capabilities');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Failed to fetch capabilities';
      throw Exception(msg);
    }
  }
}

