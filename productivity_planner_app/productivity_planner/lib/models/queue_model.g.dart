// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueueAdapter extends TypeAdapter<Queue> {
  @override
  final int typeId = 0;

  @override
  Queue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Queue(
      id: fields[0] as int?,
      name: fields[1] as String,
      isArchived: fields[2] as bool,
      isComplete: fields[3] as bool,
      orderModeIndex: fields[4] as int,
      description: fields[5] as String?,
      sortOrder: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Queue obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isArchived)
      ..writeByte(3)
      ..write(obj.isComplete)
      ..writeByte(4)
      ..write(obj.orderModeIndex)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
