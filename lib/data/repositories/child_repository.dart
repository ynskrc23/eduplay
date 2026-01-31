import 'package:sqflite/sqflite.dart';
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
}
