import 'package:hive/hive.dart';

part 'pet.g.dart'; // this will be auto-generated

@HiveType(typeId: 0)
class Pet extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String emoji;

  @HiveField(2)
  String breed;

  @HiveField(3)
  String ageGender;

  @HiveField(4)
  String birthdate;

  @HiveField(5)
  String weight;

  @HiveField(6)
  String status;

  @HiveField(7)
  String lastCheckup;

  @HiveField(8)
  String nextVax;

  @HiveField(9)
  String activity1;

  @HiveField(10)
  String activity2;

  Pet({
    required this.name,
    required this.emoji,
    required this.breed,
    required this.ageGender,
    required this.birthdate,
    required this.weight,
    required this.status,
    required this.lastCheckup,
    required this.nextVax,
    required this.activity1,
    required this.activity2,
  });
}
