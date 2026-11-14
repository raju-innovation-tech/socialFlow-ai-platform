import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers/auth_state_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_icons.dart';

class AppSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Brand Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SocialFlow AI',
                        style: AppTypography.cardHeading.copyWith(
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'AI Social Media Autopilot',
                        style: AppTypography.supporting.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                _buildNavItem(
                  context,
                  title: 'Dashboard',
                  icon: LucideIcons.layoutDashboard,
                  route: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  title: 'Content Calendar',
                  icon: LucideIcons.calendar,
                  route: '/calendar',
                ),
                _buildNavItem(
                  context,
                  title: 'Create Post',
                  icon: LucideIcons.fileEdit,
                  route: '/publishing/create',
                ),
                _buildNavItem(
                  context,
                  title: 'Platform Editor',
                  icon: LucideIcons.sliders,
                  route: '/publishing/editor',
                ),
                _buildNavItem(
                  context,
                  title: 'Multi-Preview',
                  icon: LucideIcons.eye,
                  route: '/publishing/preview',
                ),
                _buildNavItem(
                  context,
                  title: 'Approvals',
                  icon: LucideIcons.checkSquare,
                  route: '/approvals',
                  badgeCount: 2,
                ),
                _buildNavItem(
                  context,
                  title: 'Publishing Queue',
                  icon: LucideIcons.clock,
                  route: '/publishing/queue',
                ),
                _buildNavItem(
                  context,
                  title: 'Drafts',
                  icon: LucideIcons.fileText,
                  route: '/publishing/drafts',
                ),
                _buildNavItem(
                  context,
                  title: 'History & Logs',
                  icon: LucideIcons.history,
                  route: '/publishing/history',
                ),
                _buildNavItem(
                  context,
                  title: 'Media Library',
                  icon: LucideIcons.image,
                  route: '/media',
                ),
                _buildNavItem(
                  context,
                  title: 'Campaigns',
                  icon: LucideIcons.target,
                  route: '/campaigns',
                ),
                _buildNavItem(
                  context,
                  title: 'Analytics Overview',
                  icon: LucideIcons.barChart2,
                  route: '/analytics/overview',
                ),
                _buildNavItem(
                  context,
                  title: 'Platform Analytics',
                  icon: LucideIcons.trendingUp,
                  route: '/analytics/platforms',
                ),
                _buildNavItem(
                  context,
                  title: 'Reports & Export',
                  icon: LucideIcons.fileSpreadsheet,
                  route: '/analytics/reports',
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),

                // Channels Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'CHANNELS & AUTOMATION',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  title: 'WhatsApp Hub',
                  icon: LucideIcons.phoneCall,
                  route: '/whatsapp/business',
                ),
                _buildNavItem(
                  context,
                  title: 'Telegram Hub',
                  icon: LucideIcons.send,
                  route: '/telegram/channels',
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),

                // Workspace & Management
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'WORKSPACE',
                    style: AppTypography.chip.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  title: 'Social Accounts',
                  icon: LucideIcons.share2,
                  route: '/social-accounts',
                ),
                _buildNavItem(
                  context,
                  title: 'Team Members',
                  icon: LucideIcons.users,
                  route: '/team',
                ),
                _buildNavItem(
                  context,
                  title: 'Settings',
                  icon: LucideIcons.settings,
                  route: '/settings/profile',
                ),
                _buildNavItem(
                  context,
                  title: 'Billing & Plan',
                  icon: LucideIcons.creditCard,
                  route: '/billing/subscription',
                ),
                if (authState.isSuperAdmin)
                  _buildNavItem(
                    context,
                    title: 'Super Admin',
                    icon: LucideIcons.shieldCheck,
                    route: '/super-admin/dashboard',
                  ),

                const SizedBox(height: 16),

                // Connected Accounts quick widget
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Connected Accounts',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/social-accounts/connect'),
                            child: const Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildQuickAccountRow('Instagram', '@cybermagic.studio', AppColors.instagram),
                      const SizedBox(height: 8),
                      _buildQuickAccountRow('Facebook', 'Cyber Magic', AppColors.facebook),
                      const SizedBox(height: 8),
                      _buildQuickAccountRow('LinkedIn', 'Cyber Magic', AppColors.linkedin),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI Credits Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.zap, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text(
                            'Your AI Credits',
                            style: AppTypography.supporting.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '2,450',
                            style: AppTypography.cardHeading.copyWith(color: AppColors.textPrimary),
                          ),
                          Text(
                            ' / 5,000 used',
                            style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 2450 / 5000,
                        backgroundColor: AppColors.card,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Resets on 1 Jun 2025 (Demo)',
                        style: AppTypography.chip.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    int? badgeCount,
  }) {
    final bool isSelected = currentRoute == route || (route != '/dashboard' && currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: AppRadius.mdBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.16) : Colors.transparent,
            borderRadius: AppRadius.mdBorder,
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.25),
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: AppTypography.chip.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccountRow(String platform, String handle, Color brandColor) {
    return Row(
      children: [
        PlatformBrandIcon(platform: platform, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: AppTypography.supporting.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                handle,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.chip.copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
