import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiBaseUrl = '$baseUrl';
  static const Duration _requestTimeout = Duration(seconds: 45);
  static const int _maxAttempts = 3;
  static const Set<int> _retryableStatusCodes = {
    408,
    429,
    500,
    502,
    503,
    504,
  };

  static bool _isTransientNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error.toString().toLowerCase().contains('connection abort') ||
        error.toString().toLowerCase().contains('connection closed') ||
        error.toString().toLowerCase().contains('timed out');
  }

  static Duration _retryDelay(int attempt) {
    // Small exponential backoff to absorb Render wake-up latency.
    return Duration(milliseconds: 1200 * attempt);
  }

  static String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Non-JSON response body.
    }
    return fallback;
  }

  static Future<http.Response> _sendWithRetry({
    required Future<http.Response> Function() send,
    required String operation,
  }) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await send().timeout(_requestTimeout);
        final shouldRetry =
            _retryableStatusCodes.contains(response.statusCode) &&
            attempt < _maxAttempts;

        if (shouldRetry) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }

        return response;
      } catch (e) {
        final canRetry = attempt < _maxAttempts && _isTransientNetworkError(e);
        if (canRetry) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }
        throw Exception('$operation error: $e');
      }
    }

    throw Exception('$operation failed');
  }

  static Future<({int statusCode, String body})> _sendMultipartWithRetry({
    required Future<http.MultipartRequest> Function() buildRequest,
    required String operation,
  }) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final request = await buildRequest();
        final streamed = await request.send().timeout(_requestTimeout);
        final body = await streamed.stream.bytesToString();
        final shouldRetry =
            _retryableStatusCodes.contains(streamed.statusCode) &&
            attempt < _maxAttempts;

        if (shouldRetry) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }

        return (statusCode: streamed.statusCode, body: body);
      } catch (e) {
        final canRetry = attempt < _maxAttempts && _isTransientNetworkError(e);
        if (canRetry) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }
        throw Exception('$operation error: $e');
      }
    }

    throw Exception('$operation failed');
  }

  // Register user
  static Future<User> registerUser({
    required String username,
    required String email,
    required String password,
    required String? birthDate,
    required String? gender,
    required String? avatarPath,
    String? language,
  }) async {
    try {
      final result = await _sendMultipartWithRetry(
        operation: 'Registration',
        buildRequest: () async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$apiBaseUrl/register'),
          );

          request.fields['username'] = username;
          request.fields['email'] = email;
          request.fields['password'] = password;
          if (birthDate != null) request.fields['birthDate'] = birthDate;
          if (gender != null) request.fields['gender'] = gender;
          if (language != null) request.fields['language'] = language;

          if (avatarPath != null && avatarPath.isNotEmpty) {
            request.files.add(
              await http.MultipartFile.fromPath('avatar', avatarPath),
            );
          }

          return request;
        },
      );

      if (result.statusCode == 201) {
        return User.fromJson(jsonDecode(result.body));
      }

      throw Exception(_extractErrorMessage(result.body, 'Registration failed'));
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Login user
  static Future<User> loginUser({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _sendWithRetry(
        operation: 'Login',
        send: () => http.post(
          Uri.parse('$apiBaseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identifier': identifier,
            'password': password,
          }),
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body, 'Login failed'));
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Get all users
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await _sendWithRetry(
        operation: 'Get users',
        send: () => http.get(
          Uri.parse('$apiBaseUrl/users'),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(_extractErrorMessage(response.body, 'Failed to fetch users'));
      }
    } catch (e) {
      throw Exception('Get users error: $e');
    }
  }

  // Get specific user
  static Future<User> getUserById(int id) async {
    try {
      final response = await _sendWithRetry(
        operation: 'Get user',
        send: () => http.get(
          Uri.parse('$apiBaseUrl/users/$id'),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body, 'User not found'));
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  // Get contacts for a user
  static Future<List<User>> getContacts(int userId) async {
    try {
      final response = await _sendWithRetry(
        operation: 'Get contacts',
        send: () => http.get(
          Uri.parse('$apiBaseUrl/contacts/$userId'),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(_extractErrorMessage(response.body, 'Failed to fetch contacts'));
      }
    } catch (e) {
      throw Exception('Get contacts error: $e');
    }
  }

  // Add contact by username or email
  static Future<User> addContact({
    required int userId,
    required String query,
  }) async {
    try {
      final response = await _sendWithRetry(
        operation: 'Add contact',
        send: () => http.post(
          Uri.parse('$apiBaseUrl/contacts'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'query': query,
          }),
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      final message = _extractErrorMessage(response.body, 'Add contact failed');
      throw Exception(message);
    } catch (e) {
      throw Exception('Add contact error: $e');
    }
  }

  // Update user language
  static Future<User> updateUserLanguage({
    required int userId,
    required String language,
  }) async {
    try {
      final response = await _sendWithRetry(
        operation: 'Update language',
        send: () => http.put(
          Uri.parse('$apiBaseUrl/users/$userId/language'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'language': language}),
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      final message = _extractErrorMessage(response.body, 'Update failed');
      throw Exception(message);
    } catch (e) {
      throw Exception('Update language error: $e');
    }
  }

  // Get avatar URL
  static String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }
    return '$baseUrl$avatarPath';
  }
}
