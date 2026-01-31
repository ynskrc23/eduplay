import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('eduplay.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // 0 or 1
    const foreignIdType = 'INTEGER NOT NULL';

    // 1. ChildProfile
    await db.execute('''
      CREATE TABLE child_profile ( 
        id $idType, 
        name $textType,
        age $intType,
        avatar_id $textType,
        current_level $intType,
        total_score $intType,
        created_at $textType
      )
    ''');

    // 2. Game
    await db.execute('''
      CREATE TABLE game ( 
        id $idType, 
        code $textType,
        name $textType,
        description $textType,
        is_active $boolType
      )
    ''');

    // 3. Level
    await db.execute('''
      CREATE TABLE level ( 
        id $idType, 
        game_id $foreignIdType,
        min_value $intType,
        max_value $intType,
        digit_count $intType,
        difficulty $textType,
        unlock_score $intType,
        FOREIGN KEY (game_id) REFERENCES game (id) ON DELETE CASCADE
      )
    ''');

    // 4. Question (Rules)
    await db.execute('''
      CREATE TABLE question_rule ( 
        id $idType, 
        level_id $foreignIdType,
        operation $textType,
        min_operand $intType,
        max_operand $intType,
        allow_negative $boolType,
        FOREIGN KEY (level_id) REFERENCES level (id) ON DELETE CASCADE
      )
    ''');

    // 5. GameSession
    await db.execute('''
      CREATE TABLE game_session ( 
        id $idType, 
        child_id $foreignIdType,
        game_id $foreignIdType,
        level_id $foreignIdType,
        started_at $textType,
        ended_at $textType,
        total_questions $intType,
        correct_count $intType,
        wrong_count $intType,
        FOREIGN KEY (child_id) REFERENCES child_profile (id) ON DELETE CASCADE,
        FOREIGN KEY (game_id) REFERENCES game (id) ON DELETE CASCADE,
        FOREIGN KEY (level_id) REFERENCES level (id) ON DELETE CASCADE
      )
    ''');

    // 6. AnswerLog
    await db.execute('''
      CREATE TABLE answer_log ( 
        id $idType, 
        session_id $foreignIdType,
        question_text $textType,
        given_answer $textType,
        correct_answer $textType,
        is_correct $boolType,
        response_time_ms $intType,
        FOREIGN KEY (session_id) REFERENCES game_session (id) ON DELETE CASCADE
      )
    ''');

    // 7. Achievement
    await db.execute('''
      CREATE TABLE achievement ( 
        id $idType, 
        code $textType,
        title $textType,
        description $textType,
        icon $textType
      )
    ''');

    // 8. ChildAchievement
    await db.execute('''
      CREATE TABLE child_achievement ( 
        id $idType, 
        child_id $foreignIdType,
        achievement_id $foreignIdType,
        earned_at $textType,
        FOREIGN KEY (child_id) REFERENCES child_profile (id) ON DELETE CASCADE,
        FOREIGN KEY (achievement_id) REFERENCES achievement (id) ON DELETE CASCADE
      )
    ''');

    // 9. DailyReward
    await db.execute('''
      CREATE TABLE daily_reward ( 
        id $idType, 
        child_id $foreignIdType,
        reward_date $textType,
        reward_type $textType,
        reward_value $intType,
        FOREIGN KEY (child_id) REFERENCES child_profile (id) ON DELETE CASCADE
      )
    ''');

    // 10. ParentSettings
    await db.execute('''
      CREATE TABLE parent_settings ( 
        id $idType, 
        max_daily_minutes $intType,
        notifications_enabled $boolType,
        ads_enabled $boolType,
        premium_active $boolType
      )
    ''');
    
    // Initial Seed Data (Optional - e.g. ParentSettings or basic Games)
    await db.insert('parent_settings', {
      'max_daily_minutes': 30,
      'notifications_enabled': 1,
      'ads_enabled': 1,
      'premium_active': 0,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
