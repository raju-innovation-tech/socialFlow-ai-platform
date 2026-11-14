import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/dialogs.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPlatform = 'All Platforms';
  String _calendarView = 'Week';
  final TextEditingController _aiPromptController = TextEditingController();

  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Header
            _buildWelcomeHeader(context),
            const SizedBox(height: 20),

            // Top KPI Bento Row
            _buildKpiRow(),
            const SizedBox(height: 24),

            // Main Content Area (Calendar & Pipeline on left, Analytics & AI on right)
            if (isWideDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContentCalendarCard(context),
                        const SizedBox(height: 20),
                        _buildContentPipelineCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPerformanceChartCard(),
                        const SizedBox(height: 20),
                        _buildAiAssistantCard(),
                        const SizedBox(height: 20),
                        _buildApprovalQueueCard(context),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildContentCalendarCard(context),
                  const SizedBox(height: 20),
                  _buildContentPipelineCard(),
                  const SizedBox(height: 20),
                  _buildPerformanceChartCard(),
                  const SizedBox(height: 20),
                  _buildAiAssistantCard(),
                  const SizedBox(height: 20),
                  _buildApprovalQueueCard(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 1. Welcome Header
  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text('Good morning, Team', style: AppTypography.mainHeading, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your AI is ready to plan, create and publish content that grows your brand.',
                style: AppTypography.subHeading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. KPI Cards Row
  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 900
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth > 550 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard(
              width: cardWidth,
              title: 'Upcoming Posts',
              value: '24',
              trend: '↑ 20% vs last 7 days',
              icon: LucideIcons.calendar,
              accentColor: const Color(0xFF38BDF8),
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Engagement (This week)',
              value: '8.7K',
              trend: '↑ 32% vs last 7 days',
              icon: LucideIcons.trendingUp,
              accentColor: AppColors.primary,
              hasMiniSparkline: true,
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Content Created',
              value: '56',
              trend: '↑ 18% vs last 7 days',
              icon: LucideIcons.fileText,
              accentColor: AppColors.accentViolet,
            ),
            _buildKpiCard(
              width: cardWidth,
              title: 'Time Saved',
              value: '16.5h',
              trend: '↑ 42% vs last 7 days',
              icon: LucideIcons.clock,
              accentColor: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color accentColor,
    bool hasMiniSparkline = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTypography.kpiValue),
              if (hasMiniSparkline) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 5),
                              FlSpot(2, 4),
                              FlSpot(3, 7),
                              FlSpot(4, 6),
                              FlSpot(5, 9),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: AppTypography.supporting.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Content Calendar Card
  Widget _buildContentCalendarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Content Calendar', style: AppTypography.cardHeading.copyWith(fontSize: 18)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.chevronLeft, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('May 19 – May 25, 2025', style: AppTypography.supporting),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('Today', style: AppTypography.supporting),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedPlatform, style: AppTypography.supporting),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(_calendarView, style: AppTypography.supporting),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(LucideIcons.settings, size: 16, color: AppColors.textSecondary),
                      onPressed: () => context.go('/calendar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Days Columns (Mon 19, Tue 20, Wed 21, Thu 22, Fri 23, Sat 24, Sun 25)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendarDayColumn(
                  day: 'Mon 19',
                  isToday: false,
                  posts: [
                    _CalendarItemData(
                      platform: 'instagram',
                      time: '10:00 AM',
                      title: '5 Design Trends to Watch in 2025',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'linkedin',
                      time: '01:30 PM',
                      title: 'Why Brand Strategy Drives Growth',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=200',
                    ),
                  ],
                ),
                _buildCalendarDayColumn(
                  day: 'Tue 20',
                  isToday: false,
                  posts: [
                    _CalendarItemData(
                      platform: 'facebook',
                      time: '11:00 AM',
                      title: 'Behind the Scenes Creative Process',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'instagram',
                      time: '04:00 PM',
                      title: 'How AI is Changing Creation',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=200',
                    ),
                  ],
                ),
                _buildCalendarDayColumn(
                  day: 'Wed 21',
                  isToday: true,
                  posts: [
                    _CalendarItemData(
                      platform: 'linkedin',
                      time: '10:30 AM',
                      title: '3 Ways Data Improves Marketing',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'instagram',
                      time: '02:00 PM',
                      title: 'Office Vibes Wednesday ✨',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=200',
                    ),
                  ],
                ),
                _buildCalendarDayColumn(
                  day: 'Thu 22',
                  isToday: false,
                  posts: [
                    _CalendarItemData(
                      platform: 'facebook',
                      time: '11:30 AM',
                      title: 'New Project Spotlight',
                      status: 'Pending Review',
                      imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'linkedin',
                      time: '03:00 PM',
                      title: '5 Content Tips That Actually Work',
                      status: 'Pending Review',
                      imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=200',
                    ),
                  ],
                ),
                _buildCalendarDayColumn(
                  day: 'Fri 23',
                  isToday: false,
                  posts: [
                    _CalendarItemData(
                      platform: 'instagram',
                      time: '10:00 AM',
                      title: 'Client Success Stories',
                      status: 'Draft',
                      imageUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'facebook',
                      time: '04:30 PM',
                      title: 'Q&A Friday: Ask Us Anything',
                      status: 'Draft',
                      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=200',
                    ),
                  ],
                ),
                _buildCalendarDayColumn(
                  day: 'Sat 24',
                  isToday: false,
                  posts: [],
                ),
                _buildCalendarDayColumn(
                  day: 'Sun 25',
                  isToday: false,
                  posts: [
                    _CalendarItemData(
                      platform: 'instagram',
                      time: '06:00 PM',
                      title: 'Sunday Reset: Plan, Rest, Win',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=200',
                    ),
                    _CalendarItemData(
                      platform: 'linkedin',
                      time: '11:00 AM',
                      title: 'Weekend Motivation: Keep Building',
                      status: 'Scheduled',
                      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Add Content Button
          Center(
            child: InkWell(
              onTap: () => context.go('/publishing/create'),
              borderRadius: AppRadius.pillBorder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Add Content',
                      style: AppTypography.button.copyWith(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayColumn({
    required String day,
    required bool isToday,
    required List<_CalendarItemData> posts,
  }) {
    return Container(
      width: 154,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.elevatedCard.withOpacity(0.5) : Colors.transparent,
        borderRadius: AppRadius.mdBorder,
        border: isToday ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5) : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Text(
                day,
                style: AppTypography.supporting.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border.withOpacity(0.5), style: BorderStyle.solid),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Center(
                child: Text('No posts', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ...posts.map((p) => _buildCalendarPostCard(p)),
        ],
      ),
    );
  }

  Widget _buildCalendarPostCard(_CalendarItemData item) {
    Color badgeColor = AppColors.success;
    if (item.status == 'Pending Review') badgeColor = AppColors.warning;
    if (item.status == 'Draft') badgeColor = AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.elevatedCard,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlatformBrandIcon(platform: item.platform, size: 18),
              Text(
                item.time,
                style: AppTypography.chip.copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.imageUrl,
              height: 60,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 60,
                color: AppColors.secondaryBackground,
                child: const Icon(LucideIcons.image, size: 16, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.supporting.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.status,
              style: AppTypography.chip.copyWith(
                color: badgeColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Content Pipeline Tracker Card
  Widget _buildContentPipelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Pipeline', style: AppTypography.cardHeading),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPipelineStage(icon: LucideIcons.lightbulb, label: 'Idea Generation', count: '18', color: AppColors.warning),
                _buildPipelineArrow(),
                _buildPipelineStage(icon: LucideIcons.edit3, label: 'In Progress', count: '12', color: const Color(0xFF38BDF8)),
                _buildPipelineArrow(),
                _buildPipelineStage(icon: LucideIcons.fileCheck, label: 'Ready for Review', count: '7', color: AppColors.accentViolet),
                _buildPipelineArrow(),
                _buildPipelineStage(icon: LucideIcons.checkCircle, label: 'Approved', count: '24', color: AppColors.success),
                _buildPipelineArrow(),
                _buildPipelineStage(icon: LucideIcons.calendar, label: 'Scheduled', count: '24', color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStage({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.supporting.copyWith(fontSize: 11)),
            Text(count, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildPipelineArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Icon(LucideIcons.arrowRight, size: 14, color: AppColors.textMuted),
    );
  }

  // 5. Right Section: Performance Overview Chart
  Widget _buildPerformanceChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Content Performance', style: AppTypography.cardHeading, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: AppRadius.smBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text('This Week', style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        const days = ['May 19', 'May 20', 'May 21', 'May 22', 'May 23', 'May 24', 'May 25'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Text(days[val.toInt()], style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const Text('0', style: TextStyle(fontSize: 9, color: AppColors.textMuted));
                        if (val == 5) return const Text('5K', style: TextStyle(fontSize: 9, color: AppColors.textMuted));
                        if (val == 10) return const Text('10K', style: TextStyle(fontSize: 9, color: AppColors.textMuted));
                        if (val == 15) return const Text('15K', style: TextStyle(fontSize: 9, color: AppColors.textMuted));
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Reach (Blue)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 7),
                      FlSpot(1, 9),
                      FlSpot(2, 8.5),
                      FlSpot(3, 11),
                      FlSpot(4, 10.5),
                      FlSpot(5, 13.5),
                      FlSpot(6, 12.4),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  // Engagement (Violet)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4.5),
                      FlSpot(1, 6),
                      FlSpot(2, 5.8),
                      FlSpot(3, 7.8),
                      FlSpot(4, 7),
                      FlSpot(5, 8.5),
                      FlSpot(6, 8.7),
                    ],
                    isCurved: true,
                    color: AppColors.accentViolet,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  // Clicks (Teal/Green)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 2.5),
                      FlSpot(2, 3),
                      FlSpot(3, 3.2),
                      FlSpot(4, 2.8),
                      FlSpot(5, 4),
                      FlSpot(6, 4.5),
                    ],
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 1.8,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.primary, 'Reach'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.accentViolet, 'Engagement'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.success, 'Clicks'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AppTypography.chip.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  // 6. Right Section: AI Assistant Beta Card
  Widget _buildAiAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.bot, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text('AI Assistant', style: AppTypography.cardHeading),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Beta', style: AppTypography.chip.copyWith(color: AppColors.primary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Here are some content ideas for this week designed for higher engagement:',
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 10),
          _buildAiBullet('Carousel: 5 productivity hacks for marketers'),
          _buildAiBullet('Reel: Day in the life of a creative team'),
          _buildAiBullet('Post: Industry insight with a strong hook'),
          const SizedBox(height: 14),
          OutlinedActionButton(
            text: 'Generate More Ideas',
            icon: LucideIcons.sparkles,
            onPressed: () {
              AppToast.show(context, 'Generated 3 fresh AI ideas for this week!', isSuccess: true);
            },
          ),
          const SizedBox(height: 16),
          // Prompt Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiPromptController,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      hintText: 'Ask AI anything...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.send, size: 16, color: AppColors.primary),
                  onPressed: () {
                    if (_aiPromptController.text.isNotEmpty) {
                      AppToast.show(context, 'AI prompt processed in Demo Mode', isSuccess: true);
                      _aiPromptController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary)),
          Expanded(child: Text(text, style: AppTypography.supporting.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  // 7. Right Section: Approval Queue Card
  Widget _buildApprovalQueueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Approval Queue', style: AppTypography.cardHeading),
              InkWell(
                onTap: () => context.go('/approvals'),
                child: Text('View all', style: AppTypography.chip.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildApprovalItem(
            context,
            title: 'New Project Spotlight',
            meta: 'Facebook • May 22, 11:30 AM',
            imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=100',
          ),
          const SizedBox(height: 12),
          _buildApprovalItem(
            context,
            title: '5 Content Tips That Actually Work',
            meta: 'LinkedIn • May 22, 03:00 PM',
            imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=100',
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(
    BuildContext context, {
    required String title,
    required String meta,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 38,
                height: 38,
                color: AppColors.card,
                child: const Icon(LucideIcons.image, size: 14, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.supporting.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(meta, style: AppTypography.chip.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          InkWell(
            onTap: () => AppToast.show(context, 'Post approved!', isSuccess: true),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.check, size: 14, color: AppColors.success),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => AppToast.show(context, 'Post rejected with feedback request', isError: true),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.x, size: 14, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarItemData {
  final String platform;
  final String time;
  final String title;
  final String status;
  final String imageUrl;

  _CalendarItemData({
    required this.platform,
    required this.time,
    required this.title,
    required this.status,
    required this.imageUrl,
  });
}
