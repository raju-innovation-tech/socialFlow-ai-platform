import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            Row(
              children: [
                for (int i = 0; i < breadcrumbs!.length; i++) ...[
                  Text(
                    breadcrumbs![i],
                    style: AppTypography.supporting.copyWith(
                      color: i == breadcrumbs!.length - 1
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (i < breadcrumbs!.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(LucideIcons.chevronRight, size: 12, color: AppColors.textSecondary),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.mainHeading),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTypography.subHeading),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ],
      ),
    );
  }
}
