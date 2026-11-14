import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/cards.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

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
              title: 'Super Admin Control Plane',
              subtitle: 'System-wide platform health, multi-tenant workspace oversight, and API quotas.',
              breadcrumbs: const ['Platform', 'Super Admin', 'Overview'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'API Health',
                    icon: LucideIcons.activity,
                    onPressed: () => context.go('/super-admin/api-health'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'System Logs',
                    icon: LucideIcons.terminal,
                    onPressed: () => context.go('/super-admin/logs'),
                  ),
                ],
              ),
            ),

            // Top KPI Row
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth > 550 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: w,
                      child: const StatCard(
                        title: 'Total Registered Users',
                        value: '18,420',
                        trend: '↑ 14% new this week',
                        icon: LucideIcons.users,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: const StatCard(
                        title: 'Active Workspaces',
                        value: '3,842',
                        trend: '↑ 8.2% monthly growth',
                        icon: LucideIcons.building2,
                        iconColor: AppColors.accentViolet,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: const StatCard(
                        title: 'Monthly Recurring Rev',
                        value: '\$248.5K',
                        trend: '↑ 22% ARR velocity',
                        icon: LucideIcons.dollarSign,
                        iconColor: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: const StatCard(
                        title: 'Platform System Health',
                        value: '99.98%',
                        trend: 'All 7 APIs Operational',
                        icon: LucideIcons.shieldCheck,
                        iconColor: AppColors.info,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Modules quick links
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
                  Text('Super Admin Management Modules', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleTile(
                          context,
                          title: 'User Management',
                          subtitle: 'View 18.4K users, suspend accounts, and view auth logs.',
                          icon: LucideIcons.users,
                          route: '/super-admin/users',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModuleTile(
                          context,
                          title: 'Workspace Management',
                          subtitle: 'Manage 3.8K enterprise tenant workspaces & quotas.',
                          icon: LucideIcons.building,
                          route: '/super-admin/workspaces',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModuleTile(
                          context,
                          title: 'API Health & Rate Limits',
                          subtitle: 'Live status of LinkedIn, Meta, Google, Telegram & X APIs.',
                          icon: LucideIcons.activity,
                          route: '/super-admin/api-health',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModuleTile(
                          context,
                          title: 'System Logs & Workers',
                          subtitle: 'Redis queues, Celery workers, and background schedulers.',
                          icon: LucideIcons.terminal,
                          route: '/super-admin/logs',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: AppRadius.mdBorder,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.supporting),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
