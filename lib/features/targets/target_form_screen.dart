import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:pocket_noc/core/models/target.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';

class TargetFormScreen extends ConsumerStatefulWidget {
  final String? targetId;

  const TargetFormScreen({super.key, this.targetId});

  @override
  ConsumerState<TargetFormScreen> createState() => _TargetFormScreenState();
}

class _TargetFormScreenState extends ConsumerState<TargetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  bool get _isEditing => widget.targetId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final targets = ref.read(targetsProvider);
      final target = targets.where((t) => t.id == widget.targetId).firstOrNull;
      if (target != null) {
        _nameController.text = target.name;
        _hostController.text = target.host;
        _notesController.text = target.notes;
        _tags.addAll(target.tags);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final target = Target(
      id: widget.targetId ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      notes: _notesController.text.trim(),
      tags: List.from(_tags),
    );

    if (_isEditing) {
      await ref.read(targetsProvider.notifier).update(target);
    } else {
      await ref.read(targetsProvider.notifier).add(target);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Target' : 'Add Target'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Home Router, VPS, Raspberry Pi',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Hostname or IP',
                  hintText: 'e.g. 192.168.1.1 or example.com',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Host is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any notes about this target',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Add a tag',
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Examples: home router, VPS, Raspberry Pi, work server',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF8B949E)
                      : const Color(0xFF8C959F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
