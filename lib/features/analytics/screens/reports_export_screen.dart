import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class ReportsExportScreen extends StatefulWidget {
  const ReportsExportScreen({super.key});

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  String _selectedTemplate = 'Executive Monthly Summary';
  String _selectedFormat = 'PDF Presentation';
  bool _isGenerating = false;

  void _exportReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isGenerating = false);
    AppToast.show(context, '$_selectedTemplate ($_selectedFormat) downloaded! (Demo)', isSuccess: true);
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
              title: 'Automated Reports & Client Exports',
              subtitle: 'Generate branded PDF slide decks or CSV raw spreadsheets for stakeholders.',
              breadcrumbs: const ['Workspace', 'Analytics', 'Reports & Export'],
              action: SecondaryButton(
                text: 'Analytics Overview',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/analytics/overview'),
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
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
                    Text('Configure Export Parameters', style: AppTypography.cardHeading),
                    const SizedBox(height: 18),

                    Text('Select Report Template', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTemplate,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.elevatedCard,
                        style: AppTypography.body,
                        items: [
                          'Executive Monthly Summary',
                          'Omni-Channel Conversion Attribution',
                          'Campaign ROI & Budget Audit',
                          'Audience Demographics & Growth Report',
                        ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTemplate = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Export File Format', style: AppTypography.supporting),
                    const SizedBox(height: 6),
                    Row(
                      children: ['PDF Presentation', 'CSV Raw Spreadsheet'].map((format) {
                        final isSel = _selectedFormat == format;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(format),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.secondaryBackground,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary),
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedFormat = format);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    PrimaryButton(
                      text: 'Generate & Download Report',
                      icon: LucideIcons.download,
                      isFullWidth: true,
                      isLoading: _isGenerating,
                      onPressed: _exportReport,
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
