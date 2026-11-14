import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Gradient? gradient;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 44,
    this.gradient,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final decoration = BoxDecoration(
      gradient: enabled
          ? (widget.gradient ?? AppColors.primaryGradient)
          : LinearGradient(
              colors: [Colors.grey.shade800, Colors.grey.shade900],
            ),
      borderRadius: AppRadius.mdBorder,
      boxShadow: _isHovered && enabled
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ]
          : [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
    );

    Widget child = InkWell(
      onTap: enabled ? widget.onPressed : null,
      onHover: (hover) => setState(() => _isHovered = hover),
      borderRadius: AppRadius.mdBorder,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: decoration,
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(text, style: AppTypography.button.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class OutlinedActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const OutlinedActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: activeColor,
        side: BorderSide(color: activeColor.withOpacity(0.5)),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: activeColor),
            const SizedBox(width: 6),
          ],
          Text(text, style: AppTypography.chip.copyWith(color: activeColor)),
        ],
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 0.28),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: size * 0.48,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

