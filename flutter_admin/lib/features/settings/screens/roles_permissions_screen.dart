import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';

class RolesPermissionsScreen extends StatelessWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = [
      {'name': 'Connect & Disconnect Social Accounts', 'owner': true, 'admin': true, 'editor': false, 'approver': false, 'analyst': false},
      {'name': 'Publish Posts Directly to Channels', 'owner': true, 'admin': true, 'editor': false, 'approver': true, 'analyst': false},
      {'name': 'Create & Edit Draft Posts', 'owner': true, 'admin': true, 'editor': true, 'approver': true, 'analyst': false},
      {'name': 'Approve or Reject Editorial Posts', 'owner': true, 'admin': true, 'editor': false, 'approver': true, 'analyst': false},
      {'name': 'View Analytics & Export CSV/PDF Reports', 'owner': true, 'admin': true, 'editor': true, 'approver': true, 'analyst': true},
      {'name': 'Manage Workspace Members & Roles', 'owner': true, 'admin': true, 'editor': false, 'approver': false, 'analyst': false},
      {'name': 'Update Billing, Tier & Payment Methods', 'owner': true, 'admin': false, 'editor': false, 'approver': false, 'analyst': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Role-Based Access Control (RBAC) Matrix',
              subtitle: 'Fine-grained enterprise capability matrix across all workspace roles.',
              breadcrumbs: const ['Settings', 'Roles & Permissions'],
              action: PrimaryButton(
                text: 'Invite Member',
                icon: LucideIcons.userPlus,
                onPressed: () => context.go('/team/invite'),
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
                        DataColumn(label: Text('Capability / Scope')),
                        DataColumn(label: Text('Owner')),
                        DataColumn(label: Text('Admin')),
                        DataColumn(label: Text('Editor')),
                        DataColumn(label: Text('Approver')),
                        DataColumn(label: Text('Analyst')),
                      ],
                      rows: permissions.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(_buildCheck(p['owner'] as bool)),
                            DataCell(_buildCheck(p['admin'] as bool)),
                            DataCell(_buildCheck(p['editor'] as bool)),
                            DataCell(_buildCheck(p['approver'] as bool)),
                            DataCell(_buildCheck(p['analyst'] as bool)),
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

  Widget _buildCheck(bool enabled) {
    if (enabled) {
      return const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 18);
    }
    return const Icon(LucideIcons.minus, color: AppColors.textMuted, size: 16);
  }
}
