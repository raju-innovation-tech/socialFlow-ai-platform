import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class SubscriptionUsageScreen extends StatelessWidget {
  const SubscriptionUsageScreen({super.key});

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
              title: 'Subscription & Resource Quotas',
              subtitle: 'Monitor account consumption, AI generation tokens, and active plan entitlements.',
              breadcrumbs: const ['Workspace', 'Billing', 'Subscription & Usage'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Invoice History',
                    icon: LucideIcons.receipt,
                    onPressed: () => context.go('/billing/invoices'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Upgrade to Enterprise',
                    icon: LucideIcons.zap,
                    onPressed: () => AppToast.show(context, 'Enterprise upgrade checkout modal (Demo)', isSuccess: true),
                  ),
                ],
              ),
            ),

            // Current Plan Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2640), Color(0xFF121B2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.crown, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Pro Growth Plan', style: AppTypography.cardHeading.copyWith(fontSize: 20)),
                            const SizedBox(width: 10),
                            const StatusBadge(label: 'Active Subscription', color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('\$149/month • Renews on June 1, 2025 • Up to 15 social channels', style: AppTypography.supporting),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Usage Meters
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
                  Text('Active Resource Consumption', style: AppTypography.cardHeading),
                  const SizedBox(height: 20),
                  _buildQuotaMeter('AI Generation Credits', '2,450 / 5,000 credits used', 2450 / 5000, AppColors.primary),
                  const SizedBox(height: 18),
                  _buildQuotaMeter('Connected Social Channels', '7 / 15 platforms active', 7 / 15, AppColors.accentViolet),
                  const SizedBox(height: 18),
                  _buildQuotaMeter('Monthly Scheduled Posts', '48 / 200 posts queued', 48 / 200, AppColors.success),
                  const SizedBox(height: 18),
                  _buildQuotaMeter('Cloud Media Storage', '14.2 GB / 50 GB used', 14.2 / 50, AppColors.warning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaMeter(String label, String stat, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(stat, style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fraction,
          backgroundColor: AppColors.secondaryBackground,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
