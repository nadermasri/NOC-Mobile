import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/utils/subnet_calculator.dart';
import 'package:pocket_noc/core/widgets/result_card.dart';

class SubnetCalcScreen extends StatefulWidget {
  const SubnetCalcScreen({super.key});

  @override
  State<SubnetCalcScreen> createState() => _SubnetCalcScreenState();
}

class _SubnetCalcScreenState extends State<SubnetCalcScreen> {
  final _cidrController = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _cidrController.dispose();
    super.dispose();
  }

  void _calculate() {
    final cidr = _cidrController.text.trim();
    if (cidr.isEmpty) return;

    setState(() {
      _error = null;
      _result = null;
    });

    try {
      final calc = SubnetCalculator(cidr);
      setState(() => _result = calc.calculate());
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subnet Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToolInputSection(
              label: 'CIDR Notation',
              hint: 'e.g. 192.168.1.0/24',
              controller: _cidrController,
              onRun: _calculate,
              buttonLabel: 'Calculate',
            ),
            const SizedBox(height: 16),
            if (_error != null)
              ResultCard(
                title: 'Error',
                isSuccess: false,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (_result != null)
              ResultCard(
                title: 'Subnet Details',
                subtitle: _result!['cidr'],
                isSuccess: true,
                onCopy: () {
                  final buf = StringBuffer();
                  buf.writeln('Subnet Calculator: ${_result!['cidr']}');
                  buf.writeln('Network: ${_result!['networkAddress']}');
                  buf.writeln('Broadcast: ${_result!['broadcastAddress']}');
                  buf.writeln('Subnet Mask: ${_result!['subnetMask']}');
                  buf.writeln('Wildcard: ${_result!['wildcardMask']}');
                  buf.writeln('Usable Range: ${_result!['usableRange']}');
                  buf.writeln('Usable Hosts: ${_result!['usableHosts']}');
                  buf.writeln('Total Hosts: ${_result!['totalHosts']}');
                  buf.writeln('Class: ${_result!['ipClass']}');
                  buf.writeln('Private: ${_result!['isPrivate']}');
                  Clipboard.setData(ClipboardData(text: buf.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Column(
                  children: [
                    KeyValueRow(
                      label: 'Network',
                      value: _result!['networkAddress'],
                      monospace: true,
                      copyable: true,
                    ),
                    KeyValueRow(
                      label: 'Broadcast',
                      value: _result!['broadcastAddress'],
                      monospace: true,
                      copyable: true,
                    ),
                    KeyValueRow(
                      label: 'Subnet Mask',
                      value: _result!['subnetMask'],
                      monospace: true,
                    ),
                    KeyValueRow(
                      label: 'Wildcard Mask',
                      value: _result!['wildcardMask'],
                      monospace: true,
                    ),
                    const Divider(),
                    KeyValueRow(
                      label: 'Usable Range',
                      value: _result!['usableRange'],
                      monospace: true,
                    ),
                    KeyValueRow(
                      label: 'Usable Hosts',
                      value: '${_result!['usableHosts']}',
                      valueColor: AppColors.primary,
                    ),
                    KeyValueRow(
                      label: 'Total Addresses',
                      value: '${_result!['totalHosts']}',
                    ),
                    const Divider(),
                    KeyValueRow(
                      label: 'Prefix',
                      value: '/${_result!['prefix']}',
                    ),
                    KeyValueRow(
                      label: 'IP Class',
                      value: _result!['ipClass'],
                    ),
                    KeyValueRow(
                      label: 'Private',
                      value: _result!['isPrivate'] ? 'Yes' : 'No',
                      valueColor: _result!['isPrivate']
                          ? AppColors.success
                          : AppColors.info,
                    ),
                    const Divider(),
                    KeyValueRow(
                      label: 'Binary Mask',
                      value: _result!['binaryMask'],
                      monospace: true,
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
