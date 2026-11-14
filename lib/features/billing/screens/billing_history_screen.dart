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

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = [
      {'invoice': 'INV-2025-005', 'date': 'May 01, 2025', 'amount': '\$149.00', 'status': 'Paid', 'card': 'Mastercard ending in 4242'},
      {'invoice': 'INV-2025-004', 'date': 'Apr 01, 2025', 'amount': '\$149.00', 'status': 'Paid', 'card': 'Mastercard ending in 4242'},
      {'invoice': 'INV-2025-003', 'date': 'Mar 01, 2025', 'amount': '\$149.00', 'status': 'Paid', 'card': 'Mastercard ending in 4242'},
      {'invoice': 'INV-2025-002', 'date': 'Feb 01, 2025', 'amount': '\$149.00', 'status': 'Paid', 'card': 'Mastercard ending in 4242'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Invoices & Billing History',
              subtitle: 'Download tax receipts, update corporate card info, and review billing statements.',
              breadcrumbs: const ['Workspace', 'Billing', 'Invoices'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Subscription Quotas',
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => context.go('/billing/subscription'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Update Payment Method',
                    icon: LucideIcons.creditCard,
                    onPressed: () => AppToast.show(context, 'Stripe card element modal triggered (Demo)', isSuccess: true),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Billing Statements', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 20),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv['invoice']!, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                Text('${inv["date"]} • Billed to ${inv["card"]}', style: AppTypography.supporting),
                              ],
                            ),
                          ),
                          Text(inv['amount']!, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                          const SizedBox(width: 16),
                          StatusBadge(label: inv['status']!, color: AppColors.success),
                          const SizedBox(width: 12),
                          OutlinedActionButton(
                            text: 'PDF',
                            icon: LucideIcons.download,
                            onPressed: () => AppToast.show(context, 'Downloading ${inv["invoice"]}.pdf (Demo)', isSuccess: true),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
