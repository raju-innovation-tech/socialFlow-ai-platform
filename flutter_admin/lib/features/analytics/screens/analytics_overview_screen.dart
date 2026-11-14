import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/cards.dart';

class AnalyticsOverviewScreen extends StatefulWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  State<AnalyticsOverviewScreen> createState() => _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends State<AnalyticsOverviewScreen> {
  String _timeframe = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Omni-Channel Analytics',
              subtitle: 'Comprehensive performance attribution across all 7 connected channels.',
              breadcrumbs: const ['Workspace', 'Analytics', 'Overview'],
              action: Row(
                children: [
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
                  Text('Aggregate Engagement Metrics', style: AppTypography.cardHeading),
                  DropdownButton<String>(
                    value: _timeframe,
                    dropdownColor: AppColors.elevatedCard,
                    style: AppTypography.body,
                    items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Year to Date']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _timeframe = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top KPI Row
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
                      child: const StatCard(
                        title: 'Total Impressions',
                        value: '248.5K',
                        trend: '↑ 24% vs last period',
                        icon: LucideIcons.eye,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const StatCard(
                        title: 'Total Engagements',
                        value: '38.2K',
                        trend: '↑ 18.4% vs last period',
                        icon: LucideIcons.heart,
                        iconColor: AppColors.accentViolet,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const StatCard(
                        title: 'Link Clicks',
                        value: '9,450',
                        trend: '↑ 31% vs last period',
                        icon: LucideIcons.mousePointer,
                        iconColor: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const StatCard(
                        title: 'Audience Growth',
                        value: '+4,820',
                        trend: '↑ 12% net growth',
                        icon: LucideIcons.userPlus,
                        iconColor: AppColors.warning,
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
                    height: 280,
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
                                const labels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
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
          ],
        ),
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
