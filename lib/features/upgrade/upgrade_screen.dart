import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text('Pocket NOC Pro',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Unlock the full power of network monitoring',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Comparison table
            _PlanComparison(isDark: isDark, theme: theme),

            const SizedBox(height: 32),
            if (auth.plan != 'pro') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'In-app purchases coming soon. Contact us for early access.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Upgrade Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cancel anytime. No commitments.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Card(
                color: AppColors.success.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.success),
                  title: Text('You\'re on the Pro plan',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  subtitle: const Text('All features unlocked'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanComparison extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _PlanComparison({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ComparisonRow(
          feature: 'Monitors',
          free: '3',
          pro: 'Unlimited',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'Saved Targets',
          free: '3',
          pro: 'Unlimited',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'Execution History',
          free: '50',
          pro: 'Unlimited',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'AI Explanations',
          free: '5/day',
          pro: 'Unlimited',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'PDF Export',
          free: '-',
          pro: 'Yes',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'Cloud Sync',
          free: 'Yes',
          pro: 'Yes',
          isDark: isDark,
          theme: theme,
        ),
        _ComparisonRow(
          feature: 'All Diagnostics',
          free: 'Yes',
          pro: 'Yes',
          isDark: isDark,
          theme: theme,
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String feature;
  final String free;
  final String pro;
  final bool isDark;
  final ThemeData theme;

  const _ComparisonRow({
    required this.feature,
    required this.free,
    required this.pro,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(feature, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 2,
            child: Text(free,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                )),
          ),
          Expanded(
            flex: 2,
            child: Text(pro,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
