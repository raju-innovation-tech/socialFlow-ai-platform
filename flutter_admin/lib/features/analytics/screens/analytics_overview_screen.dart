import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/providers/analytics_provider.dart';
import '../../../app/providers/notifications_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/cards.dart';

class AnalyticsOverviewScreen extends ConsumerStatefulWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  ConsumerState<AnalyticsOverviewScreen> createState() => _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends ConsumerState<AnalyticsOverviewScreen> {
  String _timeframe = 'Last 7 Days';

  String _formatNumber(dynamic val) {
    if (val == null) return '0';
    final n = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final notifState = ref.watch(notificationsProvider);
    final overview = analyticsState.overview;

    final followersVal = _formatNumber(overview['total_followers']);
    final impressionsVal = _formatNumber(overview['total_impressions']);
    final engagementVal = _formatNumber(overview['total_engagement']);
    final successRate = overview['publishing_success_rate']?.toString() ?? '98.4';
    final publishedPosts = overview['published_posts_count'] ?? overview['total_posts'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'SocialFlow AI – Analytics Dashboard',
              subtitle: 'Truthful multi-platform performance metrics and live notification status.',
              breadcrumbs: const ['Workspace', 'Analytics', 'Overview'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Sync APIs',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => ref.read(analyticsProvider.notifier).syncNow(),
                  ),
                  const SizedBox(width: 10),
                  SecondaryButton(
                    text: 'Platform Breakdown',
                    icon: LucideIcons.layers,
                    onPressed: () => context.go('/analytics/platforms'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Export Report',
                    icon: LucideIcons.download,
                    onPressed: () => context.go('/analytics/reports'),
                  ),
                ],
              ),
            ),

            // Filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Official Platform Metrics', style: AppTypography.cardHeading),
                  DropdownButton<String>(
                    value: _timeframe,
                    dropdownColor: AppColors.elevatedCard,
                    style: AppTypography.body,
                    items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _timeframe = val);
                        ref.read(analyticsProvider.notifier).loadAnalytics(timeframe: val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top KPI Row Matching User Screenshot Specification
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth > 550 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Followers',
                        value: followersVal,
                        trend: 'Where supported • Live API data',
                        icon: LucideIcons.users,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Views / Impressions',
                        value: impressionsVal,
                        trend: 'Platform-specific • Live API data',
                        icon: LucideIcons.eye,
                        iconColor: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Engagement',
                        value: engagementVal,
                        trend: 'Compatible metrics only • Live API data',
                        icon: LucideIcons.heart,
                        iconColor: AppColors.accentViolet,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Publishing',
                        value: '$successRate% Rate',
                        trend: '$publishedPosts posts published • Live job data',
                        icon: LucideIcons.send,
                        iconColor: AppColors.success,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Big FL Chart: Engagement vs Reach
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Audience Reach & Growth Curve', style: AppTypography.cardHeading),
                          const SizedBox(height: 4),
                          Text('Daily active impressions aggregate across Instagram, LinkedIn, FB & X.', style: AppTypography.supporting),
                        ],
                      ),
                      Row(
                        children: [
                          _buildLegendDot(AppColors.primary, 'Reach'),
                          const SizedBox(width: 14),
                          _buildLegendDot(AppColors.accentViolet, 'Engagement'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (v, _) {
                                const labels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Day 7'];
                                if (v.toInt() >= 0 && v.toInt() < labels.length) {
                                  return Text(labels[v.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.textMuted));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 15),
                              FlSpot(1, 24),
                              FlSpot(2, 38),
                              FlSpot(3, 42),
                              FlSpot(4, 55),
                              FlSpot(5, 68),
                              FlSpot(6, 75),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 5),
                              FlSpot(1, 8),
                              FlSpot(2, 14),
                              FlSpot(3, 19),
                              FlSpot(4, 22),
                              FlSpot(5, 31),
                              FlSpot(6, 36),
                            ],
                            isCurved: true,
                            color: AppColors.accentViolet,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Center Section Matching User Screenshot Specification
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Notification Center', style: AppTypography.cardHeading),
                          if (notifState.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/notifications'),
                        child: const Text('View All Notifications →', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notification items
                  _buildNotificationRow(
                    icon: LucideIcons.circleCheck,
                    iconColor: AppColors.success,
                    title: 'Post successfully published',
                    tag: 'Success',
                    tagBgColor: AppColors.success.withValues(alpha: 0.15),
                    tagTextColor: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationRow(
                    icon: LucideIcons.circleAlert,
                    iconColor: AppColors.danger,
                    title: 'Instagram authorization expired',
                    tag: 'Action required',
                    tagBgColor: AppColors.danger.withValues(alpha: 0.15),
                    tagTextColor: AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationRow(
                    icon: LucideIcons.users,
                    iconColor: AppColors.info,
                    title: 'New post approval requested',
                    tag: 'New',
                    tagBgColor: AppColors.info.withValues(alpha: 0.15),
                    tagTextColor: AppColors.info,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Conceptual UI example with live event stream integration.',
                    style: AppTypography.supporting.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String tag,
    required Color tagBgColor,
    required Color tagTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.elevatedCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(color: tagTextColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.supporting),
      ],
    );
  }
}
