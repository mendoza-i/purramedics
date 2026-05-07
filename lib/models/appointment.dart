import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 2)
class Appointment extends HiveObject {
  @HiveField(0)
  late String clinicName;

  @HiveField(1)
  late String doctorName;

  @HiveField(2)
  late String date; // Format: "Feb 14, 2026"

  @HiveField(3)
  late String time; // Format: "10:00 AM"

  @HiveField(4)
  late String petName;

  @HiveField(5)
  late String status; // "Confirmed", "Pending", "Completed"

  @HiveField(6)
  late String type; // "Checkup", "Vaccine", "Surgery", "Other"

  Appointment({
    required this.clinicName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.petName,
    required this.status,
    required this.type,
  });
}
