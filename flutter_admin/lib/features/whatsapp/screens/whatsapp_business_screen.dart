import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class WhatsAppBusinessScreen extends StatefulWidget {
  const WhatsAppBusinessScreen({super.key});

  @override
  State<WhatsAppBusinessScreen> createState() => _WhatsAppBusinessScreenState();
}

class _WhatsAppBusinessScreenState extends State<WhatsAppBusinessScreen> {
  final List<Map<String, String>> _templates = [
    {
      'name': 'weekly_digest_v1',
      'category': 'Marketing',
      'language': 'en_US',
      'status': 'Approved',
      'lastUpdated': 'May 12, 2025',
    },
    {
      'name': 'event_reminder_alert',
      'category': 'Utility',
      'language': 'en_US',
      'status': 'Approved',
      'lastUpdated': 'May 08, 2025',
    },
    {
      'name': 'order_status_update',
      'category': 'Transactional',
      'language': 'en_US',
      'status': 'Approved',
      'lastUpdated': 'Apr 24, 2025',
    },
  ];

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
              title: 'WhatsApp Business Platform (Official API)',
              subtitle: 'Enterprise Cloud API messaging, verified template approval, and broadcast automations.',
              breadcrumbs: const ['Channels', 'WhatsApp', 'Business Cloud API'],
              action: PrimaryButton(
                text: 'New Meta Template',
                icon: LucideIcons.plus,
                onPressed: () => AppToast.show(context, 'Template editor opened (Demo)', isSuccess: true),
              ),
            ),

            // Official Compliance Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whatsapp.withOpacity(0.1),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.whatsapp.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppColors.whatsapp, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Meta Cloud API Connection', style: AppTypography.cardHeading.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Direct official WhatsApp Business integration. Fully complies with Meta opt-in policies and 24h customer care window guidelines.',
                          style: AppTypography.supporting,
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'Verified WABA', color: AppColors.whatsapp),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Templates Table
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
                      Text('Approved WhatsApp Message Templates', style: AppTypography.cardHeading),
                      OutlinedActionButton(
                        text: 'Sync Templates from Meta',
                        icon: LucideIcons.refreshCw,
                        onPressed: () => AppToast.show(context, 'Synced 3 templates from Meta Cloud (Demo)', isSuccess: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 20),
                    itemBuilder: (context, index) {
                      final t = _templates[index];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.fileText, color: AppColors.whatsapp, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['name']!, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                Text('Category: ${t["category"]} • Language: ${t["language"]} • Updated: ${t["lastUpdated"]}', style: AppTypography.supporting),
                              ],
                            ),
                          ),
                          StatusBadge(label: t['status']!, color: AppColors.success),
                          const SizedBox(width: 12),
                          OutlinedActionButton(
                            text: 'Broadcast',
                            icon: LucideIcons.send,
                            onPressed: () => AppToast.show(context, 'Broadcast dispatch modal triggered (Demo)', isSuccess: true),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
