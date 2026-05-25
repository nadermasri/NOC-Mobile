import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? child;
  final bool isSuccess;
  final bool isLoading;
  final VoidCallback? onCopy;
  final VoidCallback? onExplain;

  const ResultCard({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.isSuccess = true,
    this.isLoading = false,
    this.onCopy,
    this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!isLoading)
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: onCopy,
                    tooltip: 'Copy',
                    visualDensity: VisualDensity.compact,
                  ),
                if (onExplain != null)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    onPressed: onExplain,
                    tooltip: 'AI Explain',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;
  final bool copyable;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.monospace = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: $value'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Text(
                value,
                style: monospace
                    ? theme.textTheme.labelMedium
                        ?.copyWith(color: valueColor)
                    : theme.textTheme.bodyMedium
                        ?.copyWith(color: valueColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ToolInputSection extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onRun;
  final bool isLoading;
  final String buttonLabel;
  final Widget? extraField;

  const ToolInputSection({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onRun,
    this.isLoading = false,
    this.buttonLabel = 'Run',
    this.extraField,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint),
              onSubmitted: (_) => isLoading ? null : onRun(),
            ),
            if (extraField != null) ...[
              const SizedBox(height: 12),
              extraField!,
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : onRun,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
