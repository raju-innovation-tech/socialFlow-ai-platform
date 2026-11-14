import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/cards.dart';

class CampaignOverviewScreen extends StatelessWidget {
  const CampaignOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final campaigns = MockData.campaigns;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Multi-Channel Campaigns',
              subtitle: 'Group related posts, track shared budgets, and measure aggregated conversion impact.',
              breadcrumbs: const ['Workspace', 'Campaigns'],
              action: PrimaryButton(
                text: 'Create Campaign',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/campaigns/create'),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final c = campaigns[index];
                    return InkWell(
                      onTap: () => context.go('/campaigns/details/${c.id}'),
                      borderRadius: AppRadius.cardBorder,
                      child: CampaignCard(campaign: c),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
