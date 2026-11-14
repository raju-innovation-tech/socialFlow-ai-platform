import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSolid;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.isSolid = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor = color ?? AppColors.primary;
    final norm = label.toLowerCase();

    if (color == null) {
      if (norm.contains('scheduled') || norm.contains('connected') || norm.contains('approved') || norm.contains('active')) {
        badgeColor = AppColors.success;
      } else if (norm.contains('review') || norm.contains('pending') || norm.contains('draft') || norm.contains('paused')) {
        badgeColor = AppColors.warning;
      } else if (norm.contains('failed') || norm.contains('error') || norm.contains('expired') || norm.contains('disconnected')) {
        badgeColor = AppColors.danger;
      } else if (norm.contains('published')) {
        badgeColor = AppColors.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSolid ? badgeColor : badgeColor.withOpacity(0.14),
        borderRadius: AppRadius.pillBorder,
        border: isSolid ? null : Border.all(color: badgeColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: isSolid ? Colors.white : badgeColor),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSolid ? Colors.white : badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.chip.copyWith(
              color: isSolid ? Colors.white : badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

