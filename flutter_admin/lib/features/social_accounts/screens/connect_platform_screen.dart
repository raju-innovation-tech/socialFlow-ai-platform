import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class ConnectPlatformScreen extends StatelessWidget {
  const ConnectPlatformScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _PlatformInfo(
        title: 'LinkedIn',
        subtitle: 'Company Pages & Personal Profiles',
        description: 'Auto-publish carousels, text, images, and track corporate engagement.',
        icon: Icons.business_center_rounded,
        brandColor: AppColors.linkedin,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'Facebook Pages',
        subtitle: 'Meta Graph API v20.0',
        description: 'Publish feed videos, reels, photos and sync comments & analytics.',
        icon: Icons.facebook_rounded,
        brandColor: AppColors.facebook,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'Instagram Professional',
        subtitle: 'Business & Creator Accounts',
        description: 'Schedule reels, carousels, single photos and sync performance metrics.',
        icon: Icons.camera_alt_rounded,
        brandColor: AppColors.instagram,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'YouTube',
        subtitle: 'YouTube Shorts & Long-Form Video',
        description: 'Upload shorts, schedule premiere videos, optimize tags and monitor views.',
        icon: Icons.smart_display_rounded,
        brandColor: AppColors.youtube,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'X (Formerly Twitter)',
        subtitle: 'Official API v2 Integration',
        description: 'Publish threads, polls, media tweets and monitor brand mentions.',
        icon: Icons.tag_rounded,
        brandColor: Colors.white,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'WhatsApp Business',
        subtitle: 'Meta Cloud API (Official)',
        description: 'Template approvals, 1-to-many broadcasts and verified notification channels.',
        icon: LucideIcons.phoneCall,
        brandColor: AppColors.whatsapp,
        isSupported: true,
      ),
      _PlatformInfo(
        title: 'Telegram',
        subtitle: 'Official Bot API',
        description: 'Instant broadcast alerts to public/private channels and supergroups.',
        icon: LucideIcons.send,
        brandColor: AppColors.telegram,
        isSupported: true,
      ),
    ];

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
                  itemCount: platforms.length,
                  itemBuilder: (context, index) {
                    final item = platforms[index];
                    return _buildPlatformCard(context, item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(BuildContext context, _PlatformInfo item) {
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
            onPressed: () {
              AppToast.show(
                context,
                'Initiated OAuth2 authentication handshake with ${item.title} (Demo)',
                isSuccess: true,
              );
              context.go('/social-accounts');
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformInfo {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color brandColor;
  final bool isSupported;

  _PlatformInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.brandColor,
    required this.isSupported,
  });
}
