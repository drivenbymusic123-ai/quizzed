import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'db_service.dart';

/// Central point that decides whether to use the online API or the local DB
/// based on current connectivity.
class DataService {
  final AuthService _auth;
  final ApiService _api;
  final DbService _db;

  DataService(this._auth, this._api, this._db);

  // Existing getQuiz unchanged

  final AuthService _auth;
  final ApiService _api;
  final DbService _db;

  DataService(this._auth, this._api, this._db);

  /// Returns the quiz matching the supplied secret [code].
  ///
  /// * If the device is **online**, the code is looked up on the server.
  /// * If the device is **offline**, the code is looked up locally.
  Future<Map<String, dynamic>?> getQuiz(String code) async {
    var connectivity = await Connectivity().checkConnectivity();
    bool isOnline = connectivity != ConnectivityResult.none;
    if (isOnline) {
      // Online path – retrieve from remote server
      return await _api.fetchQuizByCode(code);
    } else {
      // Offline path – retrieve from local DB (offline‑created quizzes)
      return await _db.getQuizByCode(code);
    }
  }

  /// Uploads any pending local changes (users, quizzes, answers) when
  /// connectivity becomes available.
  Future<void> syncPendingChanges() async {
    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    // 1️⃣ Sync pending users (offline sign‑up)
    final pendingUsers = await _db.getPendingUsers();
    for (final user in pendingUsers) {
      final token = await _api.signUp(user['email'], user['password'], user['display_name']);
      if (token != null) {
        await _db.markUserSynced(user['id'], token);
      }
    }
    // 2️⃣ Sync pending quizzes, answers … (not fully implemented here)
    // TODO: implement bulk sync for quizzes/answers when needed.
  }
}
