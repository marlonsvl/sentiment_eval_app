import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'https://sentiment-eval-backend.onrender.com';
  static const _storage = FlutterSecureStorage();

  User? _currentUser;
  String? _token;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      _token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'user_data');

      if (_token != null && userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      print('Error loading stored auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'), // Match ApiService endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        // Store credentials securely
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(
          key: 'user_data',
          value: json.encode(data['user']),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint if available
      if (_token != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout/'), // Match ApiService endpoint
          headers: {
            'Authorization': 'Token $_token', // Match ApiService format
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _currentUser = null;
      _token = null;
      await _storage.deleteAll();
      notifyListeners();
    }
  }

  // This getter is now mainly for backward compatibility
  // The ApiService handles its own authentication
  Map<String, String> get authHeaders => {
    'Authorization': 'Token $_token', // Match ApiService format
    'Content-Type': 'application/json',
  };
}
