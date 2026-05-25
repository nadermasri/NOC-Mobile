import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';

class CreateMonitorScreen extends ConsumerStatefulWidget {
  const CreateMonitorScreen({super.key});

  @override
  ConsumerState<CreateMonitorScreen> createState() =>
      _CreateMonitorScreenState();
}

class _CreateMonitorScreenState extends ConsumerState<CreateMonitorScreen> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _type = 'http';
  int _interval = 300;
  int _timeout = 10;
  int _retryCount = 3;
  bool _isLoading = false;
  String? _error;

  // HTTP config
  int _expectedStatus = 200;
  // TCP config
  int _port = 443;
  // DNS config
  final _expectedIpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _expectedIpController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildConfig() {
    switch (_type) {
      case 'http':
        return {'expected_status': _expectedStatus};
      case 'tcp':
        return {'port': _port};
      case 'dns':
        final ip = _expectedIpController.text.trim();
        return ip.isNotEmpty ? {'expected_ip': ip} : {};
      case 'ip_change':
        return {};
      default:
        return {};
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(monitorsProvider.notifier).create({
      'name': _nameController.text.trim(),
      'target': _targetController.text.trim(),
      'monitor_type': _type,
      'interval_seconds': _interval,
      'timeout_seconds': _timeout,
      'retry_count': _retryCount,
      'config': _buildConfig(),
    });

    if (!mounted) return;

    if (result['success'] == true) {
      context.pop();
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Monitor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.error, fontSize: 14)),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Website',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target',
                  hintText: _type == 'http'
                      ? 'https://example.com'
                      : _type == 'dns'
                          ? 'example.com'
                          : 'example.com',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Monitor Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['http', 'tcp', 'tls', 'dns', 'ip_change']
                    .map((t) => ChoiceChip(
                          label: Text(t.toUpperCase()),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (_type == 'http') ...[
                DropdownButtonFormField<int>(
                  initialValue: _expectedStatus,
                  decoration:
                      const InputDecoration(labelText: 'Expected Status'),
                  items: [200, 201, 301, 302, 404]
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text('$s')))
                      .toList(),
                  onChanged: (v) => setState(() => _expectedStatus = v ?? 200),
                ),
                const SizedBox(height: 16),
              ],
              if (_type == 'tcp') ...[
                TextFormField(
                  initialValue: '$_port',
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _port = int.tryParse(v) ?? 443,
                ),
                const SizedBox(height: 16),
              ],
              if (_type == 'dns') ...[
                TextFormField(
                  controller: _expectedIpController,
                  decoration: const InputDecoration(
                    labelText: 'Expected IP (optional)',
                    hintText: '93.184.216.34',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _interval,
                      decoration:
                          const InputDecoration(labelText: 'Interval'),
                      items: [
                        const DropdownMenuItem(value: 60, child: Text('1 min')),
                        const DropdownMenuItem(value: 300, child: Text('5 min')),
                        const DropdownMenuItem(value: 600, child: Text('10 min')),
                        const DropdownMenuItem(value: 1800, child: Text('30 min')),
                        const DropdownMenuItem(value: 3600, child: Text('1 hr')),
                      ],
                      onChanged: (v) =>
                          setState(() => _interval = v ?? 300),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _timeout,
                      decoration:
                          const InputDecoration(labelText: 'Timeout'),
                      items: [5, 10, 15, 20, 30]
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text('${s}s')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _timeout = v ?? 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _retryCount,
                decoration: const InputDecoration(labelText: 'Retry Count'),
                items: [1, 2, 3, 4, 5]
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) => setState(() => _retryCount = v ?? 3),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _create,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Monitor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
