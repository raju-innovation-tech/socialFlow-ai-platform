import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class WorkspaceManagementScreen extends StatelessWidget {
  const WorkspaceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaces = [
      {'name': 'Cyber Magic Studio', 'owner': 'admin@cybermagic.studio', 'members': '5 members', 'tier': 'Pro (\$149/mo)', 'channels': '7 channels'},
      {'name': 'Acme Global Marketing', 'owner': 'cmo@acmeglobal.com', 'members': '18 members', 'tier': 'Enterprise (\$499/mo)', 'channels': '14 channels'},
      {'name': 'HyperGrowth Labs', 'owner': 'founder@hypergrowth.ai', 'members': '3 members', 'tier': 'Starter (\$49/mo)', 'channels': '3 channels'},
      {'name': 'Nova Media Group', 'owner': 'editorial@novamedia.org', 'members': '12 members', 'tier': 'Enterprise (\$499/mo)', 'channels': '10 channels'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Super Admin: Multi-Tenant Workspaces',
              subtitle: 'Monitor 3,842 active tenant workspaces, seat allocations, and storage limits.',
              breadcrumbs: const ['Super Admin', 'Workspaces'],
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
                        DataColumn(label: Text('Workspace')),
                        DataColumn(label: Text('Primary Owner')),
                        DataColumn(label: Text('Team Seats')),
                        DataColumn(label: Text('Subscription Tier')),
                        DataColumn(label: Text('Connected Channels')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: workspaces.map((w) {
                        return DataRow(
                          cells: [
                            DataCell(Text(w['name']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(w['owner']!)),
                            DataCell(Text(w['members']!)),
                            DataCell(Text(w['tier']!)),
                            DataCell(Text(w['channels']!)),
                            const DataCell(StatusBadge(label: 'Healthy', color: AppColors.success)),
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
