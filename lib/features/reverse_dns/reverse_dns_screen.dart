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

class ReverseDnsScreen extends ConsumerStatefulWidget {
  final String? initialIp;

  const ReverseDnsScreen({super.key, this.initialIp});

  @override
  ConsumerState<ReverseDnsScreen> createState() => _ReverseDnsScreenState();
}

class _ReverseDnsScreenState extends ConsumerState<ReverseDnsScreen> {
  final _ipController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialIp != null) {
      _ipController.text = widget.initialIp!;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _runReverseDns() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty || !InputValidator.isValidIpv4(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IPv4 address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await NetworkDiagnosticsService().reverseDns(ip);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'reverseDns',
      target: ip,
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reverse DNS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'IP Address',
              hint: 'e.g. 8.8.8.8',
              controller: _ipController,
              onRun: _runReverseDns,
              isLoading: _isLoading,
              buttonLabel: 'Lookup',
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
                      Text('Looking up PTR record...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'Reverse DNS Result',
                subtitle: _ipController.text,
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final text =
                      'Reverse DNS: ${_ipController.text}\nPTR: ${_result!['ptr'] ?? 'N/A'}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'reverseDns',
                    'target': _ipController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    KeyValueRow(
                      label: 'IP',
                      value: _result!['ip'] ?? 'N/A',
                      monospace: true,
                    ),
                    if (_result!['success'] == true)
                      KeyValueRow(
                        label: 'PTR Record',
                        value: _result!['ptr'] ?? 'N/A',
                        monospace: true,
                        copyable: true,
                        valueColor: AppColors.primary,
                      ),
                    if (_result!['success'] != true)
                      KeyValueRow(
                        label: 'Error',
                        value: _result!['error'] ?? 'No PTR record found',
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
