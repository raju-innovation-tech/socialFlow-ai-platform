import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class WhatsAppGroupsScreen extends StatelessWidget {
  const WhatsAppGroupsScreen({super.key});

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
              title: 'WhatsApp Groups Planner',
              subtitle: 'Coordinate group announcements with scheduled notifications and companion reminders.',
              breadcrumbs: const ['Channels', 'WhatsApp', 'Groups'],
              action: PrimaryButton(
                text: 'Draft Group Announcement',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/publishing/create'),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.warning, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Compliance Notice: WhatsApp Private Groups', style: AppTypography.cardHeading.copyWith(color: AppColors.warning)),
                        const SizedBox(height: 2),
                        Text(
                          'Personal group automation without user interaction violates WhatsApp Terms of Service. SocialFlow AI uses assisted push notifications so managers dispatch group messages in compliance.',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'Assisted Push Flow', color: AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                  Text('Registered Internal & Partner Groups', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  _buildGroupRow(
                    name: 'VIP Client Beta Testers',
                    members: '124 members',
                    scheduledPost: 'Weekly update teaser scheduled for Friday 4 PM',
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  _buildGroupRow(
                    name: 'Core Studio Contributors',
                    members: '48 members',
                    scheduledPost: 'Standup reminder dispatched today at 9:30 AM',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupRow({required String name, required String members, required String scheduledPost}) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.users, color: AppColors.whatsapp, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
              Text('$members • $scheduledPost', style: AppTypography.supporting),
            ],
          ),
        ),
        OutlinedActionButton(
          text: 'Open Draft',
          icon: LucideIcons.externalLink,
          onPressed: () {},
        ),
      ],
    );
  }
}
