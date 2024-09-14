// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_save.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaveAllAdapter extends TypeAdapter<SaveAll> {
  @override
  final int typeId = 69;

  @override
  SaveAll read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaveAll()
      ..anyInt = fields[0] as int
      ..anyString = fields[1] as String
      ..anyBool = fields[2] as bool
      ..anyDouble = fields[3] as double;
  }

  @override
  void write(BinaryWriter writer, SaveAll obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.anyInt)
      ..writeByte(1)
      ..write(obj.anyString)
      ..writeByte(2)
      ..write(obj.anyBool)
      ..writeByte(3)
      ..write(obj.anyDouble);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveAllAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
