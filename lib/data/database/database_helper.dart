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
        ended_at TEXT,
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
    
    // Initial Seed Data
    // 1. Create Default Game: Math Race
    final gameId = await db.insert('game', {
      'code': 'MATH_RACE',
      'name': 'Matematik Yarışı',
      'description': 'Temel toplama ve çıkarma işlemleriyle yarış.',
      'is_active': 1,
    });

    // 2. Create Levels
    // Level 1: 0-10 Addition
    final level1Id = await db.insert('level', {
      'game_id': gameId,
      'min_value': 0,
      'max_value': 10,
      'digit_count': 1,
      'difficulty': 'EASY',
      'unlock_score': 0,
    });

    // Level 2: 0-20 Addition
    final level2Id = await db.insert('level', {
      'game_id': gameId,
      'min_value': 0,
      'max_value': 20,
      'digit_count': 2,
      'difficulty': 'NORMAL',
      'unlock_score': 50, // Needs 50 score to unlock
    });

    // Level 3: 0-20 Subtraction
    final level3Id = await db.insert('level', {
      'game_id': gameId,
      'min_value': 0,
      'max_value': 20,
      'digit_count': 2,
      'difficulty': 'NORMAL',
      'unlock_score': 100,
    });

    // 3. Create Question Rules
    // Rule for Level 1: Addition 0-10
    await db.insert('question_rule', {
      'level_id': level1Id,
      'operation': '+',
      'min_operand': 0,
      'max_operand': 10,
      'allow_negative': 0,
    });

    // Rule for Level 2: Addition 0-20
    await db.insert('question_rule', {
      'level_id': level2Id,
      'operation': '+',
      'min_operand': 0,
      'max_operand': 20,
      'allow_negative': 0,
    });

    // Rule for Level 3: Subtraction 0-20
    await db.insert('question_rule', {
      'level_id': level3Id,
      'operation': '-',
      'min_operand': 0,
      'max_operand': 20,
      'allow_negative': 0, // Result cannot be negative
    });

    // Parent Settings Default
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
