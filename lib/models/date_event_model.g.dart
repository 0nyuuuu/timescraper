// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DateEventModelAdapter extends TypeAdapter<DateEventModel> {
  @override
  final int typeId = 1;

  @override
  DateEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DateEventModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DateEventModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
