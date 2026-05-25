import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/services/network_diagnostics_service.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:intl/intl.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String? targetHost;

  const ReportScreen({super.key, this.targetHost});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _hostController = TextEditingController();
  bool _isRunning = false;
  final List<DiagnosticResult> _reportResults = [];
  final Map<String, bool> _selectedChecks = {
    'ping': true,
    'dns': true,
    'port': true,
    'tls': true,
    'http': true,
    'traceroute': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.targetHost != null) {
      _hostController.text = widget.targetHost!;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _runReport() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isRunning = true;
      _reportResults.clear();
    });

    final diagnostics = NetworkDiagnosticsService();

    if (_selectedChecks['ping'] == true) {
      final result = await diagnostics.ping(host);
      _addResult('ping', host, result);
    }

    if (_selectedChecks['dns'] == true) {
      final result = await diagnostics.dnsLookup(host);
      _addResult('dns', host, result);
    }

    if (_selectedChecks['port'] == true) {
      final result = await diagnostics.portCheck(host, 443);
      _addResult('port', '$host:443', result);
    }

    if (_selectedChecks['tls'] == true) {
      final result = await diagnostics.tlsCheck(host);
      _addResult('tls', host, result);
    }

    if (_selectedChecks['http'] == true) {
      final result = await diagnostics.httpHeaders(host);
      _addResult('http', host, result);
    }

    if (_selectedChecks['traceroute'] == true) {
      final result = await diagnostics.traceroute(host);
      _addResult('traceroute', host, result);
    }

    setState(() => _isRunning = false);
  }

  void _addResult(String type, String target, Map<String, dynamic> data) {
    final result = DiagnosticResult(
      id: const Uuid().v4(),
      type: type,
      target: target,
      data: data,
      success: data['success'] == true,
      error: data['error'] as String?,
      durationMs: data['durationMs'] as int? ?? 0,
    );
    ref.read(resultsProvider.notifier).add(result);
    setState(() => _reportResults.add(result));
  }

  String _generateTextReport() {
    final buf = StringBuffer();
    buf.writeln('=== Pocket NOC Diagnostic Report ===');
    buf.writeln('Target: ${_hostController.text}');
    buf.writeln(
        'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buf.writeln('');

    for (final result in _reportResults) {
      buf.writeln('--- ${result.type.toUpperCase()} ---');
      buf.writeln('Status: ${result.success ? "Success" : "Failed"}');
      buf.writeln('Summary: ${result.summary}');
      if (result.error != null) buf.writeln('Error: ${result.error}');
      buf.writeln('');
    }

    buf.writeln('=== End Report ===');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Report'),
        actions: [
          if (_reportResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.share(_generateTextReport());
              },
            ),
          if (_reportResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _generateTextReport()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copied to clipboard')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      decoration: const InputDecoration(
                          hintText: 'Hostname or IP address'),
                    ),
                    const SizedBox(height: 16),
                    Text('Checks', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedChecks.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key.toUpperCase(),
                              style: const TextStyle(fontSize: 12)),
                          selected: entry.value,
                          onSelected: (selected) {
                            setState(() =>
                                _selectedChecks[entry.key] = selected);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _runReport,
                      child: _isRunning
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Running diagnostics...'),
                              ],
                            )
                          : const Text('Run Report'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_reportResults.isNotEmpty) ...[
              Text('Results', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              ..._reportResults.map((result) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        result.success ? Icons.check_circle : Icons.error,
                        color: result.success
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      title: Text(
                        result.type.toUpperCase(),
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        result.summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        onPressed: () {
                          context.push('/ai-explain', extra: {
                            'type': result.type,
                            'target': result.target,
                            'result': result.data,
                          });
                        },
                        tooltip: 'AI Explain',
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
