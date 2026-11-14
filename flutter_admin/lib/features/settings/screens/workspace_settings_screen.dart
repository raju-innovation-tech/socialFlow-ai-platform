import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class WorkspaceSettingsScreen extends StatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  State<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends State<WorkspaceSettingsScreen> {
  final _wsNameController = TextEditingController(text: 'Cyber Magic Studio');
  String _timezone = 'UTC - 05:00 (Eastern Time)';
  String _defaultApproval = 'Required for all team members except Admins';

  @override
  void dispose() {
    _wsNameController.dispose();
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
              title: 'Workspace Configuration',
              subtitle: 'Global workspace branding, default timezone, and publishing constraints.',
              breadcrumbs: const ['Settings', 'Workspace'],
              action: PrimaryButton(
                text: 'Save Workspace Settings',
                icon: LucideIcons.check,
                onPressed: () => AppToast.show(context, 'Workspace settings updated! (Demo)', isSuccess: true),
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
                      label: 'Workspace Name',
                      controller: _wsNameController,
                    ),
                    const SizedBox(height: 20),

                    Text('Default Workspace Timezone', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: _timezone,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.elevatedCard,
                        style: AppTypography.body,
                        items: [
                          'UTC - 05:00 (Eastern Time)',
                          'UTC - 08:00 (Pacific Time)',
                          'UTC + 00:00 (GMT/London)',
                          'UTC + 05:30 (India Standard Time)',
                          'UTC + 08:00 (Singapore / HK)',
                        ].map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _timezone = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Approval Policy Enforcement', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: _defaultApproval,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.elevatedCard,
                        style: AppTypography.body,
                        items: [
                          'Required for all team members except Admins',
                          'Strict: Required for everyone including Admins',
                          'Relaxed: Direct publishing allowed for Editors',
                        ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _defaultApproval = val);
                        },
                      ),
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
}
