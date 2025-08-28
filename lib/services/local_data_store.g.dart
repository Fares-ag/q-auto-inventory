// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_data_store.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUserAdapter extends TypeAdapter<LocalUser> {
  @override
  final int typeId = 2;

  @override
  LocalUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUser(
      id: fields[0] as String,
      name: fields[5] as String,
      email: fields[1] as String,
      roleId: fields[2] as String,
      department: fields[4] as String,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalUser obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.roleId)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.department)
      ..writeByte(5)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
