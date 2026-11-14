import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final bool readOnly;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.supporting.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    this.label = 'Password',
    this.hintText = 'Enter your password',
    this.controller,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      obscureText: _obscure,
      prefixIcon: const Icon(LucideIcons.lock, size: 18, color: AppColors.textSecondary),
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
          size: 18,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      validator: widget.validator,
    );
  }
}

class SearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final double width;

  const SearchField({
    super.key,
    this.hintText = 'Search anything...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 14, color: AppColors.textSecondary),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          fillColor: AppColors.secondaryBackground,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdBorder,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdBorder,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdBorder,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.elevatedCard,
          icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textSecondary),
          style: AppTypography.body,
        ),
      ),
    );
  }
}
