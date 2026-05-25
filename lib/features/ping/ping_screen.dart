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

class PingScreen extends ConsumerStatefulWidget {
  final String? initialHost;

  const PingScreen({super.key, this.initialHost});

  @override
  ConsumerState<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends ConsumerState<PingScreen> {
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

  Future<void> _runPing() async {
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

    final result = await NetworkDiagnosticsService().ping(host);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'ping',
      target: host,
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
      durationMs: result['durationMs'] as int? ?? 0,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  String _formatResult() {
    if (_result == null) return '';
    final buf = StringBuffer();
    buf.writeln('Ping: ${_hostController.text}');
    buf.writeln('Sent: ${_result!['sent']}');
    buf.writeln('Received: ${_result!['received']}');
    buf.writeln('Packet Loss: ${_result!['packetLoss']}%');
    if (_result!['success'] == true) {
      buf.writeln('Min: ${_result!['min']}ms');
      buf.writeln('Max: ${_result!['max']}ms');
      buf.writeln('Avg: ${_result!['avg']}ms');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ping')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'Target',
              hint: 'Hostname or IP address',
              controller: _hostController,
              onRun: _runPing,
              isLoading: _isLoading,
              buttonLabel: 'Ping',
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
                      Text('Pinging...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'Ping Result',
                subtitle: _hostController.text,
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: _formatResult()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'ping',
                    'target': _hostController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    KeyValueRow(
                      label: 'Packets Sent',
                      value: '${_result!['sent'] ?? 'N/A'}',
                    ),
                    KeyValueRow(
                      label: 'Packets Received',
                      value: '${_result!['received'] ?? 'N/A'}',
                    ),
                    KeyValueRow(
                      label: 'Packet Loss',
                      value: '${_result!['packetLoss'] ?? 'N/A'}%',
                      valueColor: (_result!['packetLoss'] ?? '0') == '0'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    if (_result!['success'] == true) ...[
                      const Divider(),
                      KeyValueRow(
                        label: 'Min Latency',
                        value: '${_result!['min']}ms',
                        monospace: true,
                      ),
                      KeyValueRow(
                        label: 'Max Latency',
                        value: '${_result!['max']}ms',
                        monospace: true,
                      ),
                      KeyValueRow(
                        label: 'Avg Latency',
                        value: '${_result!['avg']}ms',
                        monospace: true,
                        valueColor: AppColors.primary,
                      ),
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
