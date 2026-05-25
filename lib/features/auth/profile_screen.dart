import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      (auth.displayName.isNotEmpty
                              ? auth.displayName[0]
                              : auth.email.isNotEmpty
                                  ? auth.email[0]
                                  : '?')
                          .toUpperCase(),
                      style: theme.textTheme.displayMedium
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.displayName.isNotEmpty ? auth.displayName : 'User',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: auth.plan == 'pro'
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: auth.plan == 'pro'
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                    ),
                    child: Text(
                      auth.plan == 'pro' ? 'PRO' : 'FREE',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: auth.plan == 'pro'
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (auth.plan != 'pro')
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: AppColors.warning),
                title: const Text('Upgrade to Pro'),
                subtitle: const Text('Unlimited monitors, alerts, and more'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/upgrade'),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Profile'),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).refreshProfile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile refreshed')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text('Sign Out',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/dashboard');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
