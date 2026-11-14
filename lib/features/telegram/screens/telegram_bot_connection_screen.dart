import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class TelegramBotConnectionScreen extends StatefulWidget {
  const TelegramBotConnectionScreen({super.key});

  @override
  State<TelegramBotConnectionScreen> createState() => _TelegramBotConnectionScreenState();
}

class _TelegramBotConnectionScreenState extends State<TelegramBotConnectionScreen> {
  final _botUsernameController = TextEditingController(text: '@CyberMagicSocialBot');
  final _tokenController = TextEditingController(text: '7482910482:AAE8x9...[ENCRYPTED]');
  bool _isConnected = true;
  bool _isSaving = false;

  void _handleSave() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSaving = false);
    AppToast.show(context, 'Bot token validated & securely encrypted in vault! (Demo)', isSuccess: true);
  }

  void _disconnectBot() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Disconnect Telegram Bot?',
        message: 'Disconnecting will stop automated broadcasts to all linked channels and supergroups.',
        confirmText: 'Disconnect',
        isDestructive: true,
        onConfirm: () {
          setState(() {
            _isConnected = false;
            _tokenController.clear();
          });
          AppToast.show(context, 'Telegram Bot disconnected (Demo)', isSuccess: true);
        },
      ),
    );
  }

  @override
  void dispose() {
    _botUsernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Telegram Bot Authorization & Secrets',
              subtitle: 'Connect your custom @BotFather bot token for secure automated channel dispatches.',
              breadcrumbs: const ['Channels', 'Telegram', 'Bot Configuration'],
              action: SecondaryButton(
                text: 'Back to Channels',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/telegram/channels'),
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.telegram.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.bot, color: AppColors.telegram, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official Telegram Bot Token', style: AppTypography.cardHeading),
                              Text('Created via @BotFather on Telegram', style: AppTypography.supporting),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: _isConnected ? 'Active & Paired' : 'Disconnected',
                          color: _isConnected ? AppColors.success : AppColors.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: 'Bot Username',
                      hintText: '@MyBrandSocialBot',
                      controller: _botUsernameController,
                      prefixIcon: const Icon(LucideIcons.atSign, size: 16),
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'Bot Secret API Token',
                      hintText: 'Enter 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                      controller: _tokenController,
                      obscureText: true,
                      prefixIcon: const Icon(LucideIcons.key, size: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🔒 Security Notice: Bot tokens are never displayed in plaintext after saving and are stored using AES-256 vault encryption.',
                      style: AppTypography.chip.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isConnected)
                          OutlinedActionButton(
                            text: 'Disconnect Bot',
                            icon: LucideIcons.trash2,
                            color: AppColors.danger,
                            onPressed: _disconnectBot,
                          )
                        else
                          const SizedBox(),
                        PrimaryButton(
                          text: 'Verify & Save Token',
                          icon: LucideIcons.shieldCheck,
                          isLoading: _isSaving,
                          onPressed: _handleSave,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
