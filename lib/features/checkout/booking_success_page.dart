import 'package:doora_app/main_shell.dart';
import 'package:flutter/material.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({
    super.key,
    required this.orderIds,
    required this.bookingDate,
    required this.bookingTime,
  });

  final List<String> orderIds;
  final String bookingDate;
  final String bookingTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final primary = cs.primary; // blue
    const bg = Color(0xFFF5F6FA); // light background
    const cardBg = Colors.white;
    const labelColor = Color(0xFF363A45); // dark text
    const subtleText = Color(0xFF7C828E); // light grey text

    final idText = orderIds.join(', ');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Check icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),

                // MAIN HEADING (color changed)
                Text(
                  'Booking Successful!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primary, // ⭐ blue heading
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  orderIds.length > 1
                      ? 'Your bookings have been created successfully.'
                      : 'Your booking has been created successfully.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subtleText,
                  ),
                ),
                const SizedBox(height: 24),

                // CARD WITH IDS + DATE/TIME
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking IDs (label color changed)
                      Text(
                        orderIds.length > 1 ? 'Booking IDs' : 'Booking ID',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: labelColor, // ⭐ dark grey
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        idText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primary, // ⭐ blue IDs
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (bookingDate.isNotEmpty || bookingTime.isNotEmpty)
                        Text(
                          'Scheduled for: $bookingDate at $bookingTime',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtleText,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'You will also receive confirmation on WhatsApp.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtleText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Go to My Bookings
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainShell(
                              initialIndex: 1), // ✅ 1 = My Bookings tab
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Go to My Bookings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to Home
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
