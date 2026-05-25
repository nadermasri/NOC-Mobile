import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadAlerts());
  }

  Future<void> _loadAlerts() async {
    await ref.read(alertsProvider.notifier).load(status: _statusFilter);
    final count = await ref.read(alertServiceProvider).getUnreadCount();
    ref.read(unreadAlertCountProvider.notifier).state = count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alerts = ref.watch(alertsProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Acknowledge All',
            onPressed: () async {
              final count =
                  await ref.read(alertsProvider.notifier).acknowledgeAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$count alerts acknowledged')),
              );
              ref.read(unreadAlertCountProvider.notifier).state = 0;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: !auth.isLoggedIn
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off, size: 64,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    const SizedBox(height: 16),
                    Text('Sign in to view alerts',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _statusFilter == null,
                          onTap: () {
                            setState(() => _statusFilter = null);
                            _loadAlerts();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Unread',
                          selected: _statusFilter == 'unread',
                          onTap: () {
                            setState(() => _statusFilter = 'unread');
                            _loadAlerts();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Acknowledged',
                          selected: _statusFilter == 'acknowledged',
                          onTap: () {
                            setState(() => _statusFilter = 'acknowledged');
                            _loadAlerts();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Resolved',
                          selected: _statusFilter == 'resolved',
                          onTap: () {
                            setState(() => _statusFilter = 'resolved');
                            _loadAlerts();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: alerts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (list) => list.isEmpty
                        ? const EmptyState(
                            icon: Icons.notifications_none,
                            title: 'No alerts',
                            subtitle: 'Alerts from your monitors will appear here',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAlerts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                return _AlertCard(
                                  alert: list[index],
                                  onAcknowledge: () async {
                                    final id = list[index]['id'] as int;
                                    await ref
                                        .read(alertsProvider.notifier)
                                        .acknowledge(id);
                                    final count = await ref
                                        .read(alertServiceProvider)
                                        .getUnreadCount();
                                    ref.read(unreadAlertCountProvider.notifier).state = count;
                                  },
                                  onResolve: () async {
                                    final id = list[index]['id'] as int;
                                    await ref
                                        .read(alertsProvider.notifier)
                                        .resolve(id);
                                    final count = await ref
                                        .read(alertServiceProvider)
                                        .getUnreadCount();
                                    ref.read(unreadAlertCountProvider.notifier).state = count;
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const _AlertCard({
    required this.alert,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final severity = alert['severity'] as String? ?? 'info';
    final status = alert['status'] as String? ?? 'unread';

    Color severityColor;
    IconData severityIcon;
    switch (severity) {
      case 'critical':
        severityColor = AppColors.error;
        severityIcon = Icons.error;
      case 'warning':
        severityColor = AppColors.warning;
        severityIcon = Icons.warning;
      default:
        severityColor = AppColors.info;
        severityIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['title'] as String? ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: status == 'unread'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                        color: severityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert['message'] as String? ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatTime(alert['created_at'] as String? ?? ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                const Spacer(),
                if (status == 'unread')
                  TextButton.icon(
                    onPressed: onAcknowledge,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Acknowledge'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (status == 'acknowledged')
                  TextButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Resolve'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (status == 'resolved')
                  Text('Resolved',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
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
