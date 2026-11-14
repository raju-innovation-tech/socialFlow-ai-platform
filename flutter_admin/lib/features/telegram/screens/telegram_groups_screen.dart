import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class TelegramGroupsScreen extends StatelessWidget {
  const TelegramGroupsScreen({super.key});

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
              title: 'Telegram Supergroups & Chats',
              subtitle: 'Broadcast alerts, schedule discussion topics, and configure bot moderation permissions.',
              breadcrumbs: const ['Channels', 'Telegram', 'Groups'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Bot Connection',
                    icon: LucideIcons.bot,
                    onPressed: () => context.go('/telegram/connect-bot'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Post to Group',
                    icon: LucideIcons.messageSquare,
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
                  Text('Authorized Telegram Supergroups', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  _buildGroupRow(
                    context,
                    name: 'SocialFlow Builders & Insiders',
                    members: '1,840 members',
                    permissions: 'Can Post, Pin, and Delete Messages',
                    lastActive: 'Active 12m ago',
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  _buildGroupRow(
                    context,
                    name: 'Growth Hackers Round Table',
                    members: '620 members',
                    permissions: 'Can Post Messages',
                    lastActive: 'Active 1h ago',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupRow(
    BuildContext context, {
    required String name,
    required String members,
    required String permissions,
    required String lastActive,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.telegram.withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.users, color: AppColors.telegram, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
              Text('$members • $permissions • $lastActive', style: AppTypography.supporting),
            ],
          ),
        ),
        const StatusBadge(label: 'Bot Authorized', color: AppColors.success),
        const SizedBox(width: 10),
        OutlinedActionButton(
          text: 'Schedule Message',
          icon: LucideIcons.clock,
          onPressed: () => context.go('/publishing/create'),
        ),
      ],
    );
  }
}
