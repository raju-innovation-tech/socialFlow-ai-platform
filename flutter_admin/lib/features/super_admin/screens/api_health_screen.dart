import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class ApiHealthScreen extends StatelessWidget {
  const ApiHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apis = [
      {'name': 'Meta Graph API (Facebook / Instagram)', 'status': 'Operational', 'latency': '142ms', 'quota': '32% consumed', 'errorRate': '0.01%'},
      {'name': 'LinkedIn Enterprise v2 API', 'status': 'Operational', 'latency': '185ms', 'quota': '45% consumed', 'errorRate': '0.00%'},
      {'name': 'X Developer API v2', 'status': 'Operational', 'latency': '210ms', 'quota': '58% consumed', 'errorRate': '0.04%'},
      {'name': 'YouTube Data API v3', 'status': 'Operational', 'latency': '120ms', 'quota': '18% consumed', 'errorRate': '0.00%'},
      {'name': 'WhatsApp Meta Cloud API', 'status': 'Operational', 'latency': '95ms', 'quota': '24% consumed', 'errorRate': '0.00%'},
      {'name': 'Telegram Bot API Core', 'status': 'Operational', 'latency': '78ms', 'quota': '12% consumed', 'errorRate': '0.00%'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Global Platform API Health & Rate Limits',
              subtitle: 'Live latency telemetry, rate limit windows, and platform partner status.',
              breadcrumbs: const ['Super Admin', 'API Health'],
              action: SecondaryButton(
                text: 'Admin Dashboard',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/super-admin/dashboard'),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.cardBorder,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 850),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.secondaryBackground),
                      headingTextStyle: AppTypography.cardHeading.copyWith(fontSize: 13),
                      dataTextStyle: AppTypography.body.copyWith(fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Partner Platform')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('P95 Latency')),
                        DataColumn(label: Text('Rate Limit Quota')),
                        DataColumn(label: Text('Error Rate')),
                      ],
                      rows: apis.map((a) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  PlatformBrandIcon(platform: a['name']!, size: 22),
                                  const SizedBox(width: 10),
                                  Text(a['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(StatusBadge(label: a['status']!, color: AppColors.success)),
                            DataCell(Text(a['latency']!)),
                            DataCell(Text(a['quota']!)),
                            DataCell(Text(a['errorRate']!)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
