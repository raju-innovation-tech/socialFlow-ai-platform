import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const AppTopBar({
    super.key,
    this.onMenuPressed,
    this.isMobile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
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

          // Demo Mode Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'DEMO MODE',
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
          Stack(
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications in Demo Mode')),
                    );
                  },
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Profile Pill matching screenshot
          InkWell(
            onTap: () => context.go('/settings/profile'),
            borderRadius: AppRadius.mdBorder,
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
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'CM',
                        style: TextStyle(
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
                          'Cyber Magic Team',
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
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: AppTypography.chip.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
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
