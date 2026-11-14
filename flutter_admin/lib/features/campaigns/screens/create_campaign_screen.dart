import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController(text: '5000');
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  void _saveCampaign() async {
    if (_nameController.text.isEmpty) {
      AppToast.show(context, 'Please enter a campaign name', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    AppToast.show(context, 'Campaign "${_nameController.text}" created! (Demo)', isSuccess: true);
    context.go('/campaigns');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
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
              title: 'Create New Campaign',
              subtitle: 'Set strategy objectives, allocate budget, and link omni-channel publishing schedules.',
              breadcrumbs: const ['Workspace', 'Campaigns', 'Create'],
              action: SecondaryButton(
                text: 'Cancel',
                onPressed: () => context.go('/campaigns'),
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
                      label: 'Campaign Title',
                      hintText: 'e.g. Q3 Global Product Launch',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'Campaign Objective & Narrative',
                      hintText: 'Briefly describe target audience, CTA, and desired outcome...',
                      controller: _descController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date', style: AppTypography.supporting),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(LucideIcons.calendar, size: 14),
                                label: Text('${_startDate.month}/${_startDate.day}/${_startDate.year}'),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) setState(() => _startDate = d);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Date', style: AppTypography.supporting),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(LucideIcons.calendar, size: 14),
                                label: Text('${_endDate.month}/${_endDate.day}/${_endDate.year}'),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) setState(() => _endDate = d);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'Budget (\$ USD)',
                      hintText: '5000',
                      controller: _budgetController,
                      prefixIcon: const Icon(LucideIcons.dollarSign, size: 16),
                    ),
                    const SizedBox(height: 28),

                    PrimaryButton(
                      text: 'Create Campaign & Open Workspace',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _saveCampaign,
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
