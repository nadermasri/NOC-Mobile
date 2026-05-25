import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/utils/input_validator.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/services/network_diagnostics_service.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class PortCheckScreen extends ConsumerStatefulWidget {
  final String? initialHost;

  const PortCheckScreen({super.key, this.initialHost});

  @override
  ConsumerState<PortCheckScreen> createState() => _PortCheckScreenState();
}

class _PortCheckScreenState extends ConsumerState<PortCheckScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialHost != null) {
      _hostController.text = widget.initialHost!;
    }
    _portController.text = '443';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _runPortCheck() async {
    final host = InputValidator.sanitizeHost(_hostController.text);
    final portStr = _portController.text.trim();
    if (host.isEmpty || !InputValidator.isValidHost(host)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid hostname or IP')),
      );
      return;
    }
    if (!InputValidator.isValidPort(portStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid port number (1-65535)')),
      );
      return;
    }

    final port = int.parse(portStr);

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await NetworkDiagnosticsService().portCheck(host, port);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'port',
      target: '$host:$port',
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
      durationMs: result['durationMs'] as int? ?? 0,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Port Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Target', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hostController,
                      decoration:
                          const InputDecoration(hintText: 'Hostname or IP'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(hintText: 'Port (e.g. 443)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Common ports',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppConstants.commonPorts.take(12).map((port) {
                        return ActionChip(
                          label: Text('$port', style: const TextStyle(fontSize: 11)),
                          onPressed: () =>
                              setState(() => _portController.text = '$port'),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _runPortCheck,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Check Port'),
                    ),
                  ],
                ),
              ),
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
                      Text('Checking port...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'Port Check Result',
                subtitle:
                    '${_hostController.text}:${_portController.text}',
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final open = _result!['open'] == true;
                  final text =
                      'Port Check: ${_hostController.text}:${_portController.text}\n'
                      'Status: ${open ? "Open" : "Closed"}\n'
                      'Latency: ${_result!['latency'] ?? 'N/A'}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'port',
                    'target':
                        '${_hostController.text}:${_portController.text}',
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    KeyValueRow(
                      label: 'Host',
                      value: _result!['host'] ?? 'N/A',
                      monospace: true,
                    ),
                    KeyValueRow(
                      label: 'Port',
                      value: '${_result!['port'] ?? 'N/A'}',
                      monospace: true,
                    ),
                    if (_result!['success'] == true) ...[
                      KeyValueRow(
                        label: 'Status',
                        value: _result!['open'] == true
                            ? 'Open'
                            : (_result!['status'] ?? 'Closed'),
                        valueColor: _result!['open'] == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      if (_result!['latency'] != null)
                        KeyValueRow(
                          label: 'Latency',
                          value: '${_result!['latency']}',
                          monospace: true,
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
