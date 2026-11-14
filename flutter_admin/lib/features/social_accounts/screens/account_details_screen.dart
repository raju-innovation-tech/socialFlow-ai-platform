import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/social_account.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../app/providers/social_accounts_provider.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialAccountsProvider);
    final account = state.accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => MockData.connectedAccounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => MockData.connectedAccounts.first,
      ),
    );

    final isConnected = account.status == AccountStatus.connected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: account.name,
              subtitle: 'Detailed connection status, channel metrics, and token settings.',
              breadcrumbs: ['Workspace', 'Social Accounts', account.name],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Refresh Token',
                    icon: LucideIcons.refreshCw,
                    onPressed: () async {
                      AppToast.show(context, 'Refreshing token health...');
                      final ok = await ref.read(socialAccountsProvider.notifier).syncAccount(account.id);
                      if (context.mounted) {
                        if (ok) {
                          AppToast.show(context, 'Token health refreshed: 100% OK', isSuccess: true);
                        } else {
                          AppToast.show(context, 'Token refresh failed', isError: true);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: 'Create Post for this Account',
                    icon: LucideIcons.fileEdit,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                ],
              ),
            ),

            // Profile & KPI Overview
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  PlatformBrandIcon(platform: account.platformName, size: 64),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(account.name, style: AppTypography.cardHeading.copyWith(fontSize: 20)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isConnected ? AppColors.success.withOpacity(0.14) : AppColors.warning.withOpacity(0.14),
                                borderRadius: AppRadius.pillBorder,
                              ),
                              child: Text(
                                isConnected ? 'Connected & Active' : 'Attention Required',
                                style: AppTypography.chip.copyWith(
                                  color: isConnected ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(account.handle, style: AppTypography.subHeading),
                        const SizedBox(height: 8),
                        Text(
                          'Connected on: ${account.connectedAt.month}/${account.connectedAt.day}/${account.connectedAt.year} • Official Graph & OAuth API',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Token Details & Perms Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Granted OAuth Scopes & Permissions', style: AppTypography.cardHeading),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: account.permissions.map((perm) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(perm, style: AppTypography.supporting.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Token Expiration Window', style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Tokens are stored encrypted with AES-128 and refreshed automatically.', style: AppTypography.supporting),
                        ],
                      ),
                      OutlinedActionButton(
                        text: 'Force Re-Authenticate',
                        icon: LucideIcons.lock,
                        onPressed: () async {
                          AppToast.show(context, 'Re-authenticating account...');
                          final ok = await ref.read(socialAccountsProvider.notifier).reconnectAccount(account.id);
                          if (context.mounted) {
                            if (ok) {
                              AppToast.show(context, 'Re-authentication verified successfully', isSuccess: true);
                            } else {
                              AppToast.show(context, 'Re-authentication failed', isError: true);
                            }
                          }
                        },
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
}
