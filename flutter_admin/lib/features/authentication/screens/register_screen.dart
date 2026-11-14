import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/providers/auth_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = true;
  bool _isLoading = false;

  void _handleRegister() async {
    if (!_acceptTerms) {
      AppToast.show(context, 'Please accept Terms & Privacy Policy', isError: true);
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final res = await ref.read(authProvider.notifier).register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        final devOtp = res['dev_verification_otp'] as String?;
        AppToast.show(
          context,
          devOtp != null
              ? 'Verification code sent! (Dev OTP: $devOtp)'
              : 'Verification code sent to your email!',
          isSuccess: true,
        );
        context.go('/verify-otp?email=${Uri.encodeComponent(_emailController.text.trim())}&otp=${devOtp ?? ''}');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            constraints: const BoxConstraints(maxWidth: 460),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create Free Workspace',
                        style: AppTypography.mainHeading.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        '14-day Pro trial with all 7 platforms unlocked',
                        style: AppTypography.supporting,
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: 'Full Name',
                      hintText: 'Jane Doe',
                      controller: _nameController,
                      prefixIcon: const Icon(LucideIcons.user, size: 18, color: AppColors.textSecondary),
                      validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Work Email',
                      hintText: 'name@company.com',
                      controller: _emailController,
                      prefixIcon: const Icon(LucideIcons.mail, size: 18, color: AppColors.textSecondary),
                      validator: (val) =>
                          val != null && val.contains('@') ? null : 'Valid email required',
                    ),
                    const SizedBox(height: 16),

                    PasswordField(
                      label: 'Password',
                      controller: _passwordController,
                      validator: (val) =>
                          val != null && val.length >= 8 ? null : 'Minimum 8 characters',
                    ),
                    const SizedBox(height: 16),

                    PasswordField(
                      label: 'Confirm Password',
                      hintText: 'Re-enter password',
                      controller: _confirmPasswordController,
                      validator: (val) =>
                          val == _passwordController.text ? null : 'Passwords do not match',
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (val) => setState(() => _acceptTerms = val ?? true),
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: AppTypography.supporting,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: 'Create Account',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: AppTypography.supporting),
                        InkWell(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign In',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
