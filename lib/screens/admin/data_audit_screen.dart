import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataAuditScreen extends StatefulWidget {
  const DataAuditScreen({super.key});

  @override
  State<DataAuditScreen> createState() => _DataAuditScreenState();
}

class _DataAuditScreenState extends State<DataAuditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _collections = const [
    'assetCounter',
    'categories',
    'comments',
    'departments',
    'history',
    'issues',
    'items',
    'locations',
    'permissionSets',
    'staff',
    'subDepartments',
    'sub_departments',
    'system',
    'users',
    'vehicle_checkinout',
    'vehicle_maintenance',
  ];

  bool _loading = false;
  Map<String, int> _counts = <String, int>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Map<String, int> results = <String, int>{};
    try {
      for (final name in _collections) {
        try {
          // Prefer server-side aggregation count if available
          final aggregateQuery = _firestore.collection(name).count();
          final aggregateSnapshot = await aggregateQuery.get();
          results[name] = aggregateSnapshot.count as int;
        } catch (_) {
          // Fallback: do a lightweight estimate by fetching first page size (not accurate for huge datasets)
          final snap = await _firestore.collection(name).limit(1000).get();
          results[name] = snap.size; // indicates at least this many
        }
      }
      if (!mounted) return;
      setState(() {
        _counts = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showPreview(String name) async {
    try {
      final snapshot = await _firestore.collection(name).limit(5).get();
      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No documents found in $name')),
        );
        return;
      }
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name preview',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...snapshot.docs.map((doc) {
                  final data = doc.data();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(doc.id),
                      subtitle: Text(_formatPreview(data)),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load $name: $e')),
      );
    }
  }

  String _formatPreview(Map<String, dynamic> data) {
    final entries = data.entries.take(4).map((e) => '${e.key}: ${e.value}');
    return entries.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Audit'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : ListView.separated(
                    itemCount: _collections.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final name = _collections[index];
                      final count = _counts[name];
                      return ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: Text(name),
                        trailing: Text(count == null ? '—' : count.toString()),
                        onTap: () => _showPreview(name),
                      );
                    },
                  ),
      ),
    );
  }
}
