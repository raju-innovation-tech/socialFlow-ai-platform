import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/cards.dart';

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() => _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _platforms = ['LinkedIn', 'Instagram', 'Facebook', 'YouTube', 'X (Twitter)', 'WhatsApp', 'Telegram'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _platforms.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              title: 'Platform-Specific Analytics',
              subtitle: 'Native metrics and engagement breakdowns for individual channels.',
              breadcrumbs: const ['Workspace', 'Analytics', 'Platforms'],
              action: SecondaryButton(
                text: 'All Reports',
                icon: LucideIcons.fileSpreadsheet,
                onPressed: () => context.go('/analytics/reports'),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _platforms.map((p) {
                  return Tab(
                    child: Row(
                      children: [
                        PlatformBrandIcon(platform: p, size: 18),
                        const SizedBox(width: 8),
                        Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: _platforms.map((p) {
                  return _buildPlatformStatsTab(p);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStatsTab(String platform) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '$platform Impressions',
                value: '84.2K',
                trend: '↑ 14% this month',
                icon: LucideIcons.eye,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: '$platform CTR (Click Rate)',
                value: '4.8%',
                trend: '↑ 0.6% vs benchmark',
                icon: LucideIcons.mousePointer,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Follower Base',
                value: '65.4K',
                trend: '+1,240 this month',
                icon: LucideIcons.users,
                iconColor: AppColors.accentViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

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
              Text('Top Performing Content on $platform', style: AppTypography.cardHeading),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network('https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=100', width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: const Text('5 Design Trends to Watch in 2025'),
                subtitle: const Text('12,400 Reach • 1,420 Engagements • 310 Clicks'),
                trailing: const Icon(LucideIcons.trendingUp, color: AppColors.success),
              ),
              const Divider(color: AppColors.border),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network('https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=100', width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: const Text('3 Ways Data Improves Marketing Decisions'),
                subtitle: const Text('16,500 Reach • 2,180 Engagements • 640 Clicks'),
                trailing: const Icon(LucideIcons.trendingUp, color: AppColors.success),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
