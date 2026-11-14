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

class PlatformEditorScreen extends StatefulWidget {
  const PlatformEditorScreen({super.key});

  @override
  State<PlatformEditorScreen> createState() => _PlatformEditorScreenState();
}

class _PlatformEditorScreenState extends State<PlatformEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {
    'LinkedIn': TextEditingController(
      text: '🚀 The future of B2B social automation: How data-driven scheduling enhances inbound pipelines while maintaining organic tone.\n\nKey takeaways from our quarterly review:\n1. Timing matters less than relevance\n2. First 2 lines drive click-throughs\n3. Engage in comments within 1 hour\n\nWhat is your go-to social strategy? Let us know below!\n\n#B2B #Marketing #Productivity',
    ),
    'Instagram': TextEditingController(
      text: 'Visual perfection meets automated workflows ✨ Swipe through to see our 5 design trends for 2025. Which one inspires your next brand launch? 💬\n.\n.\n#UIUX #DesignInspo #DesignTrends #CreativeStudio',
    ),
    'Facebook': TextEditingController(
      text: 'We are thrilled to share our latest product updates with the community! Check out what the team built this week and let us know your favorite new feature.',
    ),
    'X (Twitter)': TextEditingController(
      text: 'Automating multi-channel distribution without losing your soul (a mini guide 🧵):\n\n1/ Stop cross-posting raw links\n2/ Format for native readability\n3/ Schedule around global timezones\n\nFull breakdown coming tomorrow ⚡',
    ),
    'YouTube': TextEditingController(
      text: 'Title: How AI is Revolutionizing Social Media Management in 2025\n\nDescription: In this video, we explore how modern creative teams use SocialFlow AI to automate scheduling, asset generation, and community growth.',
    ),
    'Telegram': TextEditingController(
      text: '📢 VIP Community Alert: Early access is now open for our upcoming Q3 feature suite! Tap the link below to preview the demo.',
    ),
    'WhatsApp': TextEditingController(
      text: 'Template: weekly_digest_v1\nParameters: {{1}}=Alex, {{2}}=Friday Masterclass\n\nHi Alex! Your Friday masterclass is confirmed. Reply YES to receive materials.',
    ),
  };

  final List<String> _platforms = ['LinkedIn', 'Instagram', 'Facebook', 'X (Twitter)', 'YouTube', 'Telegram', 'WhatsApp'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _platforms.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
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
              title: 'Platform-Specific Content Editor',
              subtitle: 'Tailor copy, hashtags, media formats, and compliance specs for each individual platform.',
              breadcrumbs: const ['Publishing', 'Platform Editor'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Multi-Preview',
                    icon: LucideIcons.eye,
                    onPressed: () => context.go('/publishing/preview'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Save All Variations',
                    icon: LucideIcons.check,
                    onPressed: () {
                      AppToast.show(context, 'All 7 platform variants saved! (Demo)', isSuccess: true);
                      context.go('/publishing/queue');
                    },
                  ),
                ],
              ),
            ),

            // Tab bar for 7 platforms
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _platforms.map((p) {
                  return Tab(
                    child: Row(
                      children: [
                        PlatformBrandIcon(platform: p, size: 18),
                        const SizedBox(width: 8),
                        Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Editor body for current tab
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: _platforms.map((p) {
                  return _buildEditorPanel(p);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorPanel(String platform) {
    final controller = _controllers[platform]!;
    int limit = 3000;
    if (platform.contains('Twitter')) limit = 280;
    if (platform.contains('Instagram')) limit = 2200;
    if (platform.contains('Telegram')) limit = 4096;
    if (platform.contains('WhatsApp')) limit = 1024;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Customize copy for $platform', style: AppTypography.cardHeading),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, val, _) {
                  final isOver = val.text.length > limit;
                  return Text(
                    '${val.text.length} / $limit characters',
                    style: AppTypography.supporting.copyWith(
                      color: isOver ? AppColors.danger : AppColors.textSecondary,
                      fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: AppTypography.body,
              decoration: const InputDecoration(
                hintText: 'Enter platform copy...',
                fillColor: AppColors.secondaryBackground,
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedActionButton(
                text: 'Suggest Hashtags',
                icon: LucideIcons.hash,
                onPressed: () {
                  controller.text += ' #Trending #SocialMedia';
                },
              ),
              const SizedBox(width: 10),
              OutlinedActionButton(
                text: 'Add Call To Action',
                icon: LucideIcons.sparkles,
                onPressed: () {
                  controller.text += '\n👉 Link in bio / comments!';
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
