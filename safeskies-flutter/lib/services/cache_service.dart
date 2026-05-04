import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:safeskies/models/forecast.dart';
import 'package:safeskies/models/alert.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  late Database _db;

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'safeskies.db');
    
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> setForecast(ForecastResponse forecast) async {
    await _db.insert(
      'cache',
      {
        'key': 'last_forecast',
        'value': jsonEncode(forecast.toJson()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ForecastResponse?> getForecast() async {
    try {
      final result = await _db.query(
        'cache',
        where: 'key = ?',
        whereArgs: ['last_forecast'],
      );

      if (result.isEmpty) return null;

      final data = jsonDecode(result.first['value'] as String) as Map<String, dynamic>;
      return ForecastResponse.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> setAlerts(AlertsResponse alerts) async {
    await _db.insert(
      'cache',
      {
        'key': 'active_alerts',
        'value': jsonEncode(alerts.toJson()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AlertsResponse?> getAlerts() async {
    try {
      final result = await _db.query(
        'cache',
        where: 'key = ?',
        whereArgs: ['active_alerts'],
      );

      if (result.isEmpty) return null;

      final data = jsonDecode(result.first['value'] as String) as Map<String, dynamic>;
      return AlertsResponse.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getLastUpdated() async {
    try {
      final result = await _db.query(
        'cache',
        where: 'key = ?',
        whereArgs: ['last_updated_timestamp'],
      );

      if (result.isEmpty) return null;

      final timestamp = result.first['value'] as String;
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastUpdated() async {
    await _db.insert(
      'cache',
      {
        'key': 'last_updated_timestamp',
        'value': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isCacheExpired() async {
    final lastUpdated = await getLastUpdated();
    if (lastUpdated == null) return true;

    final hoursDiff = DateTime.now().difference(lastUpdated).inHours;
    return hoursDiff > 2;
  }

  Future<void> clearAll() async {
    await _db.delete('cache');
  }
}
