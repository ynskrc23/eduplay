import '../database/database_helper.dart';
import '../models/game.dart';
import '../models/level.dart';
import '../models/question_rule.dart';

class GameRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Game?> getGameByCode(String code) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'game',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (result.isNotEmpty) {
      return Game.fromJson(result.first);
    }
    return null;
  }

  Future<List<Level>> getLevelsByGameId(int gameId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'level',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'unlock_score ASC',
    );
    return result.map((json) => Level.fromJson(json)).toList();
  }

  Future<List<QuestionRule>> getRulesByLevelId(int levelId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'question_rule',
      where: 'level_id = ?',
      whereArgs: [levelId],
    );
    return result.map((json) => QuestionRule.fromJson(json)).toList();
  }
}
