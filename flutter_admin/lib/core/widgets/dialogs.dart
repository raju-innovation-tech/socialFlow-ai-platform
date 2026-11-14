import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.elevatedCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDestructive ? LucideIcons.alertTriangle : LucideIcons.helpCircle,
                  color: isDestructive ? AppColors.danger : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTypography.cardHeading),
              ],
            ),
            const SizedBox(height: 14),
            Text(message, style: AppTypography.bodyMuted),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  text: cancelText,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: confirmText,
                  gradient: isDestructive
                      ? const LinearGradient(colors: [AppColors.danger, Color(0xFFC53030)])
                      : null,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = true,
  }) {
    Color bg = AppColors.card;
    Color iconColor = AppColors.primary;
    IconData icon = LucideIcons.info;

    if (isError) {
      iconColor = AppColors.danger;
      icon = LucideIcons.alertCircle;
    } else if (isSuccess) {
      iconColor = AppColors.success;
      icon = LucideIcons.checkCircle;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
