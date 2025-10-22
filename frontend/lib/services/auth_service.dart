import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService({this.baseUrl = 'http://127.0.0.1:8000/api'});

  /// Register a new user
  Future<AuthResponse> register(RegisterRequest request) async {
    final uri = Uri.parse('$baseUrl/auth/register/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        
        // Save token and user data
        await _saveAuthData(authResponse.token, authResponse.user);
        
        return authResponse;
      } else {
        final error = json.decode(response.body);
        throw Exception(_formatError(error));
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    final uri = Uri.parse('$baseUrl/auth/login/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        
        // Save token and user data
        await _saveAuthData(authResponse.token, authResponse.user);
        
        return authResponse;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    final token = await getToken();
    
    if (token != null) {
      final uri = Uri.parse('$baseUrl/auth/logout/');
      
      try {
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );
      } catch (e) {
        // Continue with local logout even if API call fails
      }
    }
    
    // Clear local storage
    await clearAuthData();
  }

  /// Get user profile
  Future<User> getProfile() async {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/auth/profile/');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data);
        
        // Update stored user data
        await _storage.write(key: _userKey, value: json.encode(user.toJson()));
        
        return user;
      } else {
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  /// Change password
  Future<void> changePassword(ChangePasswordRequest request) async {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/auth/change-password/');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Password change failed');
      }
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  /// Get stored auth token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Get stored user data
  Future<User?> getStoredUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    
    try {
      final userData = json.decode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  /// Save auth data to secure storage
  Future<void> _saveAuthData(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: json.encode(user.toJson()));
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Format error messages from API
  String _formatError(dynamic error) {
    if (error is Map) {
      final messages = <String>[];
      error.forEach((key, value) {
        if (value is List) {
          messages.add('$key: ${value.join(', ')}');
        } else {
          messages.add('$key: $value');
        }
      });
      return messages.join('\n');
    }
    return error.toString();
  }
}
