// lib/features/auth/account_page.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:doora_app/core/auth/auth_service.dart';
import 'package:doora_app/features/auth/login_page.dart';
import 'package:doora_app/features/bookings/my_bookings_page.dart';

// Same brand blue as login/register
const Color kBrandBlue = Color.fromARGB(255, 41, 109, 244);

class AccountPage extends StatefulWidget {
  final VoidCallback?
      onGoToBookings; // 🔹 MainShell se index change karne ke liye callback

  const AccountPage({
    super.key,
    this.onGoToBookings,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService auth = AuthService.instance;

  // 🔹 Account tab ke andar hi LoginPage dikhane ke liye flag
  bool _openLogin = false;

  @override
  void initState() {
    super.initState();
    auth.init(); // persistent login load
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        if (auth.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔹 Agar Login/Register se ya logout ke baad login kholna hai
        if (_openLogin) {
          return LoginPage(
            closeOnSuccess: false, // yahi tab ke andar rahega
            onLoginSuccess: () {
              if (!mounted) return;
              setState(() {
                _openLogin =
                    false; // login / register complete → normal account view
              });
            },
          );
        }

        if (!auth.isLoggedIn) {
          // ---------- LOGGED OUT VIEW ----------
          return Stack(
            children: [
              _buildHeader(
                title: 'Your Doorabag account',
                subtitle: 'Login to manage your bookings & profile.',
              ),
              _buildLoggedOutCard(theme),
            ],
          );
        }

        // ---------- LOGGED IN VIEW ----------
        return Stack(
          children: [
            _buildHeader(
              title: 'Hi, ${auth.userName ?? "there"} 👋',
              subtitle: 'Manage your profile, bookings & more.',
            ),
            _buildLoggedInCard(theme),
          ],
        );
      },
    );
  }

  // ---------------- HEADER (COMMON) ----------------

  Widget _buildHeader({
    required String title,
    required String subtitle,
  }) {
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
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
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
                  subtitle,
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

  // ---------------- LOGGED OUT CARD ----------------

  Widget _buildLoggedOutCard(ThemeData theme) {
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
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
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
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 72,
                        color: Color.fromARGB(255, 22, 10, 10),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome to Doorabag!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Login or create an account to view your bookings, warranty & more.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
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
                          onPressed: () {
                            // 🔹 Ab yahan se Account tab ke andar hi LoginPage khul jayega
                            setState(() {
                              _openLogin = true;
                            });
                          },
                          child: const Text(
                            'Login / Register',
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

  // ---------------- LOGGED IN CARD ----------------

  Widget _buildLoggedInCard(ThemeData theme) {
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
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
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
                      // Profile row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: kBrandBlue.withValues(alpha: 0.1),
                            child: Text(
                              (auth.userName?.isNotEmpty ?? false)
                                  ? auth.userName!.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.userName ?? 'User',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  auth.userMobile ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        const Color.fromARGB(255, 18, 11, 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),

                      // Options
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.article_outlined),
                        title: const Text('My Bookings'),
                        onTap: () {
                          // 🔹 Prefer: MainShell ka index change kare
                          if (widget.onGoToBookings != null) {
                            widget.onGoToBookings!();
                          } else {
                            // 🔹 Fallback: direct MyBookingsPage open (without bottom nav)
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyBookingsPage(),
                              ),
                            );
                          }
                        },
                      ),

                      // 🔹 Account details (edit name / number)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Account details'),
                        subtitle: const Text('Name & Mobile'),
                        onTap: _showEditAccountSheet,
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.policy_outlined),
                        title: const Text('Terms & Privacy'),
                        onTap: _showTermsSheet, // 🔹 Niche se glossy sheet
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (ctx) {
                                    return Center(
                                      child: Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.all(24),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 18, sigmaY: 18),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 20, 20, 16),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 20,
                                                    offset: Offset(0, 10),
                                                    color: Color(0x33000000),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.logout_rounded,
                                                    size: 40,
                                                    color: kBrandBlue,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Logout',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Are you sure you want to logout from this device?',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF4B5563),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx, false),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Color(
                                                                  0xFF4B5563),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: FilledButton(
                                                          style: FilledButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                kBrandBlue,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              vertical: 10,
                                                            ),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          14),
                                                            ),
                                                          ),
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx, true),
                                                          child: const Text(
                                                            'Logout',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
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
                                      ),
                                    );
                                  },
                                ) ??
                                false;

                            if (ok) {
                              await auth.logout();
                              if (!mounted) return;
                              setState(() {
                                // 🔹 Logout ke turant baad LoginPage dikhao
                                _openLogin = true;
                              });
                            }
                          },
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

  // ---------------- EDIT ACCOUNT SHEET (BOTTOM) ----------------

  void _showEditAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return _EditAccountSheet(auth: auth);
      },
    );
  }

  // ---------------- TERMS & PRIVACY SHEET ----------------

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 24,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.privacy_tip_outlined,
                              color: kBrandBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Terms & Privacy',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1. Service Platform Only',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Doorabag ek online platform hai jo customers ko independent partner technicians se connect karta hai. Technicians apne aap me independent service providers hain. Kisi bhi kaam ki direct zimmedari technician/partner ki hogi, na ki Doorabag ki.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '2. Estimates, Payments & Refunds',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Technician pehle machine check karke aapko estimate batata hai.\n'
                                '• Aapki final approval ke baad hi repair ka kaam shuru hota hai.\n'
                                '• Online payment Doorabag ke payment gateway ke through liya ja sakta hai, lekin actual service ka zimma technician ka hota hai.\n'
                                '• Kisi bhi refund/dispute ke case me Doorabag sirf support / coordination provide karega. Final decision internal policy ke hisaab se hoga.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '3. Warranty & Revisit Policy',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Warranty sirf same issue par lagu hoti hai jo invoice me mentioned hai.\n'
                                '• Warranty period technician/partner ya brand policy ke hisaab se hota hai.\n'
                                '• Warranty claim sirf Doorabag app/website me "My Bookings" → "Claim Warranty" ke through raise karna hoga.\n'
                                '• Misuse, physical damage, voltage issue, third-party interference ya unauthorised repair warranty me cover nahi hote.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '4. Cancellation & Reschedule',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Technician assign hone ke baad last moment cancellation ya frequent reschedule ke case me visit charge lag sakta hai.\n'
                                '• Exact charges city aur category wise Doorabag policy ke hisaab se alag ho sakte hain.\n'
                                '• Technician agar location, safety, ya behaviour ke basis par service deny kare to us case me Doorabag ka decision final hoga.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '5. Data & Privacy',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Aapka naam, mobile number, address aur booking details sirf service provide karne ke liye use kiye jaate hain.\n'
                                '• Doorabag aapka data kisi third-party ko sell nahi karta. Limited sharing sirf payment gateway, SMS/WhatsApp provider ya technician/partner ke saath hoti hai, jo service ke liye zaruri hai.\n'
                                '• App ya website use karte waqt aap in policies se sehmat hote hain.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '6. Limitation of Liability',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Doorabag kisi indirect, incidental ya consequential loss ke liye zimmedar nahi hoga. Hum hamesha reasonable support dene ki koshish karte hain, lekin kisi bhi damage, delay ya loss ke liye maximum liability limited rahegi aur case-to-case basis par decide hogi.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '7. Contact & Support',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Kisi bhi complaint, feedback ya clarification ke liye aap Doorabag app/website me Help & Support section se humse contact kar sakte hain.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Doorabag app/website ka istemaal karte hi aap in Terms & Privacy se sehmat maane jaate hain.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------------- EDIT ACCOUNT SHEET WIDGET ----------------

class _EditAccountSheet extends StatefulWidget {
  final AuthService auth;

  const _EditAccountSheet({required this.auth});

  @override
  State<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends State<_EditAccountSheet> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.auth.userName ?? '');
    _mobileController =
        TextEditingController(text: widget.auth.userMobile ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await widget.auth.updateProfile(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(
        context); // sheet close, AccountPage auto-refresh via AnimatedBuilder
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: kBrandBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Account details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic info',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Name required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'Mobile number',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Mobile required';
                                if (t.length != 10) {
                                  return 'Enter 10-digit mobile';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: kBrandBlue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Save changes',
                                        style: TextStyle(
                                          fontSize: 15,
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
          ),
        );
      },
    );
  }
}
