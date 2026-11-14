import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../app/providers/social_accounts_provider.dart';

class ConnectPlatformScreen extends ConsumerStatefulWidget {
  const ConnectPlatformScreen({super.key});

  @override
  ConsumerState<ConnectPlatformScreen> createState() => _ConnectPlatformScreenState();
}

class _ConnectPlatformScreenState extends ConsumerState<ConnectPlatformScreen> {
  final List<_PlatformInfo> _platforms = [
    _PlatformInfo(
      key: 'linkedin',
      title: 'LinkedIn',
      subtitle: 'Company Pages & Personal Profiles',
      description: 'Auto-publish carousels, text, images, and track corporate engagement.',
      icon: Icons.business_center_rounded,
      brandColor: AppColors.linkedin,
      isOAuth: true,
    ),
    _PlatformInfo(
      key: 'facebook',
      title: 'Facebook Pages',
      subtitle: 'Meta Graph API v20.0',
      description: 'Publish feed videos, reels, photos and sync comments & analytics.',
      icon: Icons.facebook_rounded,
      brandColor: AppColors.facebook,
      isOAuth: true,
    ),
    _PlatformInfo(
      key: 'instagram',
      title: 'Instagram Professional',
      subtitle: 'Business & Creator Accounts',
      description: 'Schedule reels, carousels, single photos and sync performance metrics.',
      icon: Icons.camera_alt_rounded,
      brandColor: AppColors.instagram,
      isOAuth: true,
    ),
    _PlatformInfo(
      key: 'youtube',
      title: 'YouTube',
      subtitle: 'YouTube Shorts & Long-Form Video',
      description: 'Upload shorts, schedule premiere videos, optimize tags and monitor views.',
      icon: Icons.smart_display_rounded,
      brandColor: AppColors.youtube,
      isOAuth: true,
    ),
    _PlatformInfo(
      key: 'x',
      title: 'X (Formerly Twitter)',
      subtitle: 'Official API v2 Integration',
      description: 'Publish threads, polls, media tweets and monitor brand mentions.',
      icon: Icons.tag_rounded,
      brandColor: Colors.white,
      isOAuth: true,
    ),
    _PlatformInfo(
      key: 'whatsapp',
      title: 'WhatsApp Business',
      subtitle: 'Meta Cloud API (Official)',
      description: 'Template approvals, 1-to-many broadcasts and verified notification channels.',
      icon: LucideIcons.phoneCall,
      brandColor: AppColors.whatsapp,
      isOAuth: false,
    ),
    _PlatformInfo(
      key: 'telegram',
      title: 'Telegram',
      subtitle: 'Official Bot API',
      description: 'Instant broadcast alerts to public/private channels and supergroups.',
      icon: LucideIcons.send,
      brandColor: AppColors.telegram,
      isOAuth: false,
    ),
  ];

  void _handleConnect(_PlatformInfo item) {
    if (item.key == 'telegram') {
      _showTelegramDialog();
    } else if (item.key == 'whatsapp') {
      _showWhatsAppDialog();
    } else {
      _initiateOAuthFlow(item);
    }
  }

