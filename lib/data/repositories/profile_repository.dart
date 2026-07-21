import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/profile.dart';

/// SQL access for the local profile: the single profile row, the dated
/// measurement history, and per-metric targets.
class ProfileRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Returns the profile row, creating the default one on first access.
  Future<Profile> getProfile() async {
    final db = await _db;
    final rows = await db.query('profile', where: 'id = 1');
    if (rows.isEmpty) {
      await db.insert('profile', {'id': 1});
      return const Profile(name: '');
    }
    return Profile.fromMap(rows.first);
  }

  Future<void> updateProfile({
    required String name,
    String? birthDate,
    double? heightCm,
    required String units,
  }) async {
    final db = await _db;
    await getProfile(); // ensure the row exists
    await db.update(
      'profile',
      {
        'name': name.trim(),
        'birth_date': birthDate,
        'height_cm': heightCm,
        'units': units,
      },
      where: 'id = 1',
    );
  }

  Future<void> setUnits(String units) async {
    final db = await _db;
    await getProfile();
    await db.update('profile', {'units': units}, where: 'id = 1');
  }

  Future<void> setLanguage(String language) async {
    final db = await _db;
    await getProfile();
    await db.update('profile', {'language': language}, where: 'id = 1');
  }

  Future<void> setTheme(String theme) async {
    final db = await _db;
    await getProfile();
    await db.update('profile', {'theme': theme}, where: 'id = 1');
  }

  /// Full history for one metric, newest first.
  Future<List<Measurement>> history(String metric) async {
    final db = await _db;
    final rows = await db.query(
      'measurements',
      where: 'metric = ?',
      whereArgs: [metric],
      orderBy: 'measured_on DESC, id DESC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  /// The newest entry per metric, in one query pass.
  Future<Map<String, Measurement>> latestByMetric() async {
    final db = await _db;
    final rows = await db.query(
      'measurements',
      orderBy: 'measured_on DESC, id DESC',
    );
    final result = <String, Measurement>{};
    for (final row in rows) {
      final m = Measurement.fromMap(row);
      result.putIfAbsent(m.metric, () => m);
    }
    return result;
  }

  Future<void> addMeasurement(String metric, double value, String measuredOn) async {
    final db = await _db;
    await db.insert('measurements', {
      'metric': metric,
      'value': value,
      'measured_on': measuredOn,
    });
  }

  Future<void> deleteMeasurement(int id) async {
    final db = await _db;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> targets() async {
    final db = await _db;
    final rows = await db.query('targets');
    return {
      for (final row in rows)
        row['metric'] as String: (row['value'] as num).toDouble(),
    };
  }

  Future<void> setTarget(String metric, double value) async {
    final db = await _db;
    await db.insert('targets', {
      'metric': metric,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearTarget(String metric) async {
    final db = await _db;
    await db.delete('targets', where: 'metric = ?', whereArgs: [metric]);
  }
}
