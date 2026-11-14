import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class AppDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              headingTextStyle: AppTypography.cardHeading.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: AppTypography.body.copyWith(fontSize: 13),
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: columns,
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}

