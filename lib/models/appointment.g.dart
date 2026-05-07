// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentAdapter extends TypeAdapter<Appointment> {
  @override
  final int typeId = 2;

  @override
  Appointment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Appointment(
      clinicName: fields[0] as String,
      doctorName: fields[1] as String,
      date: fields[2] as String,
      time: fields[3] as String,
      petName: fields[4] as String,
      status: fields[5] as String,
      type: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Appointment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.clinicName)
      ..writeByte(1)
      ..write(obj.doctorName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.petName)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
