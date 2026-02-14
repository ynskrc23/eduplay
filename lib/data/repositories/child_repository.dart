import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/database_helper.dart';
import '../models/child_profile.dart';

class ChildRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ChildProfile> createProfile(ChildProfile profile) async {
    final db = await _dbHelper.database;
    final id = await db.insert('child_profile', profile.toJson());
    return ChildProfile(
      id: id,
      name: profile.name,
      age: profile.age,
      avatarId: profile.avatarId,
      currentLevel: profile.currentLevel,
      totalScore: profile.totalScore,
      createdAt: profile.createdAt,
    );
  }

  Future<List<ChildProfile>> getAllProfiles() async {
    final db = await _dbHelper.database;
    final result = await db.query('child_profile', orderBy: 'created_at DESC');
    return result.map((json) => ChildProfile.fromJson(json)).toList();
  }

  Future<ChildProfile?> getProfileById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'child_profile',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return ChildProfile.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<bool> hasAnyProfile() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM child_profile');
    int? count = Sqflite.firstIntValue(result);
    return count != null && count > 0;
  }

  Future<void> deleteDatabaseForDev() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'matematikoy.db');
    await deleteDatabase(path);
  }

  Future<void> updateScore(int childId, int scoreToAdd) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE child_profile SET total_score = total_score + ? WHERE id = ?',
      [scoreToAdd, childId],
    );
  }

  Future<void> updateLevel(int childId, int newLevelIndex) async {
    final db = await _dbHelper.database;
    await db.update(
      'child_profile',
      {'current_level': newLevelIndex},
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

}
