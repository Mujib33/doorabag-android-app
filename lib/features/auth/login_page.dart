// lib/features/auth/login_page.dart
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // OTP
import 'package:firebase_messaging/firebase_messaging.dart'; // FCM

import 'package:doora_app/core/auth/auth_service.dart';

const Color kBrandBlue = Color.fromARGB(255, 41, 109, 244);

enum LoginOutcome { success, needsRegister, failed }

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
        'syncFcmTokenToServer ($mobile) => ${res.statusCode} ${res.body}');
  } catch (e, st) {
    debugPrint('syncFcmTokenToServer error: $e\n$st');
  }
}

class LoginPage extends StatefulWidget {
  final bool closeOnSuccess;
  final VoidCallback? onLoginSuccess;

  const LoginPage({
    super.key,
    this.closeOnSuccess = true,
    this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobile = TextEditingController();
  final _otpController = TextEditingController();

  // Register fields
  final _name = TextEditingController();
  final _city = TextEditingController();

  bool _loading = false;

  // OTP state
  bool _otpSent = false;
  String? _verificationId;

  // New user state → register form show kare
  bool _needsRegister = false;

  final FirebaseAuth _fbAuth = FirebaseAuth.instance;

  @override
  void dispose() {
    _mobile.dispose();
    _otpController.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  /* ---------------------------
   * 1) SERVER SYNC (login check)
   * --------------------------*/
  Future<LoginOutcome> _syncLoginToServer({
    required String mobile,
  }) async {
    final uri = Uri.parse('https://www.doorabag.in/api/app_login_sync.php');

    try {
      final resp = await http
          .post(
            uri,
            body: {'mobile': mobile},
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        debugPrint('HTTP ${resp.statusCode}: ${resp.body}');
        return LoginOutcome.failed;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('Non-JSON or malformed: ${resp.body}');
        return LoginOutcome.failed;
      }

      // Number not found -> register
      if (data['ok'] != true && data['needs_register'] == true) {
        return LoginOutcome.needsRegister;
      }

      if (data['ok'] != true || data['token'] == null || data['user'] == null) {
        debugPrint('Unexpected JSON: ${resp.body}');
        return LoginOutcome.failed;
      }

      final user = data['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', data['token'] as String);
      await prefs.setString(
        'user_mobile',
        (user['mobile'] ?? mobile).toString(),
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
      return LoginOutcome.success;
    } catch (e, st) {
      debugPrint('Login sync error: $e\n$st');
      return LoginOutcome.failed;
    }
  }

  /* ---------------------------
   * 2) Outcome handle
   * --------------------------*/
  Future<void> _handleOutcome(LoginOutcome outcome, String mobile) async {
    switch (outcome) {
      case LoginOutcome.success:
        // Login successful → FCM token sync
        await syncFcmTokenToServer(mobile);
        if (!mounted) return;

        // Wapas jaha se page open hua tha
        if (widget.closeOnSuccess) {
          Navigator.of(context, rootNavigator: true).pop(true);
        } else {
          widget.onLoginSuccess?.call();
        }
        break;

      case LoginOutcome.needsRegister:
        // New user → same page par register form show karo
        if (!mounted) return;
        setState(() {
          _needsRegister = true;
        });
        break;

      case LoginOutcome.failed:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
        break;
    }
  }

  /* ---------------------------
   * 3) Firebase ke baad server login
   * --------------------------*/
  Future<void> _completeLoginAfterFirebase(String mobile) async {
    final outcome = await _syncLoginToServer(mobile: mobile);
    await _handleOutcome(outcome, mobile);
  }

  /* ---------------------------
   * 4) OTP bhejna (Send OTP)
   * --------------------------*/
  Future<void> _sendOtp(String mobile) async {
    setState(() => _loading = true);

    try {
      await _fbAuth.verifyPhoneNumber(
        phoneNumber: '+91$mobile',
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _fbAuth.signInWithCredential(credential);
            await _completeLoginAfterFirebase(mobile);
          } catch (e) {
            debugPrint('verificationCompleted error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Auto verification failed. Try again.')),
              );
            }
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('verificationFailed: ${e.code} ${e.message}');
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Failed to send OTP'),
              ),
            );
          }
        },

