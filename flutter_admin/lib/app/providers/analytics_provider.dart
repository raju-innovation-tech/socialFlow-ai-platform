import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/analytics_service.dart';

class AnalyticsState {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> platforms;
  final bool isLoading;
  final String? error;
  final String timeframe;

  const AnalyticsState({
    this.overview = const {},
    this.platforms = const [],
    this.isLoading = false,
    this.error,
    this.timeframe = 'Last 7 Days',
  });

  AnalyticsState copyWith({
    Map<String, dynamic>? overview,
    List<Map<String, dynamic>>? platforms,
    bool? isLoading,
    String? error,
    String? timeframe,
  }) {
    return AnalyticsState(
      overview: overview ?? this.overview,
      platforms: platforms ?? this.platforms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      timeframe: timeframe ?? this.timeframe,
    );
  }
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  final AnalyticsService _service = AnalyticsService();

  @override
  AnalyticsState build() {
    Future.microtask(() => loadAnalytics());
    return const AnalyticsState(
      overview: {
        'total_followers': 248500,
        'total_impressions': 184200,
        'total_engagement': 38200,
        'publishing_success_rate': 98.4,
        'total_posts': 56,
        'published_posts_count': 54,
        'failed_posts_count': 2,
        'daily_performance': [],
      },
    );
  }

  String _mapTimeframeToParam(String label) {
    switch (label) {
      case 'Last 7 Days':
        return 'last_7_days';
      case 'Last 30 Days':
        return 'last_30_days';
      case 'Last 90 Days':
        return 'last_90_days';
      default:
        return 'last_7_days';
    }
  }

  Future<void> loadAnalytics({String? timeframe}) async {
    final tf = timeframe ?? state.timeframe;
    state = state.copyWith(isLoading: true, error: null, timeframe: tf);
    try {
      final periodParam = _mapTimeframeToParam(tf);
      final overviewData = await _service.getOverview(period: periodParam);
      final platformData = await _service.getPlatformAnalytics();
      state = state.copyWith(
        overview: overviewData,
        platforms: platformData,
        isLoading: false,
      );
    } catch (e) {
      // Retain fallback data gracefully if API is offline
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncNow() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.syncAnalytics();
      await loadAnalytics();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(() {
  return AnalyticsNotifier();
});

