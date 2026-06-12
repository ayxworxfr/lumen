import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lumen/core/storage/hive_boxes.dart';
import 'package:lumen/shared/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterSecureStorage mock', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('write and read string roundtrip', () async {
      const storage = FlutterSecureStorage();
      await storage.write(
        key: StorageKeys.accessToken,
        value: 'test_access_token',
      );
      final result = await storage.read(key: StorageKeys.accessToken);
      expect(result, equals('test_access_token'));
    });

    test('overwrite existing key returns new value', () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: StorageKeys.accessToken, value: 'first_value');
      await storage.write(key: StorageKeys.accessToken, value: 'second_value');
      final result = await storage.read(key: StorageKeys.accessToken);
      expect(result, equals('second_value'));
    });

    test('delete removes key', () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: StorageKeys.accessToken, value: 'abc123');
      await storage.delete(key: StorageKeys.accessToken);
      final result = await storage.read(key: StorageKeys.accessToken);
      expect(result, isNull);
    });

    test('read missing key returns null', () async {
      const storage = FlutterSecureStorage();
      final result = await storage.read(key: 'nonexistent_key');
      expect(result, isNull);
    });

    test('refresh token roundtrip', () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: StorageKeys.refreshToken, value: 'refresh_xyz');
      final result = await storage.read(key: StorageKeys.refreshToken);
      expect(result, equals('refresh_xyz'));
    });
  });

  group('SharedPreferences mock', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setString and getString roundtrip', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.language, 'zh');
      expect(prefs.getString(StorageKeys.language), equals('zh'));
    });

    test('setBool and getBool roundtrip', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.sessionActive, true);
      expect(prefs.getBool(StorageKeys.sessionActive), isTrue);
    });

    test('setBool false and getBool returns false', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.sessionActive, false);
      expect(prefs.getBool(StorageKeys.sessionActive), isFalse);
    });

    test('missing key returns null', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nonexistent'), isNull);
    });

    test('remove clears key', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.themeMode, 'dark');
      await prefs.remove(StorageKeys.themeMode);
      expect(prefs.getString(StorageKeys.themeMode), isNull);
    });

    test('containsKey reflects presence', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.isFirstLaunch, true);
      expect(prefs.containsKey(StorageKeys.isFirstLaunch), isTrue);
      expect(prefs.containsKey('missing_key'), isFalse);
    });

    test('initial mock values are pre-populated', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.themeMode: 'light',
        StorageKeys.sessionActive: false,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.themeMode), equals('light'));
      expect(prefs.getBool(StorageKeys.sessionActive), isFalse);
    });
  });

  group('HiveBox enum routing', () {
    late Directory tempDir;
    late Box<dynamic> userBox;
    late Box<dynamic> cacheBox;
    late Box<dynamic> settingsBox;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_storage_');
      Hive.init(tempDir.path);
      userBox = await Hive.openBox<dynamic>(StorageKeys.userBox);
      cacheBox = await Hive.openBox<dynamic>(StorageKeys.cacheBox);
      settingsBox = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    tearDown(() async {
      await userBox.clear();
      await cacheBox.clear();
      await settingsBox.clear();
    });

    test('HiveBox enum has exactly user/cache/settings values', () {
      expect(HiveBox.values.length, equals(3));
      expect(
        HiveBox.values,
        containsAll([HiveBox.user, HiveBox.cache, HiveBox.settings]),
      );
    });

    test('save to user box and retrieve from user box', () async {
      await userBox.put(StorageKeys.currentUser, 'user_data_value');
      final result = userBox.get(StorageKeys.currentUser);
      expect(result, equals('user_data_value'));
    });

    test('user box and cache box are isolated', () async {
      await userBox.put('shared_key', 'user_value');
      await cacheBox.put('shared_key', 'cache_value');

      expect(userBox.get('shared_key'), equals('user_value'));
      expect(cacheBox.get('shared_key'), equals('cache_value'));
    });

    test('delete from user box does not affect cache box', () async {
      await userBox.put('key1', 'value1');
      await cacheBox.put('key1', 'cache_value1');
      await userBox.delete('key1');

      expect(userBox.get('key1'), isNull);
      expect(cacheBox.get('key1'), equals('cache_value1'));
    });

    test('save and retrieve map value from cache box', () async {
      final data = {'name': 'Alice', 'age': 30};
      await cacheBox.put('user_map', data);
      final result = cacheBox.get('user_map');
      expect(result, equals(data));
    });

    test('save and retrieve from settings box', () async {
      await settingsBox.put('theme', 'dark');
      final result = settingsBox.get('theme');
      expect(result, equals('dark'));
    });

    test('user box name matches StorageKeys.userBox constant', () {
      expect(userBox.name, equals(StorageKeys.userBox));
    });

    test('cache box name matches StorageKeys.cacheBox constant', () {
      expect(cacheBox.name, equals(StorageKeys.cacheBox));
    });

    test('settings box name matches StorageKeys.settingsBox constant', () {
      expect(settingsBox.name, equals(StorageKeys.settingsBox));
    });
  });
}
