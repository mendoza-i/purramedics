// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetAdapter extends TypeAdapter<Pet> {
  @override
  final int typeId = 0;

  @override
  Pet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pet(
      name: fields[0] as String,
      emoji: fields[1] as String,
      breed: fields[2] as String,
      ageGender: fields[3] as String,
      birthdate: fields[4] as String,
      weight: fields[5] as String,
      status: fields[6] as String,
      lastCheckup: fields[7] as String,
      nextVax: fields[8] as String,
      activity1: fields[9] as String,
      activity2: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Pet obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.emoji)
      ..writeByte(2)
      ..write(obj.breed)
      ..writeByte(3)
      ..write(obj.ageGender)
      ..writeByte(4)
      ..write(obj.birthdate)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastCheckup)
      ..writeByte(8)
      ..write(obj.nextVax)
      ..writeByte(9)
      ..write(obj.activity1)
      ..writeByte(10)
      ..write(obj.activity2);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
