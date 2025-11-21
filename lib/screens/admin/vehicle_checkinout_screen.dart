import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class VehicleCheckInOutScreen extends StatelessWidget {
  const VehicleCheckInOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<VehicleService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Active Vehicle Check-outs')),
      body: AdminOnly(
        showError: true,
        child: StreamBuilder<List<VehicleCheckInOut>>(
          stream: svc.watchActiveCheckouts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(itemCount: 8, itemHeight: 64),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load: ${snapshot.error}'));
            }
            final records = snapshot.data ?? const [];
            if (records.isEmpty) {
              return const Center(child: Text('No active check-outs'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car_outlined),
                    title: Text('Vehicle: ${r.vehicleId}'),
                    subtitle: Text('User: ${r.userId} • Time: ${r.timestamp?.toLocal().toString().split(' ').first ?? '-'}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
