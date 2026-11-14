import 'package:dio/dio.dart';
import '../network/api_client.dart';

class BillingService {
  final ApiClient _client = ApiClient();

  /// List available SaaS subscription plans
  Future<List<Map<String, dynamic>>> listPlans() async {
    try {
      final res = await _client.dio.get('/api/v1/billing/plans');
      if (res.data is List) {
        return (res.data as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load subscription plans';
      throw Exception(msg);
    }
  }

  /// Get active subscription details for current workspace
  Future<Map<String, dynamic>> getSubscription() async {
    try {
      final res = await _client.dio.get('/api/v1/billing/subscription');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load subscription';
      throw Exception(msg);
    }
  }

  /// Get real-time consumption vs entitlement limits
  Future<Map<String, dynamic>> getUsage() async {
    try {
      final res = await _client.dio.get('/api/v1/billing/usage');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load resource usage';
      throw Exception(msg);
    }
  }

  /// Create checkout session with Razorpay order
  Future<Map<String, dynamic>> createCheckout({
    required String planCode,
    String billingCycle = 'monthly',
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/billing/checkout',
        data: {'plan_code': planCode, 'billing_cycle': billingCycle},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to initiate checkout';
      throw Exception(msg);
    }
  }

  /// Verify Razorpay payment signature and activate plan
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planCode,
    String billingCycle = 'monthly',
  }) async {
    try {
      final res = await _client.dio.post(
        '/api/v1/billing/verify-payment',
        data: {
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': signature,
          'plan_code': planCode,
          'billing_cycle': billingCycle,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Payment verification failed';
      throw Exception(msg);
    }
  }

  /// Cancel subscription at end of current period
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final res = await _client.dio.post('/api/v1/billing/subscription/cancel');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to cancel subscription';
      throw Exception(msg);
    }
  }

  /// Resume scheduled cancelled subscription
  Future<Map<String, dynamic>> resumeSubscription() async {
    try {
      final res = await _client.dio.post('/api/v1/billing/subscription/resume');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to resume subscription';
      throw Exception(msg);
    }
  }

  /// List all invoices
  Future<List<Map<String, dynamic>>> listInvoices() async {
    try {
      final res = await _client.dio.get('/api/v1/billing/invoices');
      if (res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load invoices';
      throw Exception(msg);
    }
  }
}

