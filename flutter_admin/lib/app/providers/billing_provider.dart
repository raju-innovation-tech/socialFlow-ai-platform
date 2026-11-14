import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/billing_service.dart';

class BillingState {
  final Map<String, dynamic> subscription;
  final Map<String, dynamic> usage;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> invoices;
  final bool isLoading;
  final String? error;

  const BillingState({
    this.subscription = const {},
    this.usage = const {},
    this.plans = const [],
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  BillingState copyWith({
    Map<String, dynamic>? subscription,
    Map<String, dynamic>? usage,
    List<Map<String, dynamic>>? plans,
    List<Map<String, dynamic>>? invoices,
    bool? isLoading,
    String? error,
  }) {
    return BillingState(
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
      plans: plans ?? this.plans,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BillingNotifier extends Notifier<BillingState> {
  final BillingService _service = BillingService();

  @override
  BillingState build() {
    Future.microtask(() => loadBillingData());
    // Initial data matching the user's diagram specification
    return const BillingState(
      subscription: {
        'plan_code': 'pro',
        'plan_name': 'Professional Plan',
        'status': 'active',
        'billing_cycle': 'monthly',
      },
      usage: {
        'usage': {
          'connected_accounts': 7,
          'monthly_publishing': 48,
          'team_members': 3,
          'storage_mb': 14200.0,
        },
        'limits': {
          'max_social_accounts': 15,
          'monthly_published_targets': 200,
          'max_team_members': 5,
          'max_storage_mb': 50000,
        },
      },
    );
  }

  Future<void> loadBillingData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _service.listPlans();
      final usage = await _service.getUsage();
      final sub = await _service.getSubscription();
      final invoices = await _service.listInvoices();

      state = state.copyWith(
        plans: plans,
        usage: usage,
        subscription: sub,
        invoices: invoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelSubscription() async {
    try {
      await _service.cancelSubscription();
      await loadBillingData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeSubscription() async {
    try {
      await _service.resumeSubscription();
      await loadBillingData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(() {
  return BillingNotifier();
});

