import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/team_member.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _emailController = TextEditingController();
  WorkspaceRole _selectedRole = WorkspaceRole.editor;
  bool _isLoading = false;

  void _sendInvitation() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      AppToast.show(context, 'Please enter a valid work email', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    AppToast.show(context, 'Invitation link emailed to ${_emailController.text}! (Demo)', isSuccess: true);
    context.go('/team');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
              title: 'Invite Team Member',
              subtitle: 'Send secure workspace invites and define granular permission boundaries.',
              breadcrumbs: const ['Workspace', 'Team Members', 'Invite'],
              action: SecondaryButton(
                text: 'Back to Team',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/team'),
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Colleague Email Address',
                      hintText: 'name@company.com',
                      controller: _emailController,
                      prefixIcon: const Icon(LucideIcons.mail, size: 16),
                    ),
                    const SizedBox(height: 24),

                    Text('Select Workspace Role', style: AppTypography.cardHeading),
                    const SizedBox(height: 12),

                    ...WorkspaceRole.values.map((role) {
                      final isSelected = _selectedRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = role),
                          borderRadius: AppRadius.mdBorder,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.secondaryBackground,
                              borderRadius: AppRadius.mdBorder,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_getRoleTitle(role), style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                      Text(_getRoleDescription(role), style: AppTypography.supporting),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Send Workspace Invitation',
                      icon: LucideIcons.send,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _sendInvitation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleTitle(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner:
        return 'Owner (Full platform & billing authority)';
      case WorkspaceRole.admin:
        return 'Admin (Can manage accounts, members, and settings)';
      case WorkspaceRole.editor:
        return 'Editor (Can create, edit, and draft posts)';
      case WorkspaceRole.approver:
        return 'Approver (Can review, reject, and publish posts)';
      case WorkspaceRole.analyst:
        return 'Analyst (Read-only access to analytics & reports)';
      case WorkspaceRole.viewer:
        return 'Viewer (Read-only preview access to calendar)';
    }
  }

  String _getRoleDescription(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner:
        return 'Total control including subscription, workspace deletion, and API tokens.';
      case WorkspaceRole.admin:
        return 'Can invite members, connect social channels, and override schedules.';
      case WorkspaceRole.editor:
        return 'Can draft multi-format content and request editorial approvals.';
      case WorkspaceRole.approver:
        return 'Empowered to sign off on content and authorize direct platform publishing.';
      case WorkspaceRole.analyst:
        return 'Can export CSV/PDF reports and view engagement dashboards.';
      case WorkspaceRole.viewer:
        return 'Basic read-only access for external clients or stakeholders.';
    }
  }
}
