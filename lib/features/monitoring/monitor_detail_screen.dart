import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/services/monitor_service.dart';

class MonitorDetailScreen extends ConsumerStatefulWidget {
  final int monitorId;
  const MonitorDetailScreen({super.key, required this.monitorId});

  @override
  ConsumerState<MonitorDetailScreen> createState() =>
      _MonitorDetailScreenState();
}

class _MonitorDetailScreenState extends ConsumerState<MonitorDetailScreen> {
  Map<String, dynamic>? _monitor;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final service = MonitorService();
    final monitor = await service.getMonitor(widget.monitorId);
    final history = await service.getHistory(widget.monitorId, limit: 100);
    if (mounted) {
      setState(() {
        _monitor = monitor;
        _history = history;
        _loading = false;
      });
    }
  }

  Future<void> _runCheck() async {
    setState(() => _checking = true);
    await ref.read(monitorsProvider.notifier).runCheck(widget.monitorId);
    await _loadData();
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _deleteMonitor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Monitor'),
        content: const Text('This will permanently remove the monitor and its history.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(monitorsProvider.notifier).delete(widget.monitorId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_monitor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitor')),
        body: const Center(child: Text('Monitor not found')),
      );
    }

    final m = _monitor!;
    final status = m['last_status'] as String? ?? 'unknown';
    final uptime = (m['uptime_percentage'] as num?)?.toDouble() ?? 100.0;

    Color statusColor;
    switch (status) {
      case 'up':
        statusColor = AppColors.success;
      case 'down':
        statusColor = AppColors.error;
      case 'degraded':
        statusColor = AppColors.warning;
      default:
        statusColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(m['name'] as String? ?? 'Monitor'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteMonitor),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      status == 'up'
                          ? Icons.check_circle
                          : status == 'down'
                              ? Icons.cancel
                              : Icons.warning,
                      color: statusColor,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(status.toUpperCase(),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(m['target'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem('Uptime', '${uptime.toStringAsFixed(1)}%',
                            uptime > 99 ? AppColors.success : uptime > 95 ? AppColors.warning : AppColors.error),
                        _StatItem('Response', '${m['last_response_ms'] ?? '-'}ms', AppColors.info),
                        _StatItem('Checks', '${m['total_checks'] ?? 0}', AppColors.primary),
                        _StatItem('Failures', '${m['total_failures'] ?? 0}',
                            (m['total_failures'] ?? 0) > 0 ? AppColors.error : AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _checking ? null : _runCheck,
              icon: _checking
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: Text(_checking ? 'Checking...' : 'Run Check Now'),
            ),
            const SizedBox(height: 20),

            // Response time chart
            if (_history.length > 1) ...[
              Text('Response Time', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: _ResponseTimeChart(history: _history),
              ),
              const SizedBox(height: 20),
            ],

            // History
            Text('Recent History', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No history yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      )),
                ),
              )
            else
              ..._history.take(20).map((e) => _HistoryTile(execution: e)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ResponseTimeChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _ResponseTimeChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = history.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final ms = (points[i]['response_ms'] as num?)?.toDouble();
      if (ms != null) spots.add(FlSpot(i.toDouble(), ms));
    }
    if (spots.isEmpty) return const SizedBox();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()}ms',
                      TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 12),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> execution;
  const _HistoryTile({required this.execution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = execution['status'] as String? ?? 'unknown';
    final ms = execution['response_ms'];
    final time = execution['executed_at'] as String? ?? '';

    Color statusColor;
    switch (status) {
      case 'up':
        statusColor = AppColors.success;
      case 'down':
        statusColor = AppColors.error;
      case 'degraded':
        statusColor = AppColors.warning;
      default:
        statusColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(status.toUpperCase(),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: statusColor)),
          ),
          if (ms != null)
            Text('${ms}ms',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                )),
          const SizedBox(width: 12),
          Text(
            _formatTime(time),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return isoTime;
    }
  }
}
