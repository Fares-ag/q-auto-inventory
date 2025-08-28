// lib/models/warranty_model.dart

import 'package:hive/hive.dart';

part 'warranty_model.g.dart';

@HiveType(typeId: 3) // Use a new, unique typeId
class Warranty extends HiveObject {
  @HiveField(0)
  DateTime? expiryDate;

  @HiveField(1)
  String? provider;

  Warranty({
    this.expiryDate,
    this.provider,
  });
}
