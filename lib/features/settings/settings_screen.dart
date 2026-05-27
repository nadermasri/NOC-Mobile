import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/services/storage_service.dart';
import 'package:pocket_noc/core/services/pdf_export_service.dart';
import 'package:pocket_noc/core/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account
          _SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                if (auth.isLoggedIn) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (auth.displayName.isNotEmpty
                                ? auth.displayName[0]
                                : auth.email.isNotEmpty
                                    ? auth.email[0]
                                    : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(auth.displayName.isNotEmpty
                        ? auth.displayName
                        : auth.email),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: auth.plan == 'pro'
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightBg),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            auth.plan.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: auth.plan == 'pro'
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile'),
                  ),
                  if (auth.plan != 'pro') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.star, color: AppColors.warning),
                      title: const Text('Upgrade to Pro'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/upgrade'),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: AppColors.error),
                    title: const Text('Delete Account',
                        style: TextStyle(color: AppColors.error)),
                    subtitle: const Text(
                        'Permanently delete your account and all data'),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign In'),
                    subtitle: const Text('Sync monitors and alerts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/login'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setDarkMode(value);
              },
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data
          _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Export PDF Report'),
                  subtitle: const Text('Generate PDF from recent diagnostics'),
                  onTap: () => _exportPdf(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle:
                      const Text('Export targets and results as JSON'),
                  onTap: () {
                    final data = StorageService().exportData();
                    final json =
                        const JsonEncoder.withIndent('  ').convert(data);
                    Share.share(json, subject: 'Pocket NOC Data Export');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.warning),
                  title: const Text('Clear History'),
                  subtitle: const Text('Delete all diagnostic results'),
                  onTap: () => _confirmClearHistory(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: AppColors.error),
                  title: const Text('Clear All Data'),
                  subtitle:
                      const Text('Delete all targets and results'),
                  onTap: () => _confirmClearAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legal
          _SectionHeader(title: 'Legal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy-policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('NOC Mobile'),
                  subtitle: Text(
                    'Network diagnostics and infrastructure toolkit',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Version'),
                  subtitle: const Text(AppConstants.appVersion),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'NOC Mobile v${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _exportPdf(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authStateProvider);
    if (auth.plan != 'pro' && auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF export is a Pro feature'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () => context.push('/upgrade'),
          ),
        ),
      );
      return;
    }

    final results = ref.read(resultsProvider);
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No diagnostic results to export')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    await PdfExportService.exportAndShare(
      results: results,
      title: 'Diagnostic Report',
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will delete all diagnostic results. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(resultsProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete all targets and results. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService().clearAll();
              ref.read(targetsProvider.notifier).refresh();
              ref.read(resultsProvider.notifier).clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data from our servers. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await AuthService().deleteAccount();
              if (success) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                    ),
                  );
                }
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to delete account. Please try again or contact support.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete Account',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
      ),
    );
  }
}
