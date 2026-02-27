// lib/core/auth/auth_service.dart
//
// Central auth state for the app.
// - Uses SharedPreferences keys written by login_page.dart
//   * "api_token"
//   * "user_id"
//   * "user_name"
//   * "user_mobile"
// - Provides:
//   * init()       → app start pe saved login load
//   * debugLogin() → login_page se call, prefs se latest data load
//   * logout()    → manual logout

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _initialized = false;
  bool _loading = true;

  int? _userId;
  String? _userName;
  String? _userMobile;
  String? _apiToken;

  bool get isLoading => _loading;
  bool get isLoggedIn => _userId != null;

  int? get userId => _userId;
  String? get userName => _userName;
  String? get userMobile => _userMobile;
  String? get apiToken => _apiToken;

  // 👇 yeh naya method add karo
  Future<void> updateProfile({
    required String name,
    required String mobile,
  }) async {
    _userName = name;
    _userMobile = mobile;

    // persist in SharedPreferences (optional but useful)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName ?? '');
    await prefs.setString('user_mobile', _userMobile ?? '');

    notifyListeners();
  }

  /// App start / Account tab open hone par ek baar call karo.
  /// Example:
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     AuthService.instance.init();
  ///   }
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _loadFromPrefs(prefs);
    _loading = false;
    notifyListeners();
  }

  /// Tumhare login_page.dart me login success ke baad yeh call ho raha hai:
  ///
  ///   AuthService.instance.debugLogin();
  ///
  /// Wohi prefs se latest user data read karke memory me set karega.
  Future<void> debugLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromPrefs(prefs);
    _loading = false;
    notifyListeners();
  }

  /// SharedPreferences se fields load karne ka common helper
  void _loadFromPrefs(SharedPreferences prefs) {
    final storedId = prefs.getInt('user_id');

    if (storedId != null && storedId != 0) {
      _userId = storedId;
      _userName = prefs.getString('user_name') ?? '';
      _userMobile = prefs.getString('user_mobile') ?? '';
      _apiToken = prefs.getString('api_token');
    } else {
      _userId = null;
      _userName = null;
      _userMobile = null;
      _apiToken = null;
    }

    if (kDebugMode) {
      debugPrint(
          '[AuthService] loaded → id=$_userId, name=$_userName, mobile=$_userMobile');
    }
  }

  /// Manual logout (sirf jab user khud logout dabaye).
  /// - SharedPreferences se sab keys delete
  /// - In-memory state clear
  /// - listeners ko notify (UI refresh)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('api_token');

    _userId = null;
    _userName = null;
    _userMobile = null;
    _apiToken = null;

    if (kDebugMode) {
      debugPrint('[AuthService] logout → state cleared');
    }

    notifyListeners();
  }
}
