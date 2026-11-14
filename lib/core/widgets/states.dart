import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.inbox,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Icon(icon, size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.cardHeading),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                text: actionText!,
                onPressed: onAction,
                icon: LucideIcons.plus,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, style: AppTypography.body),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SecondaryButton(
                text: 'Retry',
                onPressed: onRetry,
                icon: LucideIcons.refreshCw,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: borderRadius ?? AppRadius.smBorder,
      ),
    );
  }
}
