import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/dialogs.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _secondsRemaining = 45;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Default demo OTP pre-filled for convenience
    _controllers[0].text = '7';
    _controllers[1].text = '4';
    _controllers[2].text = '9';
    _controllers[3].text = '2';
    _controllers[4].text = '1';
    _controllers[5].text = '8';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOtp() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      AppToast.show(context, 'Please enter all 6 digits', isError: true);
      return;
    }
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isVerifying = false);
    AppToast.show(context, 'Email verified successfully!', isSuccess: true);
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.mailCheck, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 18),
                  Text('Verify Your Email', style: AppTypography.mainHeading.copyWith(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit verification code to\nadmin@cybermagic.studio',
                    textAlign: TextAlign.center,
                    style: AppTypography.supporting,
                  ),
                  const SizedBox(height: 28),

                  // 6 OTP Digit Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 46,
                        height: 52,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppTypography.kpiValue.copyWith(fontSize: 20),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            fillColor: AppColors.secondaryBackground,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Verify & Continue',
                    isFullWidth: true,
                    isLoading: _isVerifying,
                    onPressed: _verifyOtp,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _secondsRemaining > 0
                            ? 'Resend code in ${_secondsRemaining}s'
                            : 'Did not receive code? ',
                        style: AppTypography.supporting,
                      ),
                      if (_secondsRemaining == 0)
                        InkWell(
                          onTap: _startTimer,
                          child: Text(
                            'Resend OTP',
                            style: AppTypography.supporting.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Back to Login',
                      style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
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
