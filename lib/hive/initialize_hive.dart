import 'package:hive_flutter/hive_flutter.dart';

import 'hive_save.dart';

class InitializeHive {
  static Future<void> init() async {
    await Hive.initFlutter();
    await registerAdapters();
    await openBox();
  }

  static Future<void> registerAdapters() async {
    Hive.registerAdapter(SaveAllAdapter());
  }

  static Future<void> openBox() async {
    await Hive.openBox<SaveAll>('save');
    await Hive.openBox<List<String>>('myList');
  }
}

class SaveHive {
  static Box<SaveAll> ve() => Hive.box<SaveAll>('save');

  static Box<List<String>> veList() => Hive.box<List<String>>('myList');

  static void ii(String key, int value) {
    SaveHive.ve().put(key, SaveAll()..anyInt = value);
  }

  static void ss(String key, String value) {
    SaveHive.ve().put(key, SaveAll()..anyString = value);
  }

  static void dd(String key, double value) {
    SaveHive.ve().put(key, SaveAll()..anyDouble = value);
  }

  static void bb(String key, bool value) {
    SaveHive.ve().put(key, SaveAll()..anyBool = value);
  }

  static void saveList(String key, List<String> value) {
    SaveHive.veList().put(key, value);
  }
}

class GetHive {
  static int ii(String key, int nullValue) {
    return SaveHive.ve().get(key)?.anyInt ?? nullValue;
  }

  static String ss(String key, String nullValue) {
    return SaveHive.ve().get(key)?.anyString ?? nullValue;
  }

  static String? ssOrNull(String key) {
    return SaveHive.ve().get(key)?.anyString;
  }

  static double dd(String key, double nullValue) {
    return SaveHive.ve().get(key)?.anyDouble ?? nullValue;
  }

  static bool bb(String key, bool nullValue) {
    return SaveHive.ve().get(key)?.anyBool ?? nullValue;
  }

  static List<String> list(String key) {
    return SaveHive.veList().get(key, defaultValue: []) ?? [];
  }
}
