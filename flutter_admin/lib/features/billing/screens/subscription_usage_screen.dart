import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/providers/billing_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class SubscriptionUsageScreen extends ConsumerStatefulWidget {
  const SubscriptionUsageScreen({super.key});

  @override
  ConsumerState<SubscriptionUsageScreen> createState() => _SubscriptionUsageScreenState();
}

class _SubscriptionUsageScreenState extends ConsumerState<SubscriptionUsageScreen> {
  void _openManageSubscriptionModal(BuildContext context, BillingState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final plans = state.plans;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Choose Subscription Plan', style: AppTypography.cardHeading.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Upgrade or change your SaaS tier with official Razorpay integration.', style: AppTypography.supporting),
                const SizedBox(height: 20),
                ...plans.map((p) {
                  final isCurrent = p['plan_code'] == state.subscription['plan_code'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : AppColors.secondaryBackground,
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name']?.toString() ?? 'Plan', style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              '${p['currency']} ${p['price_monthly']}/mo • ${p['max_social_accounts']} accounts • ${p['monthly_published_targets']} posts',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                        if (isCurrent)
                          const StatusBadge(label: 'Current Plan', color: AppColors.success)
                        else
                          PrimaryButton(
                            text: 'Select',
                            height: 36,
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected ${p['name']}. Razorpay checkout initiated.')),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final usageData = billingState.usage['usage'] ?? {};
    final limitsData = billingState.usage['limits'] ?? {};

    final planName = billingState.subscription['plan_name'] ?? 'Professional Plan';
    final status = billingState.subscription['status'] ?? 'active';

    final accountsUsed = usageData['connected_accounts'] ?? 7;
    final accountsLimit = limitsData['max_social_accounts'] ?? 15;

    final pubUsed = usageData['monthly_publishing'] ?? 48;
    final pubLimit = limitsData['monthly_published_targets'] ?? 200;

    final teamUsed = usageData['team_members'] ?? 3;
    final teamLimit = limitsData['max_team_members'] ?? 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Customer Billing Dashboard',
              subtitle: 'Monitor plan subscription, official pricing, and real-time quota consumption.',
              breadcrumbs: const ['Workspace', 'Billing', 'Subscription & Usage'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Invoice History',
                    icon: LucideIcons.receipt,
                    onPressed: () => context.go('/billing/invoices'),
                  ),
                ],
              ),
            ),

            // Plan & Subscription Box Matching User Screenshot
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
                      Text(
                        planName,
                        style: AppTypography.cardHeading.copyWith(fontSize: 18, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: AppTypography.chip.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Subscription', style: AppTypography.sectionHeading.copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    'Illustrative UI – actual pricing backend se aayegi',
                    style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // 3 Key Quota Rows Matching User Diagram
                  _buildUsageRow('Connected accounts', '$accountsUsed / $accountsLimit', accountsUsed / accountsLimit),
                  const SizedBox(height: 18),
                  _buildUsageRow('Monthly publishing', '$pubUsed / $pubLimit', pubUsed / pubLimit),
                  const SizedBox(height: 18),
                  _buildUsageRow('Team members', '$teamUsed / $teamLimit', teamUsed / teamLimit),
                  const SizedBox(height: 28),

                  // "Manage Subscription" Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppColors.secondaryBackground,
                      ),
                      onPressed: () => _openManageSubscriptionModal(context, billingState),
                      child: Text(
                        'Manage Subscription',
                        style: AppTypography.button.copyWith(color: AppColors.textPrimary),
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

  Widget _buildUsageRow(String label, String stat, double fraction) {
    final clampedFraction = fraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
            Text(stat, style: AppTypography.chip.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: clampedFraction,
          backgroundColor: AppColors.secondaryBackground,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
