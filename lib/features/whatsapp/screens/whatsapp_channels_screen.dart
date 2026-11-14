import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class WhatsAppChannelsScreen extends StatelessWidget {
  const WhatsAppChannelsScreen({super.key});

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
              title: 'WhatsApp Channels Planner',
              subtitle: 'Plan updates, preview drafts, and copy formatted broadcasts for 1-way follower channels.',
              breadcrumbs: const ['Channels', 'WhatsApp', 'Channels'],
              action: PrimaryButton(
                text: 'New Channel Post',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/publishing/create'),
              ),
            ),

            // Official API Limitation Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API Policy Notice: WhatsApp Channels Automation', style: AppTypography.cardHeading.copyWith(color: AppColors.warning)),
                        const SizedBox(height: 2),
                        Text(
                          'Meta does not yet offer official public write APIs for WhatsApp Channels. Content planned here can be 1-click copied or dispatched via companion notification to maintain 100% Meta compliance.',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'Manual / Assisted Workflow', color: AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Planned Channels List
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
                  Text('Tracked Channels', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  _buildChannelItem(
                    name: 'Cyber Magic Announcements',
                    followers: '8,420 followers',
                    latestUpdate: '🚀 Q3 Roadmap is live! Read more...',
                    status: 'Ready to Copy',
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  _buildChannelItem(
                    name: 'Design Inspiration Daily',
                    followers: '19,200 followers',
                    latestUpdate: '✨ 5 spatial UI trends defining 2025.',
                    status: 'Scheduled Reminder',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelItem({
    required String name,
    required String followers,
    required String latestUpdate,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.whatsapp.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.radio, color: AppColors.whatsapp, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
              Text('$followers • $latestUpdate', style: AppTypography.supporting),
            ],
          ),
        ),
        StatusBadge(label: status),
        const SizedBox(width: 10),
        OutlinedActionButton(
          text: 'Copy & Send',
          icon: LucideIcons.copy,
          onPressed: () {},
        ),
      ],
    );
  }
}
