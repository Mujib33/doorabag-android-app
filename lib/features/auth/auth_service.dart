// lib/features/auth/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'https://www.doorabag.in'; // apna domain

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _initialized = false;
  bool _loading = true;

  int? userId;
  String? name;
  String? mobile;
  String? token;

  bool get isLoading => _loading;
  bool get isLoggedIn => userId != null;

  /// App start / Account page open pe call karo
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    name = prefs.getString('user_name');
    mobile = prefs.getString('user_mobile');
    token = prefs.getString('auth_token');
    _loading = false;
    notifyListeners();
  }

  /// LOGIN – returns true if success
  Future<bool> login(String mobileInput, String password) async {
    final uri = Uri.parse('$kBaseUrl/app/login.php');

    final res = await http.post(uri, body: {
      'mobile': mobileInput,
      'password': password,
    });

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    final user = data['user'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();

    userId = user['id'] is int
        ? user['id'] as int
        : int.tryParse(user['id'].toString());
    name = user['name']?.toString();
    mobile = user['mobile']?.toString();
    token = data['token']?.toString(); // optional

    await prefs.setInt('user_id', userId ?? 0);
    await prefs.setString('user_name', name ?? '');
    await prefs.setString('user_mobile', mobile ?? '');
    if (token != null) {
      await prefs.setString('auth_token', token!);
    }

    notifyListeners();
    return true;
  }

  /// REGISTER – optional, same JSON style
  Future<bool> register({
    required String nameInput,
    required String mobileInput,
    required String password,
  }) async {
    final uri = Uri.parse('$kBaseUrl/app/register.php');

    final res = await http.post(uri, body: {
      'name': nameInput,
      'mobile': mobileInput,
      'password': password,
    });

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Register failed');
    }

    // Register ke baad auto-login:
    final user = data['user'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();

    userId = user['id'] is int
        ? user['id'] as int
        : int.tryParse(user['id'].toString());
    name = user['name']?.toString();
    mobile = user['mobile']?.toString();
    token = data['token']?.toString();

    await prefs.setInt('user_id', userId ?? 0);
    await prefs.setString('user_name', name ?? '');
    await prefs.setString('user_mobile', mobile ?? '');
    if (token != null) {
      await prefs.setString('auth_token', token!);
    }

    notifyListeners();
    return true;
  }

  /// LOGOUT – manual only (jab user khud press kare)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('auth_token');

    userId = null;
    name = null;
    mobile = null;
    token = null;
    notifyListeners();
  }
}
