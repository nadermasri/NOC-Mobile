import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final publicIp = ref.watch(publicIpProvider);
    final results = ref.watch(resultsProvider);
    final lastResult = results.isNotEmpty ? results.first : null;
    final auth = ref.watch(authStateProvider);
    final monitors = ref.watch(monitorsProvider);
    final unreadAlerts = ref.watch(unreadAlertCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket NOC'),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => context.push('/login'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(publicIpProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Network', style: theme.textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Public IP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                        const Spacer(),
                        publicIp.when(
                          data: (ip) =>
                              Text(ip ?? 'Unavailable', style: theme.textTheme.labelLarge),
                          loading: () => const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, _) => Text('Error',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (lastResult != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Last diagnostic',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              )),
                          const Spacer(),
                          Text(
                            '${lastResult.type.toUpperCase()} · ${lastResult.target}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, h:mm a').format(lastResult.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Monitor status summary (if logged in with monitors)
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 16),
              monitors.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  final upCount =
                      list.where((m) => m['last_status'] == 'up').length;
                  final downCount =
                      list.where((m) => m['last_status'] == 'down').length;
                  final degradedCount =
                      list.where((m) => m['last_status'] == 'degraded').length;

                  return Card(
                    child: InkWell(
                      onTap: () => context.go('/monitors'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monitor_heart,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Monitors',
                                    style: theme.textTheme.headlineSmall),
                                const Spacer(),
                                if (unreadAlerts > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$unreadAlerts alerts',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatusChip(
                                    label: '$upCount Up',
                                    color: AppColors.success),
                                const SizedBox(width: 8),
                                if (downCount > 0)
                                  _StatusChip(
                                      label: '$downCount Down',
                                      color: AppColors.error),
                                if (downCount > 0) const SizedBox(width: 8),
                                if (degradedCount > 0)
                                  _StatusChip(
                                      label: '$degradedCount Degraded',
                                      color: AppColors.warning),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            // Pro upsell card (if free and logged in)
            if (auth.isLoggedIn && auth.plan != 'pro') ...[
              const SizedBox(height: 16),
              Card(
                child: InkWell(
                  onTap: () => context.push('/upgrade'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.05),
                          AppColors.primaryDark.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upgrade to Pro',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text('Unlimited monitors, PDF export, and more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Quick actions
            Text('Tools', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _ToolCard(
                  icon: Icons.network_ping,
                  title: 'Ping',
                  subtitle: 'Latency test',
                  color: AppColors.primary,
                  onTap: () => context.push('/tools/ping'),
                ),
                _ToolCard(
                  icon: Icons.route,
                  title: 'Traceroute',
                  subtitle: 'Path analysis',
                  color: AppColors.info,
                  onTap: () => context.push('/tools/traceroute'),
                ),
                _ToolCard(
                  icon: Icons.dns,
                  title: 'DNS Lookup',
                  subtitle: 'Record query',
                  color: AppColors.success,
                  onTap: () => context.push('/tools/dns'),
                ),
                _ToolCard(
                  icon: Icons.swap_horiz,
                  title: 'Reverse DNS',
                  subtitle: 'PTR lookup',
                  color: AppColors.warning,
                  onTap: () => context.push('/tools/reverse-dns'),
                ),
                _ToolCard(
                  icon: Icons.electrical_services,
                  title: 'Port Check',
                  subtitle: 'TCP connect',
                  color: AppColors.error,
                  onTap: () => context.push('/tools/port-check'),
                ),
                _ToolCard(
                  icon: Icons.http,
                  title: 'HTTP Headers',
                  subtitle: 'Response info',
                  color: const Color(0xFF26A69A),
                  onTap: () => context.push('/tools/http-headers'),
                ),
                _ToolCard(
                  icon: Icons.lock_outline,
                  title: 'TLS Check',
                  subtitle: 'Certificate info',
                  color: const Color(0xFF7E57C2),
                  onTap: () => context.push('/tools/tls-check'),
                ),
                _ToolCard(
                  icon: Icons.calculate_outlined,
                  title: 'Subnet Calc',
                  subtitle: 'CIDR math',
                  color: const Color(0xFFEC407A),
                  onTap: () => context.push('/tools/subnet-calc'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent results
            if (results.isNotEmpty) ...[
              Row(
                children: [
                  Text('Recent Results', style: theme.textTheme.headlineMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/report'),
                    child: const Text('Report'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...results.take(5).map(
                    (result) => _RecentResultCard(result: result),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentResultCard extends StatelessWidget {
  final DiagnosticResult result;

  const _RecentResultCard({required this.result});

  IconData get _icon {
    switch (result.type) {
      case 'ping':
        return Icons.network_ping;
      case 'traceroute':
        return Icons.route;
      case 'dns':
        return Icons.dns;
      case 'reverseDns':
        return Icons.swap_horiz;
      case 'port':
        return Icons.electrical_services;
      case 'http':
        return Icons.http;
      case 'tls':
        return Icons.lock_outline;
      case 'subnet':
        return Icons.calculate_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icon, color: AppColors.primary),
        title: Text(
          '${result.type.toUpperCase()} · ${result.target}',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          result.summary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        trailing: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? AppColors.success : AppColors.error,
          size: 18,
        ),
      ),
    );
  }
}
