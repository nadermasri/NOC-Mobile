import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final targets = ref.watch(targetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/targets/add'),
          ),
        ],
      ),
      body: targets.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved targets',
              subtitle: 'Add servers, routers, or devices to quickly run diagnostics',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: targets.length,
              itemBuilder: (context, index) {
                final target = targets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showTargetActions(context, target.host),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dns, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  target.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      context.push('/targets/edit/${target.id}');
                                    case 'delete':
                                      ref.read(targetsProvider.notifier).delete(target.id);
                                    case 'report':
                                      context.push('/report?host=${target.host}');
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'report', child: Text('Run Report')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            target.host,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (target.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              target.notes,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (target.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: target.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showTargetActions(BuildContext context, String host) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.network_ping),
                title: const Text('Ping'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tools/ping?host=$host');
                },
              ),
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text('Traceroute'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tools/traceroute?host=$host');
                },
              ),
              ListTile(
                leading: const Icon(Icons.dns),
                title: const Text('DNS Lookup'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tools/dns?domain=$host');
                },
              ),
              ListTile(
                leading: const Icon(Icons.electrical_services),
                title: const Text('Port Check'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tools/port-check?host=$host');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('TLS Check'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tools/tls-check?domain=$host');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
