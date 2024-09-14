import 'package:hive/hive.dart';

part 'hive_save.g.dart';

@HiveType(typeId: 69)
class SaveAll {
  @HiveField(0)
  int anyInt = 0;

  @HiveField(1)
  String anyString = ' ';

  @HiveField(2)
  bool anyBool = true;

  @HiveField(3)
  double anyDouble = 0.0;
}
