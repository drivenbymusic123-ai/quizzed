import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quiz.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    // initialize
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'quiz_app.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE quizzes (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          isOnline INTEGER,
          liveSync INTEGER,
          timerEnabled INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE questions (
          quizId TEXT,
          idx INTEGER,
          questionText TEXT,
          type INTEGER,
          options TEXT,
          answer TEXT,
          PRIMARY KEY (quizId, idx)
        )
      ''');
    });
  }

  Future<void> insertQuiz(Quiz quiz) async {
    final db = await database;
    await db.insert('quizzes', {
      'id': quiz.id,
      'title': quiz.title,
      'description': quiz.description,
      'isOnline': quiz.isOnline ? 1 : 0,
      'liveSync': quiz.liveSync ? 1 : 0,
      'timerEnabled': 0, // not used now
    });
    for (int i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      await db.insert('questions', {
        'quizId': quiz.id,
        'idx': i,
        'questionText': q.questionText,
        'type': q.type.index,
        'options': q.options.join('||'),
        'answer': q.answer,
      });
    }
  }

  Future<Map<String, dynamic>?> getQuizByCode(String code) async {
    final db = await database;
    final quizMap = await db.query('quizzes', where: 'id = ?', whereArgs: [code]);
    if (quizMap.isEmpty) return null;
    final quizRow = quizMap.first;
    final qList = await db.query('questions', where: 'quizId = ?', whereArgs: [code], orderBy: 'idx');
    final questions = qList.map((row) => {
          'questionText': row['questionText'],
          'type': row['type'],
          'options': (row['options'] as String).split('||'),
          'answer': row['answer'],
        }).toList();
    return {
      'id': quizRow['id'],
      'title': quizRow['title'],
      'description': quizRow['description'],
      'isOnline': (quizRow['isOnline'] as int) == 1,
      'liveSync': (quizRow['liveSync'] as int) == 1,
      'questions': questions,
    };
  }

  // Stub methods for user sync – not used now but kept for compatibility
  Future<List<Map<String, dynamic>>> getPendingUsers() async => [];
  Future<void> markUserSynced(String userId, String token) async {}
}
