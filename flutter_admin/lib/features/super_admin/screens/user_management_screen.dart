import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _search = '';
  final List<Map<String, String>> _users = [
    {'name': 'Alex Morgan', 'email': 'alex@cybermagic.studio', 'workspace': 'Cyber Magic Studio', 'tier': 'Enterprise', 'status': 'Active'},
    {'name': 'Sarah Jenkins', 'email': 'sarah@acmedesign.co', 'workspace': 'Acme Global', 'tier': 'Pro Growth', 'status': 'Active'},
    {'name': 'Marcus Vance', 'email': 'marcus@growthpilot.io', 'workspace': 'GrowthPilot HQ', 'tier': 'Starter', 'status': 'Active'},
    {'name': 'Elena Rostova', 'email': 'elena@novamedia.org', 'workspace': 'Nova Media Group', 'tier': 'Enterprise', 'status': 'Active'},
    {'name': 'Liam Gallagher', 'email': 'liam@spencermarketing.com', 'workspace': 'Spencer Marketing', 'tier': 'Suspended', 'status': 'Suspended'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      if (_search.isEmpty) return true;
      return u['name']!.toLowerCase().contains(_search.toLowerCase()) ||
          u['email']!.toLowerCase().contains(_search.toLowerCase()) ||
          u['workspace']!.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Super Admin: Platform User Management',
              subtitle: 'Monitor all registered accounts, tenant assignments, and authentication status.',
              breadcrumbs: const ['Super Admin', 'User Management'],
              action: SecondaryButton(
                text: 'Admin Dashboard',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/super-admin/dashboard'),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SearchField(
                    hintText: 'Search 18,420 users by name, email, or domain...',
                    width: 320,
                    onChanged: (val) => setState(() => _search = val),
                  ),
                  const Spacer(),
                  const StatusBadge(label: 'Total Users: 18,420', color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Primary Workspace')),
                        DataColumn(label: Text('Plan Tier')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredUsers.map((u) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(u['email']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            DataCell(Text(u['workspace']!)),
                            DataCell(Text(u['tier']!)),
                            DataCell(
                              StatusBadge(
                                label: u['status']!,
                                color: u['status'] == 'Active' ? AppColors.success : AppColors.danger,
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.shieldAlert, size: 16),
                                    tooltip: 'Impersonate / Audit User',
                                    onPressed: () => AppToast.show(context, 'Audit session initiated (Demo)', isSuccess: true),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.ban, size: 16, color: AppColors.danger),
                                    tooltip: 'Suspend Account',
                                    onPressed: () => AppToast.show(context, 'Account suspended (Demo)', isError: true),
                                  ),
                                ],
                              ),
                            ),
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
