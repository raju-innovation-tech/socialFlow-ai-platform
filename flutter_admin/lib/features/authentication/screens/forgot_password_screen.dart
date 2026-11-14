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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController(text: 'admin@cybermagic.studio');
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, 'Please enter a valid email', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final devOtp = await _authService.forgotPassword(email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(
        context,
        devOtp != null
            ? 'Password reset code sent! (Dev OTP: $devOtp)'
            : 'Password reset instructions sent to your email!',
        isSuccess: true,
      );
      context.go('/reset-password?email=${Uri.encodeComponent(email)}&otp=${devOtp ?? ''}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.keyRound, color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(height: 18),
                  Text('Reset Password', style: AppTypography.mainHeading.copyWith(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your registered email address and we will send a password reset link.',
                    style: AppTypography.supporting,
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'name@company.com',
                    controller: _emailController,
                    prefixIcon: const Icon(LucideIcons.mail, size: 18, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Send Reset Link',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: TextButton.icon(
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      label: const Text('Back to Sign In'),
                      onPressed: () => context.go('/login'),
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
