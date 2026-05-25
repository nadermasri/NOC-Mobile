import 'package:flutter/material.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: theme.textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              'Last updated: May 2025',
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
            const SizedBox(height: 24),
            _section(theme, textColor, 'What This App Does',
                'Pocket NOC is a network diagnostics and infrastructure toolkit. '
                'It performs standard network diagnostic operations including ping, '
                'traceroute, DNS lookups, port checks, TLS certificate inspection, '
                'HTTP header checks, and subnet calculations.'),
            _section(theme, textColor, 'What This App Does NOT Do',
                'This app does not perform offensive security scanning, packet sniffing, '
                'vulnerability exploitation, or any form of aggressive network probing. '
                'All operations are standard, read-only diagnostic operations that are '
                'commonly available in operating system command-line tools.'),
            _section(theme, textColor, 'Data Collection',
                'All diagnostic results are stored locally on your device using '
                'encrypted local storage. No data is sent to external servers unless '
                'you explicitly use the AI Explanation feature, which sends diagnostic '
                'results to our backend API for analysis. No personal information is '
                'collected or transmitted.'),
            _section(theme, textColor, 'Data Storage',
                'Your saved targets, diagnostic results, and preferences are stored '
                'locally on your device. You can export your data at any time from '
                'the Settings screen, and you can delete all data at any time.'),
            _section(theme, textColor, 'Third-Party Services',
                'The app uses the ipify.org API to determine your public IP address. '
                'No identifying information is sent with this request. When using the '
                'AI Explanation feature, diagnostic data is sent to our backend for '
                'processing.'),
            _section(theme, textColor, 'Your Rights',
                'You have the right to export all of your data, delete all of your data, '
                'and stop using the app at any time. All data deletion is immediate and '
                'permanent.'),
            _section(theme, textColor, 'Contact',
                'If you have questions about this privacy policy, please contact us '
                'through the app store listing or our website.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(
      ThemeData theme, Color textColor, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
