import '../database/database_helper.dart';
import '../models/game_session.dart';

class GameSessionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createSession(GameSession session) async {
    final db = await _dbHelper.database;
    return await db.insert('game_session', session.toJson());
  }

  Future<void> updateSessionEnd(int sessionId, DateTime endedAt, int correct, int wrong) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('''
      UPDATE game_session 
      SET ended_at = ?, correct_count = ?, wrong_count = ?, total_questions = ?
      WHERE id = ?
    ''', [
      endedAt.toIso8601String(),
      correct,
      wrong,
      correct + wrong,
      sessionId
    ]);
  }

  Future<List<GameSession>> getLastSessions(int childId, int limit) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'game_session',
      where: 'child_id = ? AND ended_at IS NOT NULL',
      whereArgs: [childId],
      orderBy: 'ended_at DESC',
      limit: limit,
    );
    return result.map((json) => GameSession.fromJson(json)).toList();
  }
}
