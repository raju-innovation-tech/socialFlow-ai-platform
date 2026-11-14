import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  final List<Map<String, String>> _logs = [
    {'time': '12:04:15.820', 'level': 'INFO', 'service': 'worker-scheduler', 'message': 'Processed 14 scheduled cron jobs. Zero dispatch failures.'},
    {'time': '12:03:42.110', 'level': 'INFO', 'service': 'meta-publisher', 'message': 'Successfully published Instagram carousel to @cybermagic.studio (id: 1794281928)'},
    {'time': '12:02:18.450', 'level': 'INFO', 'service': 'telegram-bot-pool', 'message': 'Broadcast batch of 1 message delivered to 14,800 channel subscribers.'},
    {'time': '12:00:00.005', 'level': 'WARN', 'service': 'token-vault', 'message': 'LinkedIn OAuth token for tenant ws_9124 expiring in 48 hours. Auto-refresh dispatched.'},
    {'time': '11:58:32.920', 'level': 'INFO', 'service': 'redis-broker', 'message': 'Queue depth healthy: 4 pending, 18 in-flight tasks across 8 workers.'},
  ];

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
              title: 'System Telemetry & Worker Logs',
              subtitle: 'Real-time distributed background worker queues, publisher events, and error audit trail.',
              breadcrumbs: const ['Super Admin', 'System Logs'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Admin Dashboard',
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => context.go('/super-admin/dashboard'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Refresh Streams',
                    icon: LucideIcons.rotateCw,
                    onPressed: () => AppToast.show(context, 'Streams refreshed from Redis log tail (Demo)', isSuccess: true),
                  ),
                ],
              ),
            ),

            // Telemetry overview bar
            Row(
              children: [
                _buildLogMetric('Active Celery Workers', '8 / 8 Online', AppColors.success),
                const SizedBox(width: 16),
                _buildLogMetric('Redis Queue Latency', '4.2ms', AppColors.primary),
                const SizedBox(width: 16),
                _buildLogMetric('Memory Utilization', '2.4 GB / 8 GB', AppColors.accentViolet),
                const SizedBox(width: 16),
                _buildLogMetric('Error Rate (Last 1hr)', '0.00%', AppColors.success),
              ],
            ),
            const SizedBox(height: 24),

            // Dark Terminal Log Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF070B12),
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                          const SizedBox(width: 14),
                          Text('tail -f /var/log/socialflow/publisher_cluster.log', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const StatusBadge(label: 'Live Stream Active', color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isWarn = log['level'] == 'WARN';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['time']!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(width: 12),
                            Text(
                              '[${log["level"]}]',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWarn ? AppColors.warning : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${log["service"]}:', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.primary)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                log['message']!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.cardHeading.copyWith(fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}
