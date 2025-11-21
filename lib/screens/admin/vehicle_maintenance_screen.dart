import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class VehicleMaintenanceScreen extends StatefulWidget {
  const VehicleMaintenanceScreen({super.key});

  @override
  State<VehicleMaintenanceScreen> createState() => _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState extends State<VehicleMaintenanceScreen> {
  final TextEditingController _vehicleCtrl = TextEditingController();
  Future<List<VehicleMaintenance>>? _future;

  void _search() {
    final id = _vehicleCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _future = context.read<VehicleService>().listMaintenance(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Maintenance')),
      body: AdminOnly(
        showError: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _vehicleCtrl,
              decoration: const InputDecoration(
                labelText: 'Vehicle ID',
                hintText: 'Enter a vehicleId to view maintenance',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_future != null)
              FutureBuilder<List<VehicleMaintenance>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonList(itemCount: 6, itemHeight: 64),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load: ${snapshot.error}'));
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return const Center(child: Text('No maintenance records found.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final m = list[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.build_outlined),
                          title: Text(m.type),
                          subtitle: Text('Due: ${m.scheduledDate.toString().split(' ').first} • Status: ${m.completedDate == null ? 'pending' : 'completed'}'),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
