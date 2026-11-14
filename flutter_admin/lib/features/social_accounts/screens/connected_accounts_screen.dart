import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/models/social_account.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../app/providers/social_accounts_provider.dart';

class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends ConsumerState<ConnectedAccountsScreen> {
  void _disconnectAccount(SocialAccount account) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ConfirmationDialog(
        title: 'Disconnect ${account.name}?',
        message: 'Disconnecting will stop automated publishing and revoke permissions. Scheduled posts will remain paused.',
        confirmText: 'Disconnect',
        isDestructive: true,
        onConfirm: () async {
          final ok = await ref.read(socialAccountsProvider.notifier).disconnectAccount(account.id);
          if (!mounted) return;
          if (ok) {
            AppToast.show(context, '${account.name} disconnected successfully', isSuccess: true);
          } else {
            AppToast.show(context, 'Failed to disconnect account', isError: true);
          }
        },
      ),
    );
  }

  void _syncAccount(SocialAccount account) async {
    AppToast.show(context, 'Syncing account metrics with ${account.name}...');
    final ok = await ref.read(socialAccountsProvider.notifier).syncAccount(account.id);
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, '${account.name} metrics synced successfully', isSuccess: true);
    } else {
      AppToast.show(context, 'Account sync failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialAccountsProvider);
    final accounts = state.accounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Connected Accounts',
              subtitle: 'Manage omni-channel credentials, token lifecycles, and posting capabilities.',
              breadcrumbs: const ['Workspace', 'Social Accounts'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Refresh',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => ref.read(socialAccountsProvider.notifier).loadAccounts(),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: 'Connect New Platform',
                    icon: LucideIcons.plus,
                    onPressed: () => context.go('/social-accounts/connect'),
                  ),
                ],
              ),
            ),

            // Top notice banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All connections use official OAuth2 and Graph API tokens. Tokens are encrypted in transit and securely refreshed automatically.',
                      style: AppTypography.supporting.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  OutlinedActionButton(
                    text: 'View Permissions',
                    onPressed: () => context.go('/social-accounts/permissions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (accounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(LucideIcons.share2, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('No social accounts connected yet', style: AppTypography.cardHeading),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your official social media channels to start scheduling and analyzing posts.',
                        style: AppTypography.supporting,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: 'Connect Your First Platform',
                        icon: LucideIcons.plus,
                        onPressed: () => context.go('/social-accounts/connect'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Grid of Connected Accounts
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      return _buildAccountCard(acc);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(SocialAccount acc) {
    final isConnected = acc.status == AccountStatus.connected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PlatformBrandIcon(platform: acc.platformName, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.name,
                      style: AppTypography.cardHeading,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acc.handle,
                      style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success.withOpacity(0.14) : AppColors.warning.withOpacity(0.14),
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: isConnected ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isConnected ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? 'Active' : 'Attention',
                      style: AppTypography.chip.copyWith(
                        color: isConnected ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audience / Followers', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                  Text(
                    acc.followersCount >= 1000
                        ? '${(acc.followersCount / 1000).toStringAsFixed(1)}K'
                        : '${acc.followersCount}',
                    style: AppTypography.cardHeading.copyWith(fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Token Health', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                  Text(
                    isConnected ? 'Valid & Encrypted' : 'Requires Reauth',
                    style: AppTypography.supporting.copyWith(
                      color: isConnected ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 1, color: AppColors.border),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.go('/social-accounts/details/${acc.id}'),
                child: Text(
                  'Details & Metrics',
                  style: AppTypography.supporting.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.textSecondary),
                    tooltip: 'Sync Metrics & Refresh Token',
                    onPressed: () => _syncAccount(acc),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                    tooltip: 'Disconnect',
                    onPressed: () => _disconnectAccount(acc),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
