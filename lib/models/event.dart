import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 1) // Using typeId 1, assuming Pet is 0. Check Pet to be sure.
class Event extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late String location;

  @HiveField(2)
  late String date;

  @HiveField(3)
  late int colorValue; // Store color as int

  @HiveField(4)
  late String description;

  @HiveField(5)
  late String iconName; // e.g., 'vaccine', 'checkup'

  Event({
    required this.title,
    required this.location,
    required this.date,
    required this.colorValue,
    this.description = '',
    this.iconName = 'default',
  });
}
