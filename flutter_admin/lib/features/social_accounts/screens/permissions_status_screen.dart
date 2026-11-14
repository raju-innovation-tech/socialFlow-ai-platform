import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../app/providers/social_accounts_provider.dart';

class PermissionsStatusScreen extends ConsumerWidget {
  const PermissionsStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialAccountsProvider);
    final accounts = state.accounts.isNotEmpty ? state.accounts : MockData.connectedAccounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Permissions & API Health Matrix',
              subtitle: 'Audit token scopes, capabilities, and platform compliance status.',
              breadcrumbs: const ['Workspace', 'Social Accounts', 'Permissions Matrix'],
              action: SecondaryButton(
                text: 'Back to Accounts',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/social-accounts'),
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
                      headingRowColor: WidgetStateProperty.all(AppColors.secondaryBackground),
                      headingTextStyle: AppTypography.cardHeading.copyWith(fontSize: 13),
                      dataTextStyle: AppTypography.body.copyWith(fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Platform / Account')),
                        DataColumn(label: Text('Official API Tier')),
                        DataColumn(label: Text('Token Status')),
                        DataColumn(label: Text('Permissions Scopes')),
                        DataColumn(label: Text('Auto-Publishing')),
                        DataColumn(label: Text('Audit Status')),
                      ],
                      rows: accounts.map((acc) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  PlatformBrandIcon(platform: acc.platformName, size: 24),
                                  const SizedBox(width: 10),
                                  Text(acc.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const DataCell(Text('Official API Tier')),
                            const DataCell(StatusBadge(label: 'Healthy / Active')),
                            DataCell(Text('${acc.permissions.length} granted scopes')),
                            const DataCell(
                              Row(
                                children: [
                                  Icon(LucideIcons.check, size: 16, color: AppColors.success),
                                  SizedBox(width: 6),
                                  Text('Enabled'),
                                ],
                              ),
                            ),
                            const DataCell(Text('Verified Compliant')),
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
