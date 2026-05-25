import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class MonitorsScreen extends ConsumerStatefulWidget {
  const MonitorsScreen({super.key});

  @override
  ConsumerState<MonitorsScreen> createState() => _MonitorsScreenState();
}

class _MonitorsScreenState extends ConsumerState<MonitorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(monitorsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monitors = ref.watch(monitorsProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(monitorsProvider.notifier).load(),
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
                    Icon(Icons.cloud_off, size: 64,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    const SizedBox(height: 16),
                    Text('Sign in to use monitors',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Cloud sync required for infrastructure monitoring',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            )
          : monitors.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.monitor_heart_outlined,
                      title: 'No monitors yet',
                      subtitle: 'Add a monitor to track your infrastructure',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(monitorsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final m = list[index];
                          return _MonitorCard(
                            monitor: m,
                            onTap: () => context.push('/monitors/${m['id']}'),
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton(
              onPressed: () => context.push('/monitors/create'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _MonitorCard extends StatelessWidget {
  final Map<String, dynamic> monitor;
  final VoidCallback onTap;

  const _MonitorCard({required this.monitor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = monitor['last_status'] as String? ?? 'unknown';
    final uptime = (monitor['uptime_percentage'] as num?)?.toDouble() ?? 100.0;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'up':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'down':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
      case 'degraded':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
      default:
        statusColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monitor['name'] as String? ?? '',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(monitor['target'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeChip(monitor['monitor_type'] as String? ?? ''),
                        const SizedBox(width: 8),
                        Text('${uptime.toStringAsFixed(1)}% uptime',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: uptime > 99
                                  ? AppColors.success
                                  : uptime > 95
                                      ? AppColors.warning
                                      : AppColors.error,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              if (monitor['last_response_ms'] != null)
                Text('${monitor['last_response_ms']}ms',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    )),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(type.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}
