// lib/features/auth/register_page.dart
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doora_app/core/auth/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔹 FCM token sync

const Color kBrandBlue = Color.fromARGB(255, 41, 109, 244);

/// 🔹 Helper: FCM token ko server par save kare (users.fcm_token)
Future<void> syncFcmTokenToServer(String mobile) async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    final uri = Uri.parse('https://www.doorabag.in/api/save_fcm_token.php');
    final res = await http.post(uri, body: {
      'mobile': mobile,
      'fcm_token': fcmToken,
    });

    debugPrint(
        'syncFcmTokenToServer (register $mobile) => ${res.statusCode} ${res.body}');
  } catch (e, st) {
    debugPrint('syncFcmTokenToServer (register) error: $e\n$st');
  }
}

class RegisterPage extends StatefulWidget {
  final String mobile;
  final bool closeOnSuccess;
  final VoidCallback? onRegisterSuccess;

  const RegisterPage({
    super.key,
    required this.mobile,
    this.closeOnSuccess = true,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  bool _loading = false;

  Future<void> _onSubmit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uri = Uri.parse('https://www.doorabag.in/api/save_fcm_token.php');
      final resp = await http.post(uri, body: {
        'name': _name.text.trim(),
        'mobile': widget.mobile,
        'email': _email.text.trim(),
        'city': _city.text.trim(),
      }).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        throw Exception(data['message'] ?? 'Registration failed');
      }

      final user = data['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', data['token'] as String);
      await prefs.setString(
        'user_mobile',
        (user['mobile'] ?? '').toString(),
      );
      await prefs.setString(
        'user_name',
        (user['name'] ?? '').toString(),
      );
      await prefs.setInt(
        'user_id',
        user['id'] is int
            ? user['id'] as int
            : int.tryParse(user['id'].toString()) ?? 0,
      );

      await AuthService.instance.debugLogin();

      // 🔥 Registration successful → FCM token sync
      await syncFcmTokenToServer(widget.mobile);

      if (!mounted) return;

      if (widget.closeOnSuccess) {
        // Old flow: as standalone page
        Navigator.of(context).pop(true);
      } else {
        // Embedded in MainShell tab
        widget.onRegisterSuccess?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _buildCurvedHeader(context),
            _buildContentCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Container(
        height: 230,
        decoration: const BoxDecoration(
          color: kBrandBlue,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 4),
              color: Colors.black26,
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create your Doorabag account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aapka apna home service partner.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Just a few details and you are ready to book.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 160, 16, 32),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 10),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kBrandBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_iphone_rounded,
                              size: 16,
                              color: kBrandBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mobile: ${widget.mobile}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kBrandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Tell us about you',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We use this to personalise your experience.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Name
                      TextField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // City
                      TextField(
                        controller: _city,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'City (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: kBrandBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _loading ? null : _onSubmit,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
