import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// IMPORT YOUR PAGES
import 'package:doora_app/features/home/presentation/home_page.dart';
import 'package:doora_app/features/bookings/my_bookings_page.dart';
import 'package:doora_app/features/help/help_page.dart';
import 'package:doora_app/features/auth/account_page.dart';
import 'package:doora_app/core/auth/auth_service.dart';
import 'package:doora_app/features/auth/login_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex; // ✅ ADD THIS

  @override
  State<MainShell> createState() => _MainShellState();
}

// 🔔 Simple model for notification
class AppNotification {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  AppNotification({
    required this.title,
    required this.body,
    required this.data,
  });
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomePage(),
    MyBookingsPage(),
    HelpPage(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _setupNotificationClickListener();
  }

  void _onTap(int i) {
    setState(() {
      _index = i;
    });
  }

  // ================== NOTIFICATION HANDLING ==================

  Future<void> _setupNotificationClickListener() async {
    final fbm = FirebaseMessaging.instance;

    final initialMessage = await fbm.getInitialMessage();
    if (initialMessage != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationMessage(initialMessage);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) return;
      _handleNotificationMessage(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      _handleNotificationMessage(message);
    });
  }

  void _handleNotificationMessage(RemoteMessage message) {
    final notif = message.notification;
    final title =
        notif?.title ?? message.data['title'] ?? 'Update from DooraBag';
    final body = notif?.body ?? message.data['body'] ?? '';

    final appNotification = AppNotification(
      title: title,
      body: body,
      data: message.data,
    );

    _showNotificationCard(appNotification);
  }

  // ================== GLOSSY NOTIFICATION CARD ==================

  void _showNotificationCard(AppNotification n) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        final orderId = n.data['order_id'] ?? n.data['booking_id'];
        final type = (n.data['type'] ?? '').toString().toLowerCase();

        final titleL = n.title.toLowerCase();
        final bodyL = n.body.toLowerCase();

        // Estimate detection (strong)
        final bool isEstimateNotification = type.contains('estimate') ||
            type == 'estimate' ||
            type == 'estimate_shared' ||
            titleL.contains('estimate') ||
            titleL.contains('estimation') ||
            bodyL.contains('estimate') ||
            bodyL.contains('estimation');

        // Booking-related detection
        final bool isBookingNotification =
            (orderId != null && orderId.toString().isNotEmpty) ||
                type.contains('booking') ||
                type.contains('order') ||
                titleL.contains('booking') ||
                titleL.contains('technician') ||
                bodyL.contains('booking') ||
                bodyL.contains('technician');

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFF0F4FF).withValues(alpha: 0.96),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Notification',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      n.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black.withValues(alpha: 0.80),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    if (orderId != null && orderId.toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Booking ID: $orderId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black.withValues(alpha: 0.60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.black.withValues(alpha: 0.70),
                          ),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),

                        // ================= VIEW ESTIMATE =================
                        if (isEstimateNotification && orderId != null)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E6FF2)
                                  .withValues(alpha: 0.95),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Estimate notification → My Bookings tab open
                              setState(() => _index = 1);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text(
                              'View Estimate',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )

                        // ================= CHECK MY BOOKINGS =================
                        else if (isBookingNotification)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E6FF2)
                                  .withValues(alpha: 0.95),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() => _index = 1);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text(
                              'Check My Bookings',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================== UI / NAVIGATION ==================

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final bool isLoggedIn = auth.isLoggedIn &&
        auth.apiToken != null &&
        (auth.userMobile ?? '').isNotEmpty;

    Widget bookingsScreen = isLoggedIn
        ? _screens[1]
        : LoginPage(
            closeOnSuccess: false,
            onLoginSuccess: () => setState(() {}),
          );

    final List<Widget> screens = [
      _screens[0],
      bookingsScreen,
      _screens[2],
      AccountPage(
        onGoToBookings: () => setState(() => _index = 1),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF2E6FF2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                active: _index == 0,
                onTap: _onTap,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
              ),
              _NavItem(
                index: 1,
                icon: Icons.shopping_bag_outlined,
                label: 'My Bookings',
                active: _index == 1,
                onTap: _onTap,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
              ),
              _NavItem(
                index: 2,
                icon: Icons.help_outline,
                label: 'Help',
                active: _index == 2,
                onTap: _onTap,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
              ),
              _NavItem(
                index: 3,
                icon: Icons.person_outline,
                label: 'Account',
                active: _index == 3,
                onTap: _onTap,
                activeColor: Colors.white,
                inactiveColor: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- SINGLE NAV ITEM ----------------

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool active;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: active ? 24 : 22,
                color: active ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? activeColor : inactiveColor,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
