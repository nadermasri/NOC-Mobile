import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/utils/input_validator.dart';
import 'package:pocket_noc/core/services/network_diagnostics_service.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class HttpHeadersScreen extends ConsumerStatefulWidget {
  final String? initialUrl;

  const HttpHeadersScreen({super.key, this.initialUrl});

  @override
  ConsumerState<HttpHeadersScreen> createState() => _HttpHeadersScreenState();
}

class _HttpHeadersScreenState extends ConsumerState<HttpHeadersScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runHttpHeaders() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !InputValidator.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await NetworkDiagnosticsService().httpHeaders(url);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'http',
      target: url,
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
      durationMs: result['durationMs'] as int? ?? 0,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  Color _statusColor(int? code) {
    if (code == null) return AppColors.error;
    if (code >= 200 && code < 300) return AppColors.success;
    if (code >= 300 && code < 400) return AppColors.info;
    if (code >= 400 && code < 500) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Headers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'URL',
              hint: 'e.g. example.com or https://example.com',
              controller: _urlController,
              onRun: _runHttpHeaders,
              isLoading: _isLoading,
              buttonLabel: 'Check Headers',
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching headers...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'HTTP Headers',
                subtitle: _urlController.text,
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final headers = _result!['headers'] as Map? ?? {};
                  final buf = StringBuffer();
                  buf.writeln('URL: ${_result!['url']}');
                  buf.writeln('Status: ${_result!['statusCode']}');
                  buf.writeln('---');
                  headers.forEach((k, v) => buf.writeln('$k: $v'));
                  Clipboard.setData(ClipboardData(text: buf.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'http',
                    'target': _urlController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_result!['success'] == true) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(_result!['statusCode'] as int?)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_result!['statusCode']}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color:
                                    _statusColor(_result!['statusCode'] as int?),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_result!['durationMs']}ms',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (_result!['headers'] != null)
                        ...(_result!['headers'] as Map).entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    e.key.toString(),
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                    if (_result!['success'] != true)
                      KeyValueRow(
                        label: 'Error',
                        value: _result!['error'] ?? 'Unknown error',
                        valueColor: AppColors.error,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
