import 'package:http/http.dart' as http;
import 'dart:convert';

/// Minimal API client for the online backend.
/// Adjust `baseUrl` to point to your deployed Node server.
class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Fetch a quiz by its secret **online** code.
  /// Returns the decoded JSON map or null on error.
  Future<Map<String, dynamic>?> fetchQuizByCode(String code) async {
    final uri = Uri.parse('$baseUrl/api/quizzes?code=$code');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sign‑up a pending offline user. Returns the JWT token on success.
  Future<String?> signUp(String email, String password, String displayName) async {
    final uri = Uri.parse('$baseUrl/api/auth/signup');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    try {
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
