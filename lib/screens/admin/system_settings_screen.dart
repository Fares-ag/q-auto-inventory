import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  SystemSettings? _settings;
  bool _loading = true;
  String? _error;

  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _timezoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final svc = context.read<SystemSettingsService>();
      final s = await svc.fetchSettings();
      setState(() {
        _settings = s;
        _companyCtrl.text = s?.companyName ?? '';
        _timezoneCtrl.text = s?.defaultTimezone ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final svc = context.read<SystemSettingsService>();
    final newSettings = SystemSettings(
      id: _settings?.id ?? 'config',
      companyName: _companyCtrl.text.trim(),
      defaultTimezone: _timezoneCtrl.text.trim(),
    );
    await svc.updateSettings(newSettings);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(onPressed: _loading ? null : _save, icon: const Icon(Icons.save_outlined)),
        ],
      ),
      body: AdminOnly(
        showError: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _companyCtrl,
                        decoration: const InputDecoration(labelText: 'Company Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _timezoneCtrl,
                        decoration: const InputDecoration(labelText: 'Default Timezone (e.g., UTC, GMT+3)'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