  void _initiateOAuthFlow(_PlatformInfo item) async {
    AppToast.show(context, 'Generating secure OAuth2 handshake for ${item.title}...');
    final result = await ref.read(socialAccountsProvider.notifier).getAuthUrl(item.key);

    if (!mounted) return;

    if (result != null && result['authorization_url'] != null) {
      final authUrl = result['authorization_url'] as String;
      final scopes = (result['scopes_requested'] as List<dynamic>?)?.join(', ') ?? '';

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: Row(
            children: [
              PlatformBrandIcon(platform: item.title, size: 28),
              const SizedBox(width: 12),
              Text('Connect ${item.title}', style: AppTypography.cardHeading),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: AppRadius.smBorder,
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Official OAuth 2.0 PKCE flow. Your credentials are never shared with our servers.',
                          style: AppTypography.supporting.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (scopes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Requested Scopes:', style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(scopes, style: AppTypography.supporting.copyWith(fontFamily: 'monospace')),
                ],
                const SizedBox(height: 16),
                Text('Authorization URL:', style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.smBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    authUrl,
                    style: AppTypography.supporting.copyWith(fontSize: 11, fontFamily: 'monospace'),
                    maxLines: 4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SecondaryButton(
              text: 'Copy URL',
              icon: LucideIcons.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: authUrl));
                if (!mounted) return;
                AppToast.show(context, 'OAuth URL copied to clipboard!', isSuccess: true);
              },
            ),
            PrimaryButton(
              text: 'Done / Refresh Accounts',
              icon: LucideIcons.check,
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                if (!mounted) return;
                ref.read(socialAccountsProvider.notifier).loadAccounts();
                context.go('/social-accounts');
              },
            ),
          ],
        ),
      );
    } else {
      AppToast.show(
        context,
        'Platform ${item.title} requires configured client credentials in backend .env',
        isError: true,
      );
    }
  }

  void _showTelegramDialog() {
    final tokenController = TextEditingController();
    final chatController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        title: Row(
          children: [
            PlatformBrandIcon(platform: 'Telegram', size: 28),
            const SizedBox(width: 12),
            Text('Connect Telegram Bot', style: AppTypography.cardHeading),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '1. Open @BotFather on Telegram and create a bot.\n2. Paste your HTTP API bot token below.\n3. Add the bot as Administrator to your Channel/Group.',
                  style: AppTypography.supporting.copyWith(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Bot Token (Required)',
                  hintText: '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chatController,
                decoration: const InputDecoration(
                  labelText: 'Channel / Chat ID (Optional)',
                  hintText: '@my_channel or -100123456789',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Connect Bot',
            icon: LucideIcons.send,
            onPressed: () async {
              final token = tokenController.text.trim();
              if (token.isEmpty) {
                AppToast.show(context, 'Bot token is required', isError: true);
                return;
              }
              Navigator.of(dialogCtx).pop();
              final ok = await ref.read(socialAccountsProvider.notifier).connectTelegram(
                botToken: token,
                chatId: chatController.text.trim().isNotEmpty ? chatController.text.trim() : null,
              );
              if (!mounted) return;
              if (ok) {
                AppToast.show(context, 'Telegram Bot connected successfully!', isSuccess: true);
                context.go('/social-accounts');
              } else {
                AppToast.show(context, 'Telegram connection failed. Check bot token.', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showWhatsAppDialog() {
    final phoneIdController = TextEditingController();
    final wabaIdController = TextEditingController();
    final tokenController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        title: Row(
          children: [
            PlatformBrandIcon(platform: 'WhatsApp', size: 28),
            const SizedBox(width: 12),
            Text('Connect WhatsApp Cloud API', style: AppTypography.cardHeading),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  'Note: Meta Cloud API supports official business messaging & approved template broadcasts. Channels, Groups, & Communities are unavailable via API.',
                  style: AppTypography.supporting.copyWith(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneIdController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number ID',
                  hintText: 'e.g. 104829104928102',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wabaIdController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Business Account (WABA) ID',
                  hintText: 'e.g. 948201948201923',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Meta Cloud API Access Token',
                  hintText: 'System User Permanent Access Token',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Onboard WhatsApp',
            icon: LucideIcons.phoneCall,
            onPressed: () async {
              final phoneId = phoneIdController.text.trim();
              final wabaId = wabaIdController.text.trim();
              final token = tokenController.text.trim();
              if (phoneId.isEmpty || wabaId.isEmpty || token.isEmpty) {
                AppToast.show(context, 'All fields are required', isError: true);
                return;
              }
              Navigator.of(dialogCtx).pop();
              final ok = await ref.read(socialAccountsProvider.notifier).onboardWhatsApp(
                phoneNumberId: phoneId,
                wabaId: wabaId,
                accessToken: token,
              );
              if (!mounted) return;
              if (ok) {
                AppToast.show(context, 'WhatsApp Business connected successfully!', isSuccess: true);
                context.go('/social-accounts');
              } else {
                AppToast.show(context, 'WhatsApp onboarding failed.', isError: true);
              }
            },
          ),
        ],
      ),
    );
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
              title: 'Connect New Platform',
              subtitle: 'Select from our 7 officially supported enterprise social integrations.',
              breadcrumbs: const ['Workspace', 'Social Accounts', 'Connect Platform'],
              action: SecondaryButton(
                text: 'Back to Accounts',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/social-accounts'),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _platforms.length,
                  itemBuilder: (context, index) {
                    final item = _platforms[index];
                    return _buildPlatformCard(item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(_PlatformInfo item) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PlatformBrandIcon(platform: item.title, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTypography.cardHeading),
                    Text(
                      item.subtitle,
                      style: AppTypography.chip.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.supporting,
          ),

          PrimaryButton(
            text: 'Connect ${item.title}',
            isFullWidth: true,
            icon: LucideIcons.link2,
            height: 38,
            onPressed: () => _handleConnect(item),
          ),
        ],
      ),
    );
  }
}

class _PlatformInfo {
  final String key;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color brandColor;
  final bool isOAuth;

  _PlatformInfo({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.brandColor,
    required this.isOAuth,
  });
}
