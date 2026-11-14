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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@cybermagic.studio');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _rememberMe = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        await ref.read(authProvider.notifier).login(email, password);
        if (!mounted) return;
        setState(() => _isLoading = false);
        final state = ref.read(authProvider);
        AppToast.show(context, 'Welcome back, ${state.userName}!', isSuccess: true);
        context.go('/dashboard');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final err = e.toString().replaceAll('Exception: ', '');
        AppToast.show(context, err, isSuccess: false);
        if (err.toLowerCase().contains('not verified') || err.toLowerCase().contains('verification')) {
          context.go('/otp-verification');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'SocialFlow AI',
                        style: AppTypography.mainHeading.copyWith(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Sign in to your omni-channel workspace',
                        style: AppTypography.supporting,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Email Field
                    CustomTextField(
                      label: 'Work Email',
                      hintText: 'name@company.com',
                      controller: _emailController,
                      prefixIcon: const Icon(LucideIcons.mail, size: 18, color: AppColors.textSecondary),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    PasswordField(
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Remember Me & Forgot Password
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Text('Remember me', style: AppTypography.supporting),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Login Button
                    PrimaryButton(
                      text: 'Sign In',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 16),

                    // Demo Quick Action
                    Center(
                      child: OutlinedActionButton(
                        text: 'Quick Demo Access',
                        icon: LucideIcons.zap,
                        onPressed: () => context.go('/dashboard'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: AppTypography.supporting),
                          InkWell(
                            onTap: () => context.go('/register'),
                            child: Text(
                              'Create Workspace',
                              style: AppTypography.supporting.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
