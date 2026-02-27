// lib/core/auth/auth_guard.dart
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:doora_app/features/auth/login_page.dart'; // ← ये path पक्का हो

class _AuthNavLock {
  static bool busy = false;
}

Future<void> requireLoginThen(
    BuildContext context, VoidCallback onAuthed) async {
  if (AuthService.instance.isLoggedIn) {
    onAuthed();
    return;
  }
  if (_AuthNavLock.busy) return;
  _AuthNavLock.busy = true;
  try {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginPage(), // ← class name must be LoginPage
        fullscreenDialog: true,
      ),
    );
    if ((ok ?? false) && AuthService.instance.isLoggedIn) {
      onAuthed();
    }
  } finally {
    _AuthNavLock.busy = false;
  }
}
