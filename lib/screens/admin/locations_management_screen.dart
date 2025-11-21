import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class LocationsManagementScreen extends StatefulWidget {
  const LocationsManagementScreen({super.key});

  @override
  State<LocationsManagementScreen> createState() => _LocationsManagementScreenState();
}

class _LocationsManagementScreenState extends State<LocationsManagementScreen> {
  late Future<List<Location>> _locationsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _locationsFuture = context.read<CatalogService>().listLocations();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _locationsFuture;
  }

  Future<void> _showLocationDialog({Location? location}) async {
    final nameCtrl = TextEditingController(text: location?.name ?? '');
    final addressCtrl = TextEditingController(text: location?.address ?? '');
    final notesCtrl = TextEditingController(text: location?.notes ?? '');
    final isPrimary = ValueNotifier<bool>(location?.isPrimary ?? false);
    final catalog = context.read<CatalogService>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location == null ? 'Add Location' : 'Edit Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: isPrimary,
              builder: (_, v, __) => SwitchListTile(
                value: v,
                onChanged: (nv) => isPrimary.value = nv,
                title: const Text('Primary Location'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          )
        ],
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final address = addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim();
      final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
      if (name.isEmpty) return;
      if (location == null) {
        await catalog.createLocation(name: name, address: address, notes: notes, isPrimary: isPrimary.value);
      } else {
        await catalog.updateLocation(Location(
          id: location.id,
          name: name,
          address: address,
          notes: notes,
          parentLocationId: location.parentLocationId,
          isPrimary: isPrimary.value,
        ));
      }
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: DepartmentManagementOnly(
        showError: true,
        child: FutureBuilder<List<Location>>(
          future: _locationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(itemCount: 10, itemHeight: 64),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load locations: ${snapshot.error}'));
            }
            final locations = snapshot.data ?? const [];
            if (locations.isEmpty) {
              return const Center(child: Text('No locations found.'));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(loc.name),
                      subtitle: Text(loc.address ?? loc.notes ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showLocationDialog(location: loc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Location'),
                                  content: Text('Delete "${loc.name}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await catalog.deleteLocation(loc.id);
                                await _refresh();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: DepartmentManagementOnly(
        child: FloatingActionButton(
          onPressed: () => _showLocationDialog(),
          child: const Icon(Icons.add_location_alt_outlined),
        ),
      ),
    );
  }
}
