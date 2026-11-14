import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers/auth_state_provider.dart';
import '../../app/providers/notifications_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';
import '../widgets/dialogs.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const AppTopBar({
    super.key,
    this.onMenuPressed,
    this.isMobile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'SF';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final initials = _getInitials(authState.userName.isNotEmpty ? authState.userName : 'Cyber Magic');
    final displayName = authState.userName.isNotEmpty ? authState.userName : 'Cyber Magic Team';
    final roleName = authState.isSuperAdmin
        ? 'Super Admin'
        : (authState.role.name[0].toUpperCase() + authState.role.name.substring(1));

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(LucideIcons.menu, color: AppColors.textPrimary),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],

          // Search Field on Desktop/Tablet
          if (!isMobile)
            Container(
              width: 300,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const TextField(
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search posts, campaigns, tags...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

          const Spacer(),

          // Active Workspace / Mode Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: authState.isAuthenticated
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: authState.isAuthenticated ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  authState.isAuthenticated
                      ? authState.currentWorkspaceName.toUpperCase()
                      : 'DEMO MODE',
                  style: AppTypography.chip.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // "+ Create with AI" Button matching screenshot
          PrimaryButton(
            text: isMobile ? 'Create' : 'Create with AI',
            icon: LucideIcons.sparkles,
            height: 38,
            onPressed: () => context.go('/publishing/create'),
          ),

          const SizedBox(width: 12),

          // Notification Bell
          Consumer(
            builder: (context, ref, _) {
              final notifState = ref.watch(notificationsProvider);
              final hasUnread = notifState.unreadCount > 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.bell, size: 16, color: AppColors.textPrimary),
                      onPressed: () => context.go('/notifications'),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          notifState.unreadCount > 9 ? '9+' : '${notifState.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 14),

          // Profile Pill with Workspace Switcher Popup Menu
          PopupMenuButton<String>(
            tooltip: 'User & Workspace Menu',
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdBorder,
              side: const BorderSide(color: AppColors.border),
            ),
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  AppToast.show(context, 'Signed out successfully', isSuccess: true);
                  context.go('/login');
                }
              } else if (value == 'profile') {
                context.go('/settings/profile');
              } else if (value.startsWith('ws:')) {
                final wsId = value.substring(3);
                try {
                  await ref.read(authProvider.notifier).switchWorkspace(wsId);
                  if (context.mounted) {
                    AppToast.show(context, 'Switched workspace', isSuccess: true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(context, e.toString(), isError: true);
                  }
                }
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];

              // User Info Header
              items.add(
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                      if (authState.userEmail.isNotEmpty)
                        Text(authState.userEmail, style: AppTypography.supporting.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              );

              // Workspaces list
              if (authState.workspaces.isNotEmpty) {
                items.add(const PopupMenuDivider());
                items.add(
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'WORKSPACES',
                      style: AppTypography.chip.copyWith(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                );
                for (final ws in authState.workspaces) {
                  final isCurrent = ws.id == authState.currentWorkspaceId;
                  items.add(
                    PopupMenuItem<String>(
                      value: 'ws:${ws.id}',
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? LucideIcons.check : LucideIcons.building2,
                            size: 14,
                            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ws.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              items.add(const PopupMenuDivider());
              items.add(
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('Profile Settings', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
              items.add(
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(LucideIcons.logOut, size: 14, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                    ],
                  ),
                ),
              );

              return items;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: authState.isSuperAdmin
                          ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.supporting.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: authState.isSuperAdmin ? const Color(0xFF8B5CF6) : AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              roleName,
                              style: AppTypography.chip.copyWith(
                                color: authState.isSuperAdmin ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: authState.isSuperAdmin ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

