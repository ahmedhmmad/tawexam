import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';
import '../errors/exceptions.dart';

class LocalStorageService {
  final Map<String, Box<dynamic>> _boxes = {};

  Future<void> init() async {
    await Hive.initFlutter();
    await openBoxes([
      StorageKeys.authBox,
      StorageKeys.examBox,
      StorageKeys.syncBox,
      StorageKeys.settingsBox,
    ]);
  }

  Future<void> openBoxes(List<String> names) async {
    for (final name in names) {
      _boxes[name] = await Hive.openBox<dynamic>(name);
    }
  }

  Future<T?> read<T>(String boxName, String key) async {
    final value = _box(boxName).get(key);
    if (value == null) return null;
    if (value is T) return value;
    throw StorageException('Invalid value type for key $key');
  }

  Future<void> write<T>(String boxName, String key, T value) {
    return _box(boxName).put(key, value);
  }

  Future<void> delete(String boxName, String key) {
    return _box(boxName).delete(key);
  }

  Future<void> clearBox(String boxName) {
    return _box(boxName).clear();
  }

  Box<dynamic> _box(String name) {
    final box = _boxes[name];
    if (box == null || !box.isOpen) {
      throw StorageException('Storage box $name is not open');
    }
    return box;
  }
}
