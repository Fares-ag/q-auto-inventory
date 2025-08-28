// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warranty_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WarrantyAdapter extends TypeAdapter<Warranty> {
  @override
  final int typeId = 3;

  @override
  Warranty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Warranty(
      expiryDate: fields[0] as DateTime?,
      provider: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Warranty obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.expiryDate)
      ..writeByte(1)
      ..write(obj.provider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarrantyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
