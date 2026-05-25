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

class TlsCheckScreen extends ConsumerStatefulWidget {
  final String? initialDomain;

  const TlsCheckScreen({super.key, this.initialDomain});

  @override
  ConsumerState<TlsCheckScreen> createState() => _TlsCheckScreenState();
}

class _TlsCheckScreenState extends ConsumerState<TlsCheckScreen> {
  final _domainController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialDomain != null) {
      _domainController.text = widget.initialDomain!;
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _runTlsCheck() async {
    final domain = InputValidator.sanitizeHost(_domainController.text);
    if (domain.isEmpty || !InputValidator.isValidHostname(domain)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid domain name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await NetworkDiagnosticsService().tlsCheck(domain);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'tls',
      target: domain,
      data: result,
      success: result['success'] == true,
      error: result['error'] as String?,
    );
    ref.read(resultsProvider.notifier).add(diagnosticResult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('TLS Certificate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'Domain',
              hint: 'e.g. example.com',
              controller: _domainController,
              onRun: _runTlsCheck,
              isLoading: _isLoading,
              buttonLabel: 'Check TLS',
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
                      Text('Checking TLS certificate...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'TLS Certificate',
                subtitle: _domainController.text,
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final buf = StringBuffer();
                  buf.writeln('TLS Check: ${_domainController.text}');
                  if (_result!['success'] == true) {
                    buf.writeln('Issuer: ${_result!['issuer']}');
                    buf.writeln('Subject: ${_result!['subject']}');
                    buf.writeln('Valid From: ${_result!['validFrom']}');
                    buf.writeln('Valid Until: ${_result!['validUntil']}');
                    buf.writeln(
                        'Days Remaining: ${_result!['daysRemaining']}');
                  }
                  Clipboard.setData(ClipboardData(text: buf.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'tls',
                    'target': _domainController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    if (_result!['success'] == true) ...[
                      // Expiry status badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _result!['isExpired'] == true
                              ? AppColors.error.withValues(alpha: 0.1)
                              : _result!['isExpiringSoon'] == true
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _result!['isExpired'] == true
                                  ? Icons.error
                                  : _result!['isExpiringSoon'] == true
                                      ? Icons.warning
                                      : Icons.verified,
                              color: _result!['isExpired'] == true
                                  ? AppColors.error
                                  : _result!['isExpiringSoon'] == true
                                      ? AppColors.warning
                                      : AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _result!['isExpired'] == true
                                  ? 'Certificate Expired'
                                  : _result!['isExpiringSoon'] == true
                                      ? 'Expiring Soon (${_result!['daysRemaining']} days)'
                                      : '${_result!['daysRemaining']} days remaining',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _result!['isExpired'] == true
                                    ? AppColors.error
                                    : _result!['isExpiringSoon'] == true
                                        ? AppColors.warning
                                        : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      KeyValueRow(
                        label: 'Issuer',
                        value: _result!['issuer'] ?? 'N/A',
                      ),
                      KeyValueRow(
                        label: 'Subject',
                        value: _result!['subject'] ?? 'N/A',
                      ),
                      KeyValueRow(
                        label: 'Valid From',
                        value: _formatDate(_result!['validFrom']),
                        monospace: true,
                      ),
                      KeyValueRow(
                        label: 'Valid Until',
                        value: _formatDate(_result!['validUntil']),
                        monospace: true,
                      ),
                      if (_result!['sha1'] != null)
                        KeyValueRow(
                          label: 'SHA-1',
                          value: _result!['sha1']!,
                          monospace: true,
                          copyable: true,
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
