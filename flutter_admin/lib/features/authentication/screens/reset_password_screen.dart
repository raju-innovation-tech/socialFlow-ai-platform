import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService();
  double _strength = 0.0;
  String _strengthLabel = 'Too short';
  Color _strengthColor = AppColors.danger;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final qEmail = GoRouterState.of(context).uri.queryParameters['email'];
    final qOtp = GoRouterState.of(context).uri.queryParameters['otp'];
    if (qEmail != null && _emailController.text.isEmpty) {
      _emailController.text = qEmail;
    }
    if (qOtp != null && _otpController.text.isEmpty) {
      _otpController.text = qOtp;
    }
  }

  void _calculateStrength(String value) {
    if (value.isEmpty) {
      setState(() {
        _strength = 0;
        _strengthLabel = 'Empty';
        _strengthColor = AppColors.textMuted;
      });
      return;
    }
    double score = 0.0;
    if (value.length >= 8) score += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) score += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) score += 0.25;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) score += 0.25;

    setState(() {
      _strength = score;
      if (score <= 0.25) {
        _strengthLabel = 'Weak';
        _strengthColor = AppColors.danger;
      } else if (score <= 0.5) {
        _strengthLabel = 'Fair';
        _strengthColor = AppColors.warning;
      } else if (score <= 0.75) {
        _strengthLabel = 'Good';
        _strengthColor = AppColors.info;
      } else {
        _strengthLabel = 'Strong';
        _strengthColor = AppColors.success;
      }
    });
  }

  void _handleReset() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, 'Please enter a valid email', isError: true);
      return;
    }
    if (otp.length < 6) {
      AppToast.show(context, 'Please enter 6-digit reset code', isError: true);
      return;
    }
    if (_passwordController.text.length < 8) {
      AppToast.show(context, 'Password must be at least 8 characters', isError: true);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      AppToast.show(context, 'Passwords do not match', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: _passwordController.text,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, 'Password updated! Please log in.', isSuccess: true);
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(height: 18),
                  Text('Set New Password', style: AppTypography.mainHeading.copyWith(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    'Your new password must be at least 8 characters with a symbol and number.',
                    style: AppTypography.supporting,
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Account Email',
                    hintText: 'name@example.com',
                    controller: _emailController,
                    prefixIcon: const Icon(LucideIcons.mail, size: 16, color: AppColors.textSecondary),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: '6-Digit Reset Code',
                    hintText: 'Enter code sent to your email',
                    controller: _otpController,
                    prefixIcon: const Icon(LucideIcons.keyRound, size: 16, color: AppColors.textSecondary),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  PasswordField(
                    label: 'New Password',
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 8),

                  // Strength Indicator Bar
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordController,
                    builder: (context, value, _) {
                      _calculateStrength(value.text);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Strength: $_strengthLabel',
                                  style: AppTypography.chip.copyWith(color: _strengthColor)),
                              Text('${(_strength * 100).toInt()}%',
                                  style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _strength,
                            backgroundColor: AppColors.secondaryBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 4,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  PasswordField(
                    label: 'Confirm New Password',
                    hintText: 'Re-enter your password',
                    controller: _confirmController,
                  ),
                  const SizedBox(height: 26),

                  PrimaryButton(
                    text: 'Update Password',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleReset,
                  ),
                  const SizedBox(height: 18),

                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text('Cancel & Return', style: AppTypography.supporting),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
