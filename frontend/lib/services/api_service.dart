import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiBaseUrl = '$baseUrl';

  static bool _isTransientNetworkError(Object error) {
    return error is SocketException ||
        error is http.ClientException ||
        error.toString().contains('connection abort') ||
        error.toString().contains('Connection closed');
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
    const maxAttempts = 2;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
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

        final response =
            await request.send().timeout(const Duration(seconds: 45));
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          return User.fromJson(jsonDecode(responseBody));
        }

        throw Exception(jsonDecode(responseBody)['error'] ?? 'Registration failed');
      } catch (e) {
        final canRetry = attempt < maxAttempts && _isTransientNetworkError(e);
        if (canRetry) {
          await Future.delayed(const Duration(milliseconds: 1200));
          continue;
        }
        throw Exception('Registration error: $e');
      }
    }

    throw Exception('Registration failed');
  }

  // Login user
  static Future<User> loginUser({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Get all users
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Get users error: $e');
    }
  }

  // Get specific user
  static Future<User> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  // Get contacts for a user
  static Future<List<User>> getContacts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/contacts/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch contacts');
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
      final response = await http.post(
        Uri.parse('$apiBaseUrl/contacts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      final message =
          jsonDecode(response.body)['error'] ?? 'Add contact failed';
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
      final response = await http.put(
        Uri.parse('$apiBaseUrl/users/$userId/language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'language': language}),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      final message = jsonDecode(response.body)['error'] ?? 'Update failed';
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
