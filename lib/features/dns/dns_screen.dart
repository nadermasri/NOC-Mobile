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

class DnsScreen extends ConsumerStatefulWidget {
  final String? initialDomain;

  const DnsScreen({super.key, this.initialDomain});

  @override
  ConsumerState<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends ConsumerState<DnsScreen> {
  final _domainController = TextEditingController();
  String _selectedRecordType = 'A';
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

  Future<void> _runDnsLookup() async {
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

    final result = await NetworkDiagnosticsService()
        .dnsLookup(domain, recordType: _selectedRecordType);

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final diagnosticResult = DiagnosticResult(
      id: const Uuid().v4(),
      type: 'dns',
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('DNS Lookup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'Domain',
              hint: 'e.g. example.com',
              controller: _domainController,
              onRun: _runDnsLookup,
              isLoading: _isLoading,
              buttonLabel: 'Lookup',
              extraField: Wrap(
                spacing: 8,
                children: AppConstants.dnsRecordTypes.map((type) {
                  final isSelected = type == _selectedRecordType;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRecordType = type);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
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
                      Text('Looking up DNS records...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'DNS Result',
                subtitle:
                    '${_domainController.text} · $_selectedRecordType',
                isSuccess: _result!['success'] == true,
                onCopy: () {
                  final records = _result!['records'] as List? ?? [];
                  final buf = StringBuffer();
                  buf.writeln('DNS Lookup: ${_domainController.text}');
                  buf.writeln('Record Type: $_selectedRecordType');
                  buf.writeln('Resolver: ${_result!['resolver'] ?? 'N/A'}');
                  for (final r in records) {
                    final rec = Map<String, dynamic>.from(r as Map);
                    buf.writeln('${rec['type']}\t${rec['value']}\tTTL: ${rec['ttl']}');
                  }
                  Clipboard.setData(ClipboardData(text: buf.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                onExplain: () {
                  context.push('/ai-explain', extra: {
                    'type': 'dns',
                    'target': _domainController.text,
                    'result': _result,
                  });
                },
                child: Column(
                  children: [
                    KeyValueRow(
                      label: 'Resolver',
                      value: _result!['resolver'] ?? 'N/A',
                    ),
                    const Divider(),
                    if (_result!['records'] != null)
                      ...(_result!['records'] as List).map((r) {
                        final rec = Map<String, dynamic>.from(r as Map);
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${rec['type']}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${rec['value']}',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                              Text(
                                'TTL: ${rec['ttl']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
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
