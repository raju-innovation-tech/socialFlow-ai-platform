import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/team_member.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  late List<TeamMember> _members;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _members = List.from(MockData.teamMembers);
  }

  void _removeMember(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Remove ${member.name}?',
        message: 'This will revoke all access to this workspace and delete pending approvals assigned to them.',
        confirmText: 'Remove',
        isDestructive: true,
        onConfirm: () {
          setState(() {
            _members.removeWhere((m) => m.id == member.id);
          });
          AppToast.show(context, '${member.name} removed from workspace (Demo)', isSuccess: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || m.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Team & Workspace Permissions',
              subtitle: 'Collaborate with editors, approvers, analysts, and workspace admins.',
              breadcrumbs: const ['Workspace', 'Team Members'],
              action: PrimaryButton(
                text: 'Invite Member',
                icon: LucideIcons.userPlus,
                onPressed: () => context.go('/team/invite'),
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
                    hintText: 'Search members by name or email...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                    width: 300,
                  ),
                  const Spacer(),
                  Text('${filtered.length} active members', style: AppTypography.supporting),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Members Table
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
                    constraints: const BoxConstraints(minWidth: 800),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.secondaryBackground),
                      headingTextStyle: AppTypography.cardHeading.copyWith(fontSize: 13),
                      dataTextStyle: AppTypography.body.copyWith(fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Member')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Joined Date')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filtered.map((m) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(m.avatarUrl),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(m.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                                      Text(m.email, style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                child: Text(m.roleName, style: AppTypography.chip.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(Text('${m.joinedAt.month}/${m.joinedAt.day}/${m.joinedAt.year}')),
                            const DataCell(
                              Row(
                                children: [
                                  Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                                  SizedBox(width: 6),
                                  Text('Active'),
                                ],
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                onPressed: m.role == WorkspaceRole.owner ? null : () => _removeMember(m),
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
