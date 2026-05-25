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

class TracerouteScreen extends ConsumerStatefulWidget {
  final String? initialHost;

  const TracerouteScreen({super.key, this.initialHost});

  @override
  ConsumerState<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends ConsumerState<TracerouteScreen> {
  final _hostController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialHost != null) {
      _hostController.text = widget.initialHost!;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _runTraceroute() async {
    final host = InputValidator.sanitizeHost(_hostController.text);
    if (host.isEmpty || !InputValidator.isValidHost(host)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid hostname or IP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await NetworkDiagnosticsService().traceroute(host);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'traceroute',
      target: host,
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Traceroute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'Target',
              hint: 'Hostname or IP address',
              controller: _hostController,
              onRun: _runTraceroute,
              isLoading: _isLoading,
              buttonLabel: 'Trace',
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
                      Text('Tracing route...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'Traceroute Result',
                subtitle: _hostController.text,
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final hops = _result!['hops'] as List? ?? [];
                  final buf = StringBuffer();
                  buf.writeln('Traceroute: ${_hostController.text}');
                  for (final hop in hops) {
                    final h = Map<String, dynamic>.from(hop as Map);
                    buf.writeln(
                        '${h['hop']}\t${h['ip']}\t${h['latency']}\t${h['hostname']}');
                  }
                  Clipboard.setData(ClipboardData(text: buf.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'traceroute',
                    'target': _hostController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    if (_result!['hops'] != null)
                      ...(_result!['hops'] as List).map((hop) {
                        final h = Map<String, dynamic>.from(hop as Map);
                        final isTimeout = h['ip'] == '*';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isTimeout
                                ? AppColors.warning.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${h['hop']}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTimeout ? '* * *' : '${h['ip']}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: isTimeout
                                            ? AppColors.warning
                                            : null,
                                      ),
                                    ),
                                    if (!isTimeout && h['hostname'] != h['ip'])
                                      Text(
                                        '${h['hostname']}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextTertiary
                                              : AppColors.lightTextTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                isTimeout ? '-' : '${h['latency']}',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        );
                      }),
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
