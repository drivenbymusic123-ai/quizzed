import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static Database? _db;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'quiz_app.db');
    // Use a fixed passphrase or generate one per user; here we use a simple static key for demo.
    const passphrase = 'quiz_app_secret_key';
    _db = await openDatabase(path,
        password: passphrase,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              display_name TEXT,
              created_at TEXT NOT NULL
            );
          ''');
        });
  }

  Future<bool> login(String email, String password) async {
    final db = _db;
    if (db == null) return false;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isEmpty) return false;
    final row = res.first;
    final storedHash = row['password_hash'] as String;
    final inputHash = _hashPassword(password);
    if (storedHash != inputHash) return false;
    // Store a simple token (could be JWT from server later)
    await _storage.write(key: 'auth_token', value: jsonEncode({'userId': row['id']}));
    return true;
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    final db = _db;
    if (db == null) return false;
    final passwordHash = _hashPassword(password);
    final now = DateTime.now().toIso8601String();
    try {
      final id = await db.insert('users', {
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'created_at': now,
      });
      await _storage.write(key: 'auth_token', value: jsonEncode({'userId': id}));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<int?> getCurrentUserId() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;
    final data = jsonDecode(token) as Map<String, dynamic>;
    return data['userId'] as int?;
  }

  String _hashPassword(String password) {
    // Simple SHA256 hash; replace with bcrypt for production.
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
