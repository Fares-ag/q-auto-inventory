// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 1;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      itemType: fields[3] as ItemType,
      purchaseDate: fields[4] as DateTime,
      variants: fields[5] as String,
      supplier: fields[6] as String,
      company: fields[7] as String,
      qrCodeId: fields[8] as String?,
      qrCodeUrl: fields[9] as String?,
      department: fields[14] as String?,
      assignedStaff: fields[15] as String?,
      purchasePrice: fields[16] as double?,
      lastMaintenanceDate: fields[17] as DateTime?,
      maintenanceSchedule: fields[18] as String?,
      currentValue: fields[19] as double?,
      nextMaintenanceDate: fields[20] as DateTime?,
      coCd: fields[21] as String?,
      sapClass: fields[22] as String?,
      assetClassDesc: fields[23] as String?,
      apcAcct: fields[24] as String?,
      licPlate: fields[25] as String?,
      vendor: fields[26] as String?,
      plnt: fields[27] as String?,
      modelCode: fields[28] as String?,
      modelDesc: fields[29] as String?,
      modelYear: fields[30] as String?,
      assetType: fields[31] as String?,
      owner: fields[32] as String?,
      vehicleIdNo: fields[33] as String?,
      vehicleModel: fields[34] as String?,
      location: fields[35] as String?,
      isTagged: fields[11] as bool,
      isWrittenOff: fields[12] as bool,
      isAvailable: fields[13] as bool,
      status: fields[10] as String,
      imageUrl: fields[36] as String?,
      customFields: (fields[37] as Map).cast<String, dynamic>(),
      warranty: fields[38] as Warranty?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(39)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.itemType)
      ..writeByte(4)
      ..write(obj.purchaseDate)
      ..writeByte(5)
      ..write(obj.variants)
      ..writeByte(6)
      ..write(obj.supplier)
      ..writeByte(7)
      ..write(obj.company)
      ..writeByte(8)
      ..write(obj.qrCodeId)
      ..writeByte(9)
      ..write(obj.qrCodeUrl)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.isTagged)
      ..writeByte(12)
      ..write(obj.isWrittenOff)
      ..writeByte(13)
      ..write(obj.isAvailable)
      ..writeByte(14)
      ..write(obj.department)
      ..writeByte(15)
      ..write(obj.assignedStaff)
      ..writeByte(16)
      ..write(obj.purchasePrice)
      ..writeByte(17)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(18)
      ..write(obj.maintenanceSchedule)
      ..writeByte(19)
      ..write(obj.currentValue)
      ..writeByte(20)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(21)
      ..write(obj.coCd)
      ..writeByte(22)
      ..write(obj.sapClass)
      ..writeByte(23)
      ..write(obj.assetClassDesc)
      ..writeByte(24)
      ..write(obj.apcAcct)
      ..writeByte(25)
      ..write(obj.licPlate)
      ..writeByte(26)
      ..write(obj.vendor)
      ..writeByte(27)
      ..write(obj.plnt)
      ..writeByte(28)
      ..write(obj.modelCode)
      ..writeByte(29)
      ..write(obj.modelDesc)
      ..writeByte(30)
      ..write(obj.modelYear)
      ..writeByte(31)
      ..write(obj.assetType)
      ..writeByte(32)
      ..write(obj.owner)
      ..writeByte(33)
      ..write(obj.vehicleIdNo)
      ..writeByte(34)
      ..write(obj.vehicleModel)
      ..writeByte(35)
      ..write(obj.location)
      ..writeByte(36)
      ..write(obj.imageUrl)
      ..writeByte(37)
      ..write(obj.customFields)
      ..writeByte(38)
      ..write(obj.warranty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemTypeAdapter extends TypeAdapter<ItemType> {
  @override
  final int typeId = 0;

  @override
  ItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemType.laptop;
      case 1:
        return ItemType.keyboard;
      case 2:
        return ItemType.monitor;
      case 3:
        return ItemType.tablet;
      case 4:
        return ItemType.webcam;
      case 5:
        return ItemType.furniture;
      case 6:
        return ItemType.other;
      default:
        return ItemType.laptop;
    }
  }

  @override
  void write(BinaryWriter writer, ItemType obj) {
    switch (obj) {
      case ItemType.laptop:
        writer.writeByte(0);
        break;
      case ItemType.keyboard:
        writer.writeByte(1);
        break;
      case ItemType.monitor:
        writer.writeByte(2);
        break;
      case ItemType.tablet:
        writer.writeByte(3);
        break;
      case ItemType.webcam:
        writer.writeByte(4);
        break;
      case ItemType.furniture:
        writer.writeByte(5);
        break;
      case ItemType.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
