import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class TelegramChannelsScreen extends StatelessWidget {
  const TelegramChannelsScreen({super.key});

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
              title: 'Telegram Channels Management',
              subtitle: 'Automated broadcasting via official Telegram Bot API with instant push to subscribers.',
              breadcrumbs: const ['Channels', 'Telegram', 'Channels'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Bot Config',
                    icon: LucideIcons.bot,
                    onPressed: () => context.go('/telegram/connect-bot'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Broadcast to Channel',
                    icon: LucideIcons.send,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Connected Telegram Channels', style: AppTypography.cardHeading),
                      const StatusBadge(label: 'Bot Status: Online', color: AppColors.telegram),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChannelCard(
                    context,
                    name: 'Cyber Magic VIP Channel',
                    handle: '@cybermagic_vip',
                    subscribers: '14,800 subscribers',
                    botRole: 'Administrator (Can Post Messages, Edit, Pin)',
                    recentPost: 'Early Access alert posted 2 hours ago (4.2K views)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(
    BuildContext context, {
    required String name,
    required String handle,
    required String subscribers,
    required String botRole,
    required String recentPost,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: AppRadius.mdBorder,
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.send, color: AppColors.telegram, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                    Text('$handle • $subscribers', style: AppTypography.supporting),
                  ],
                ),
              ),
              OutlinedActionButton(
                text: 'Send Test Alert',
                icon: LucideIcons.send,
                onPressed: () => AppToast.show(context, 'Test ping dispatched to Telegram (Demo)', isSuccess: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Bot Privileges: $botRole', style: AppTypography.chip.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text('Latest Broadcast: $recentPost', style: AppTypography.supporting),
        ],
      ),
    );
  }
}