        codeSent: (String verId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verId;
              _otpSent = true;
              _loading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to your mobile')),
            );
          }
        },

        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e, st) {
      debugPrint('sendOtp error: $e\n$st');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send OTP. Please retry.')),
        );
      }
    }
  }

  /* ---------------------------
   * 5) OTP verify + server login
   * --------------------------*/
  Future<void> _verifyOtpAndLogin(String mobile) async {
    final code = _otpController.text.trim();

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP you received')),
      );
      return;
    }
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP session expired. Please resend.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      await _fbAuth.signInWithCredential(credential);

      await _completeLoginAfterFirebase(mobile);
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyOtp error: ${e.code} ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Invalid OTP. Please try again.'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('verifyOtp generic error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------------------------
   * 6) Register submit (naya user)
   * --------------------------*/
  Future<void> _submitRegister(String mobile) async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uri =
          Uri.parse('https://www.doorabag.in/api/app_register_user.php');
      final resp = await http.post(uri, body: {
        'name': _name.text.trim(),
        'mobile': mobile,
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

      // FCM token sync for new user
      await syncFcmTokenToServer(mobile);

      if (!mounted) return;

      if (widget.closeOnSuccess) {
        Navigator.of(context, rootNavigator: true).pop(true);
      } else {
        widget.onLoginSuccess?.call();
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

  /* ---------------------------
   * 7) Continue button tap
   * --------------------------*/
  Future<void> _onContinue() async {
    final mobile = _mobile.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 10-digit valid mobile')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (_needsRegister) {
      // Already verified OTP & server ne bola new user hai
      await _submitRegister(mobile);
    } else if (!_otpSent) {
      // Step 1: Send OTP
      await _sendOtp(mobile);
    } else {
      // Step 2: Verify OTP + server login
      await _verifyOtpAndLogin(mobile);
    }
  }

  /* ---------------------------
   * UI
   * --------------------------*/
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

    final titleText =
        _needsRegister ? 'Create your Doorabag account' : 'Sign in to Doorabag';
    final bigTitle = _needsRegister
        ? 'Aapka apna home service partner.'
        : 'DooraBag Expert Care \nOn Your Doorstep.';
    final subText = _needsRegister
        ? 'Just a few details and you are ready to book.'
        : (_otpSent
            ? 'Enter the OTP received on your mobile.'
            : 'Create account or login in one step.\nNo password required.');

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
                  titleText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bigTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subText,
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
                  child: _needsRegister
                      ? _buildRegisterForm()
                      : _buildLoginForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Login + OTP UI
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kBrandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield_outlined, size: 16, color: kBrandBlue),
              SizedBox(width: 6),
              Text(
                'Secured by Doorabag',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kBrandBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Enter your mobile number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _otpSent
              ? 'We have sent an OTP on this number.'
              : 'We will send OTP on this number to verify your account.',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 18),

        // Mobile text field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              const Text(
                '+91',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  enabled: !_otpSent, // OTP ke baad lock
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '10-digit mobile number',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // OTP TextField
        if (_otpSent) ...[
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '6-digit OTP',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

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
            onPressed: _loading ? null : _onContinue,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _otpSent ? 'Verify & Continue' : 'Send OTP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'By continuing, you agree to Doorabag’s Terms & Privacy Policy.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 🔹 Register UI (name + city only)
  Widget _buildRegisterForm() {
    final mobile = _mobile.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mobile pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                'Mobile: $mobile',
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
        const Text(
          'We use this to personalise your experience.',
          style: TextStyle(
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
            onPressed: _loading ? null : _onContinue,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}
