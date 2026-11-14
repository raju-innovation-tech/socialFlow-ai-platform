import 'package:flutter/material.dart';
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

class ConnectedAccountsScreen extends StatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  State<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends State<ConnectedAccountsScreen> {
  late List<SocialAccount> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = List.from(MockData.connectedAccounts);
  }

  void _disconnectAccount(SocialAccount account) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Disconnect ${account.name}?',
        message: 'Disconnecting will stop automated publishing and revoke permissions. Scheduled posts will remain paused.',
        confirmText: 'Disconnect',
        isDestructive: true,
        onConfirm: () {
          setState(() {
            _accounts.removeWhere((a) => a.id == account.id);
          });
          AppToast.show(context, '${account.name} disconnected (Demo Mode)', isSuccess: true);
        },
      ),
    );
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
              title: 'Connected Accounts',
              subtitle: 'Manage omni-channel credentials, token lifecycles, and posting capabilities.',
              breadcrumbs: const ['Workspace', 'Social Accounts'],
              action: PrimaryButton(
                text: 'Connect New Platform',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/social-accounts/connect'),
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
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final acc = _accounts[index];
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
                  color: AppColors.success.withOpacity(0.14),
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Active', style: AppTypography.chip.copyWith(color: AppColors.success)),
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
                    '${(acc.followersCount / 1000).toStringAsFixed(1)}K',
                    style: AppTypography.cardHeading.copyWith(fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Token Health', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                  Text('Valid (60d left)', style: AppTypography.supporting.copyWith(color: AppColors.success)),
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
                    tooltip: 'Reconnect / Refresh Token',
                    onPressed: () => AppToast.show(context, 'Token refreshed successfully (Demo)', isSuccess: true),
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
