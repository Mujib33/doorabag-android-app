// lib/features/bookings/my_bookings_page.dart
// My Bookings screen (Flutter) – glossy header + pro cards with Doorabag brand blue

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:doora_app/core/auth/auth_service.dart';
import 'package:doora_app/features/bookings/widgets/reschedule_sheet.dart';

const String kBaseUrl = 'https://www.doorabag.in'; // <- yahan apna domain
const Color kBrandBlue =
    Color(0xFF1f3b73); // ✅ SAME BRAND COLOR as Home/Cart/Bottom

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final Set<String> _estimateUpdating = {}; // ✅ prevents double tap

  Widget _searchingTechnicianBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            "Assigning technician for your booking",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        _SearchingTechCard(brandBlue: kBrandBlue),
      ],
    );
  }

  bool _loading = true;
  String? _error;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _initPage(); // 🔹 pehle auth load hone do, phir bookings lao
  }

  Widget _amountHeader(Booking b) {
    String amountText = "₹0";
    String subtitle = "";

    final status = b.status.toLowerCase().trim();
    final bool isCompleted =
        status == 'completed' || status.contains('completed');

    final int estimateAmt = b.estimateAmount ?? 0;
    final int orderPrice = b.price ?? 0;
    final String estStatus = (b.estimateStatus ?? '').toLowerCase();

    if (isCompleted) {
      // ✅ COMPLETED — show FINAL bill total:
      // 1) If server sent estimate_amount -> use it
      // 2) else if cartItems available -> compute (parts + labour + tax)
      // 3) else fallback -> totalPaid + tax

      int paid;

      final int est = b.estimateAmount ?? 0;

      if (est > 0) {
        paid = est;
      } else if (b.cartItems.isNotEmpty) {
        paid = computedEstimateTotal(b); // ✅ this matches Estimate card total
      } else {
        paid = (b.totalPaid ?? 0) + (b.taxAmount ?? 0);
      }

      amountText = "₹$paid";

      final pm = (b.paymentMode ?? "cash").toLowerCase();
      if (pm.contains("online")) {
        subtitle = "Paid online";
      } else if (pm.contains("upi")) {
        subtitle = "Paid via UPI";
      } else {
        subtitle = "Paid via Cash";
      }
    } else {
      // UPCOMING / RUNNING BOOKINGS
      final bool isEstimateAccepted = estStatus == 'accepted' ||
          estStatus == 'approved' ||
          estStatus == 'confirmed';

      final bool hasEstimate = estimateAmt > 0;

      if (hasEstimate && isEstimateAccepted) {
        final computed = computedEstimateTotal(b);
        amountText = "₹$computed";
        subtitle = "Total payable after service";
      } else {
        if (orderPrice > 0) {
          amountText = "₹$orderPrice";
        } else if (hasEstimate) {
          amountText = "₹$estimateAmt";
        } else {
          amountText = "₹0";
        }

        subtitle = "Payable after visit & diagnose if closed on visit charge";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      margin: const EdgeInsets.only(top: 6, bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF2F4F8).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827), // dark visible
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563), // grey-600
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ moved to top-level helper: computedEstimateTotal(Booking b)

  void _openBookAgainSheet(Booking b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _BookAgainSheet(
          service: b.service ?? '',
          onConfirm: (date, slot) async {
            final auth = AuthService.instance;

            if (!auth.isLoggedIn ||
                auth.apiToken == null ||
                (auth.userMobile ?? '').isEmpty) {
              if (mounted) {
                setState(() {
                  _estimateUpdating.remove(b.orderId);
                });
              }
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login again')),
              );
              return;
            }

            try {
              final uri = Uri.parse('$kBaseUrl/api/app_book_again.php');

              final res = await http.post(uri, body: {
                'api_token': auth.apiToken!, // optional - if PHP uses
                'mobile': auth.userMobile ?? '', // ✅ REQUIRED (mostly)
                'order_id': b.orderId, // ✅ REQUIRED
                'new_date': date, // ✅ REQUIRED
                'new_time': slot, // ✅ REQUIRED
              });

              if (!mounted) return;

              if (res.statusCode == 200) {
                final data = jsonDecode(res.body);

                if (data['success'] == true) {
                  Navigator.of(context).pop(); // sheet close

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (data['message'] ?? 'New booking created successfully')
                            .toString(),
                      ),
                    ),
                  );

                  await _fetchBookings(); // refresh list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (data['message'] ?? 'Unable to book again').toString(),
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Server error: HTTP ${res.statusCode.toString()}'),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to book again: $e'),
                ),
              );
            }
          },
        );
      },
    );
  }

  int _finalTotalAmount(Booking b) {
    final int est = b.estimateAmount ?? 0;

    // ✅ If estimateAmount exists, that's the final total
    if (est > 0) return est;

    // ✅ If cart available, compute parts + labour + tax
    if (b.cartItems.isNotEmpty) return computedEstimateTotal(b);

    // ✅ fallback
    final int subtotal = b.totalPaid ?? 0;
    final int tax = b.taxAmount ?? 0;
    return subtotal + tax;
  }

  // ---------------------------------------------------------------------------
  //  UC-STYLE RESCHEDULE SHEET (DATE + SLOT SELECTOR)
  // ---------------------------------------------------------------------------

  void _openRescheduleSheet(Booking b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return RescheduleSheet(
          booking: b,
          onConfirm: (newDate, newSlot) async {
            try {
              // 1) API URL
              final uri = Uri.parse('$kBaseUrl/api/app_reschedule.php');

              // 2) Request
              final res = await http.post(uri, body: {
                'api_token': AuthService.instance.apiToken,
                'order_id': b.orderId.toString(),
                'new_date': newDate,
                'new_time': newSlot,
              });

              if (!mounted) return;

              if (res.statusCode == 200) {
                final data = jsonDecode(res.body);

                if (data['success'] == true) {
                  // Bottom sheet band karo
                  Navigator.of(context).pop();

                  // Bookings dubara load karo (initState me jis function se laa rahe ho)
                  await _initPage(); // ← ye tumhare code me already hai

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (data['message'] ?? 'Booking rescheduled successfully')
                            .toString(),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (data['message'] ?? 'Unable to reschedule').toString(),
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server error while rescheduling'),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to reschedule: $e'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showCancelConfirmSheet(Booking b) async {
    final bool? yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFDFE),
                Color(0xFFF3F4F8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                // icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                // title
                const Text(
                  "Cancel this booking?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 8),

                // subtitle
                Text(
                  "Technician visit cancel ho jayega.\nAap chahe to baad me dobara book kar sakte hain.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 22),

                // buttons row
                Row(
                  children: [
                    // No button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          "No, Keep",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Yes button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: Colors.red.shade600,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: Colors.red.shade300,
                        ),
                        child: const Text(
                          "Yes, Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (yes == true) {
      await _cancelBooking(b);
    }
  }

  Future<void> _cancelBooking(Booking b) async {
    final url = Uri.parse("$kBaseUrl/api/app_cancel_booking.php");

    try {
      // ❌ b.orderId ?? ""  ->  ✅ b.orderId (non-null hai)
      final response = await http.post(url, body: {
        "order_id": b.orderId,
      });

      // ✅ async ke baad context use se pehle mounted check
      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error while cancelling')),
        );
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final ok = data['success'] == true;
      final msg = (data['message'] ?? 'Something went wrong').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      if (ok) {
        // list refresh
        await _fetchBookings();

        // phir se check, kyunki upar await hai
        if (!mounted) return;

        // bottom sheet band karo (agar khula ho)
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _callTechnician(String mobile) async {
    if (mobile.isEmpty) return;

    final uri = Uri.parse("tel:$mobile");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return; // ⭐ SAFE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to place the call")),
      );
    }
  }

  Future<void> _confirmAndClaimWarranty(Booking b) async {
    if (b.orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID missing, please contact support'),
        ),
      );
      return;
    }

    // 🔹 iOS-style bottom sheet confirmation (Yes / No)
    final bool? yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFDFE),
                Color(0xFFF3F4F8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // Blue glossy icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandBlue.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandBlue.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: kBrandBlue,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Claim Warranty?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Same problem ke liye free revisit booking create ho jayegi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        "No",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: kBrandBlue,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: kBrandBlue.withValues(alpha: 0.25),
                      ),
                      child: const Text(
                        "Yes, Claim",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    // User ne NO dabaya ya sheet close kar di
    if (yes != true) return;

    final auth = AuthService.instance;
    if (!auth.isLoggedIn ||
        auth.apiToken == null ||
        (auth.userMobile ?? '').isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/api/app_claim_warranty.php');
      final res = await http.post(uri, body: {
        'api_token': auth.apiToken!,
        'mobile': auth.userMobile ?? '',
        'order_id': b.orderId,
      });

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = data['success'] == true;
      final msg = (data['message'] ?? 'Server error').toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      if (ok) {
        // 🔹 1) Bookings list refresh
        await _fetchBookings();

        if (!mounted) return;

        // 🔹 2) View Details wali bottom sheet band karo
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateEstimateStatus(Booking b, String newStatus) async {
    // ✅ prevent double tap for same order
    if (_estimateUpdating.contains(b.orderId)) return;

    setState(() {
      _estimateUpdating.add(b.orderId);
    });
    final auth = AuthService.instance;

    if (!auth.isLoggedIn ||
        auth.apiToken == null ||
        (auth.userMobile ?? '').isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/api/app_update_estimate_status.php');
      final res = await http.post(uri, body: {
        'api_token': auth.apiToken!,
        'mobile': auth.userMobile ?? '',
        'order_id': b.orderId,
        'status': newStatus, // "Accepted" ya "Rejected"
      });

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = data['success'] == true;
      final msg = (data['message'] ?? 'Server error').toString();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      if (ok) {
        // List refresh
        await _fetchBookings();
        if (!mounted) return;
        // Details sheet band kar do taa ki naye status ke saath khul sake
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estimateUpdating.remove(b.orderId);
        });
      }
    }
  }

  Future<void> _initPage() async {
    final auth = AuthService.instance;

    // 🔸 AuthService ko thoda time do prefs se data load karne ka
    for (int i = 0; i < 15; i++) {
      if (!mounted) return;

      if (auth.isLoggedIn &&
          auth.apiToken != null &&
          (auth.userMobile ?? '').isNotEmpty) {
        // login data mil gaya → loop se bahar niklo
        break;
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    await _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;

    final auth = AuthService.instance;

    if (!auth.isLoggedIn ||
        auth.apiToken == null ||
        (auth.userMobile ?? '').isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please login to see your bookings';
        _bookings = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kBaseUrl/api/app_my_bookings.php');

      final res = await http.post(uri, body: {
        'api_token': auth.apiToken!,
        'mobile': auth.userMobile ?? '',
      });

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Unknown error from server');
      }

      final List list = data['bookings'] as List;
      final bookings = list.map((j) => Booking.fromJson(j)).toList();

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ignore: unused_element
  Future<void> _openInvoice(Booking b) async {
    if (b.orderId.isEmpty) return;
    final url =
        '$kBaseUrl/user/invoice.php?order_id=${Uri.encodeComponent(b.orderId)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

// ---------------------------------------------------------------------------
//   VIEW DETAILS SHEET  (compact + technician block for new bookings)
// ---------------------------------------------------------------------------

  void _showBookingDetails(Booking b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            final s = b.status.toLowerCase();
            final bool isUpcoming =
                s != 'completed' && s != 'cancelled'; // new / running bookings

            final bool hasTechInfo =
                (b.technicianName ?? '').trim().isNotEmpty ||
                    (b.technicianMobile ?? '').trim().isNotEmpty;

            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 55,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  // Amount + subtitle (compact)
                  _amountHeader(b),
                  const SizedBox(height: 14),

                  // Service + date/time
                  Container(
                    width: double.infinity, // ⭐ FULL WIDTH
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.service ?? "Service",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Date: ${b.bookingDate ?? '-'}   ·   Time: ${b.bookingTime ?? '-'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Technician UI (Upcoming bookings)
                  if (isUpcoming) ...[
                    const SizedBox(height: 12),
                    hasTechInfo
                        ? _technicianBlock(b)
                        : _searchingTechnicianBlock(),
                  ],

                  const SizedBox(height: 18),

                  // 🔹 Agar estimate_amount hai to iOS-style estimate card
                  if ((b.estimateAmount ?? 0) > 0) ...[
                    _estimateCard(b),
                    const SizedBox(height: 18),
                  ] else ...[
                    // Purana Job quote + payment summary sirf tab jab estimate nahi bana
                    if (b.cartItems.isNotEmpty) ...[
                      _partsList(b.cartItems),
                      const SizedBox(height: 18),
                    ],
                    _paymentSummary(b),
                  ],

                  const SizedBox(height: 18),
                  const Divider(height: 24),
                  const SizedBox(height: 6),

                  // ACTION BUTTONS (yahan se call technician button bhi hoga)
                  _actionButtons(b),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Glossy style, but pure brand blue
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E6FF2),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 8),
            color: Colors.black26,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title row center aligned
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 40), // left spacer
                Expanded(
                  child: Center(
                    child: Text(
                      'My Bookings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 40), // right spacer
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Track your Doorabag service history',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: _loading
          ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              children: const [
                SizedBox(height: 40),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _error != null
              ? ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Error: ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_error != null)
                      Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                )
              : _bookings.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 32),
                      children: [
                        const SizedBox(height: 24),
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.grey.shade500,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No bookings yet.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Start a new service from Home page.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        final svc = (b.service ?? '').trim();
                        final circleText =
                            svc.isNotEmpty ? svc[0].toUpperCase() : 'D';
                        final statusLower = b.status.toLowerCase();

                        final bool isCompletedZeroPaid =
                            (statusLower == 'completed' ||
                                    statusLower.contains('completed')) &&
                                (b.totalPaid ?? 0) == 0;

                        final bool isCancelledZeroPrice =
                            (statusLower == 'cancelled') && (b.price ?? 0) == 0;

                        final bool techNotAssigned =
                            (b.technicianName ?? '').trim().isEmpty &&
                                (b.technicianMobile ?? '').trim().isEmpty;

                        final bool isUpcomingBooking =
                            statusLower != 'completed' &&
                                statusLower != 'cancelled';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                                color: Color(0x15000000),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ROW 1 — Icon + Service + Status
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kBrandBlue,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        circleText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b.service ?? "Service",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Date: ${b.bookingDate ?? '-'}   ·   Time: ${b.bookingTime ?? '-'}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _StatusChip(status: b.status),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // ROW 2 — Price / Paid
                                if (b.status.toLowerCase() == "completed") ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Paid: ₹${_finalTotalAmount(b)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        color: Colors.grey.shade800,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ((b.estimateAmount ?? 0) > 0)
                                            ? "Estimate: ₹${computedEstimateTotal(b)}"
                                            : "Price: ₹${b.price ?? 0}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // 🔹 Searching technician card (list view)
                                if (isUpcomingBooking && techNotAssigned) ...[
                                  const SizedBox(height: 10),
                                  _SearchingTechCard(brandBlue: kBrandBlue),
                                ],

                                // ROW 3 — Buttons (View Details / Book Again + Claim)
// ❌ Hide buttons for:
//    1) Completed + paid 0
//    2) Cancelled + price 0
                                if (!isCompletedZeroPaid &&
                                    !isCancelledZeroPrice) ...[
                                  Row(
                                    children: [
                                      // ⭐ Primary button: Cancelled me "Book Again", otherwise "View Details"
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (statusLower ==
                                                  "cancelled")
                                              ? () => _openBookAgainSheet(b)
                                              : () => _showBookingDetails(b),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kBrandBlue,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            (statusLower == "cancelled")
                                                ? "Book Again"
                                                : "View Details",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // ⭐ Claim Warranty sirf jab warranty allowed ho
                                      if (b.canClaimWarranty &&
                                          statusLower != "cancelled")
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _confirmAndClaimWarranty(b),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              side: const BorderSide(
                                                  color: kBrandBlue),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Claim",
                                              style: TextStyle(
                                                color: kBrandBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _technicianBlock(Booking b) {
    final name = (b.technicianName ?? '').trim().isEmpty
        ? 'Technician assigned'
        : b.technicianName!.trim();

    final mobile = (b.technicianMobile ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ Heading
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            "Assigned technician for your booking",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563), // grey-700
            ),
          ),
        ),

        // Technician Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kBrandBlue.withValues(alpha: 0.08),
                child: Icon(
                  Icons.engineering,
                  color: kBrandBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Name + Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (mobile.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mobile,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Call Button
              if (mobile.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: InkWell(
                    onTap: () => _callTechnician(mobile),
                    child: Row(
                      children: [
                        Icon(Icons.call,
                            color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          "Call",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _estimateCard(Booking b) {
    final items = b.cartItems;

    final taxes = b.taxAmount ?? 0;

// ✅ Labour only once (from first item labour field)
    final labourTotal = items.isNotEmpty ? (items.first.labour) : 0;

// ✅ Final total: if server already sent estimate_amount, use it (single source of truth)
// Else compute from breakdown
    final totalEstimate = computedEstimateTotal(b);

    final statusRaw = (b.estimateStatus ?? '').trim();
    final statusLower = statusRaw.toLowerCase();
    final bool isPending = statusLower.isEmpty || statusLower == 'pending';
    final bool isBusy = _estimateUpdating.contains(b.orderId);

    Color statusBg;
    Color statusFg;

    if (isPending) {
      statusBg = Colors.orange.shade50;
      statusFg = Colors.orange.shade700;
    } else if (statusLower == 'accepted') {
      statusBg = Colors.green.shade50;
      statusFg = Colors.green.shade700;
    } else {
      statusBg = Colors.red.shade50;
      statusFg = Colors.red.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFE5EDFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row – title + status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Estimate details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusRaw.isEmpty ? 'Pending' : statusRaw,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Parts list
          if (items.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: items.map((it) {
                  final lineTotal = it.price * it.qty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    "Qty: ${it.qty}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (it.warrantyLabel.isNotEmpty)
                                    Text(
                                      it.warrantyLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹$lineTotal",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Text(
              "No parts added in estimate.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 🔹 Summary: Labour + Tax + Total (sirf ek-ek baar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Labour charges",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                "₹$labourTotal",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Taxes & Fees",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                "₹$taxes",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Estimate Amount",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                "₹$totalEstimate",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Accept / Reject buttons – sirf pending pe
          if (isPending) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateEstimateStatus(b, "Accepted"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isBusy ? "Please wait..." : "Accept",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateEstimateStatus(b, "Rejected"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isBusy ? "Please wait..." : "Reject",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //   ACTION BUTTONS IN DETAILS SHEET (iOS-style glossy)
  // ---------------------------------------------------------------------------
  Widget _actionButtons(Booking b) {
    final String mobile = (b.technicianMobile ?? '').trim();
    final String statusLower = b.status.toLowerCase();
    final bool isCancelled = statusLower == 'cancelled';
    final bool isUpcoming = statusLower != 'completed' && !isCancelled;

    final bool isCompleted =
        statusLower == 'completed' || statusLower.contains('completed');
    final int paidAmount = b.totalPaid ?? 0;

    // ✅ Rule: Completed booking + Paid = 0  → koi bhi button nahi
    if (isCompleted && paidAmount == 0) {
      return const SizedBox.shrink();
    }

    // ⭐ Estimate share ho chuka?
    final bool isEstimateShared = (b.estimateAmount ?? 0) > 0;

    return Column(
      children: [
        // 🔹 Call Technician — sirf upcoming + mobile available
        if (isUpcoming && mobile.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _callTechnician(mobile),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Text(
                "Call Technician",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Claim Warranty (sirf completed par)
        if (b.canClaimWarranty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => _confirmAndClaimWarranty(b),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Claim Warranty",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),

        // 🔸 Reschedule / Book Again button
        //
        //  - Agar status = Cancelled  → text: "Book Again" + fresh booking sheet
        //  - Agar estimate share ho gaya (NOT cancelled) → yeh button hide
        if (isCancelled || !isEstimateShared) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: isCancelled
                  // ⬇️ YAHI LINE TUM POOCH RAHE THE
                  ? () => _openBookAgainSheet(b)
                  : () => _openRescheduleSheet(b),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6FF2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: Colors.black45,
                elevation: 4,
              ),
              child: Text(
                isCancelled ? "Book Again" : "Reschedule",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],

// ⭐ BOOK AGAIN (completed + no warranty)
        if (statusLower == 'completed' && !b.canClaimWarranty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openBookAgainSheet(b),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Book Again",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ], // 🔸 Cancel Booking button
        //
        //  - Cancelled bookings par nahi dikhayenge
        //  - Estimate share hone ke baad bhi nahi dikhayenge
        if (!isCancelled && !isEstimateShared) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancelConfirmSheet(b),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Colors.red, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Cancel Booking",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // iOS light grey background (same as Home / Cart)
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          // Top brand blue background behind header
          Container(
            height: 170,
            color: const Color(0xFF2E6FF2),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//   BOOKING MODEL
// ---------------------------------------------------------------------------

class Booking {
  final int? id;
  final String? service;

  final String status;

  // these two should be mutable so reschedule can update
  String? bookingDate;
  String? bookingTime;

  // FIX: orderId only ONCE
  final String orderId;

  final String? technicianName;
  final String? technicianMobile;

  final int? totalPaid;
  final String? completionType;
  final String? billingDate;

  final int? price;
  final int? estimateAmount;
  final int? taxAmount;
  String? estimateStatus;

  final String? paymentId;

  // Payment mode
  final String? paymentMode;

  final List<CartItem> cartItems;

  Booking({
    required this.id,
    required this.service,
    required this.status,
    required this.bookingDate,
    required this.bookingTime,
    required this.orderId, // only once
    required this.technicianName,
    required this.technicianMobile,
    required this.totalPaid,
    required this.completionType,
    required this.billingDate,
    required this.price,
    required this.estimateAmount,
    required this.taxAmount,
    required this.estimateStatus,
    required this.paymentId,
    required this.paymentMode,
    required this.cartItems,
  });

  factory Booking.fromJson(Map<String, dynamic> j) {
    // CART PARSING
    List<CartItem> items = [];
    final raw = j['cart_data'];

    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          items = decoded
              .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (raw is List) {
        items = raw
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return Booking(
      id: _toInt(j['id']),
      service: j['service']?.toString(),
      status: j['status']?.toString() ?? '',
      bookingDate: j['booking_date']?.toString(),
      bookingTime: j['booking_time']?.toString(),
      orderId: (j['order_id'] ?? '').toString(), // ← ONLY HERE
      technicianName: j['technician_name']?.toString(),
      technicianMobile: j['technician_mobile']?.toString(),
      totalPaid: _toInt(j['total_paid']),
      completionType: j['completion_type']?.toString(),
      billingDate: j['billing_date']?.toString(),
      price: _toInt(j['price']),
      estimateAmount: _toInt(j['estimate_amount']),
      taxAmount: _toInt(j['tax_amount']),
      estimateStatus: j['estimate_status']?.toString(),
      paymentId: j['payment_id']?.toString(),
      paymentMode: j['payment_mode']?.toString(),
      cartItems: items,
    );
  }

  String get paidTag {
    if (completionType == null) return '';
    return completionType == 'billed' ? ' (Billed)' : ' (Visit Charge)';
  }

  // Warranty logic
  bool get canClaimWarranty {
    final s = status.toLowerCase().trim();

    final isCompleted = s == 'completed' || s.contains('completed');
    if (!isCompleted) return false;

    if (orderId.isEmpty) return false;
    if (cartItems.isEmpty) return false;

    final maxDays = _maxWarrantyDaysForBooking(this);
    if (maxDays <= 0) return false;

    if (billingDate == null || billingDate!.trim().isEmpty) return false;

    final billDt = _parseDateLoose(billingDate!);
    if (billDt == null) return true;

    final now = DateTime.now();
    final diffDays = now.difference(billDt).inDays;

    return diffDays <= maxDays;
  }
}

// ---------------------------------------------------------------------------
//   CART ITEM MODEL
// ---------------------------------------------------------------------------

class CartItem {
  final String name;
  final int qty;
  final int price;
  final int labour;
  final String warrantyLabel;

  CartItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.labour,
    required this.warrantyLabel,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) {
    return CartItem(
      name: j['name']?.toString() ?? '',
      qty: _toInt(j['qty']) ?? 1,
      price: _toInt(j['price']) ?? 0,
      labour: _toInt(j['labour']) ?? 0,
      warrantyLabel: j['warranty']?.toString() ?? '',
    );
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _parseDateLoose(String raw) {
  try {
    if (raw.contains(" ")) {
      final iso = raw.replaceFirst(" ", "T");
      return DateTime.parse(iso);
    } else {
      return DateTime.parse(raw);
    }
  } catch (_) {
    return null;
  }
}

int _warrantyToDays(String label) {
  label = label.toLowerCase().trim();

  if (label.isEmpty || label == 'no warranty' || label == 'no warrenty') {
    return 0;
  }

  final d1 = RegExp(r'(\d+)\s*day').firstMatch(label);
  if (d1 != null) return int.parse(d1.group(1)!);

  final m1 = RegExp(r'(\d+)\s*month').firstMatch(label);
  if (m1 != null) return int.parse(m1.group(1)!) * 30;

  final y1 = RegExp(r'(\d+)\s*year').firstMatch(label);
  if (y1 != null) return int.parse(y1.group(1)!) * 365;

  if (int.tryParse(label) != null) return int.parse(label);

  return 0;
}

int _maxWarrantyDaysForBooking(Booking b) {
  int maxDays = 0;
  for (final item in b.cartItems) {
    if (item.name.toLowerCase() == "labour charge") continue;

    final d = _warrantyToDays(item.warrantyLabel);
    if (d > maxDays) maxDays = d;
  }
  return maxDays;
}

// ---------------------------------------------------------------------------
//   STATUS CHIP UI
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bg() {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green.shade50;
      case "processing":
        return Colors.orange.shade50;
      case "cancelled":
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _fg() {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green.shade700;
      case "processing":
        return Colors.orange.shade700;
      case "cancelled":
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _fg(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//   PARTS TABLE (if needed in any other design)
// ---------------------------------------------------------------------------

// ignore: unused_element
class _PartsTable extends StatelessWidget {
  final List<CartItem> cartItems;
  const _PartsTable({required this.cartItems});

  @override
  Widget build(BuildContext context) {
    final rows = cartItems
        .where((it) => it.name.trim().isNotEmpty && it.name != 'Labour Charge')
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    bool labourAdded = false;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          const TableRow(
            children: [
              _CellWrapper(_HeaderCell('Part')),
              _CellWrapper(_HeaderCell('Qty')),
              _CellWrapper(_HeaderCell('Price')),
              _CellWrapper(_HeaderCell('Labour')),
              _CellWrapper(_HeaderCell('Warranty')),
            ],
          ),
          ...rows.map((item) {
            final showLabour = !labourAdded;
            if (showLabour) labourAdded = true;

            return TableRow(
              decoration: const BoxDecoration(),
              children: [
                _CellWrapper(_BodyCell(item.name)),
                _CellWrapper(_BodyCell(item.qty.toString())),
                _CellWrapper(_BodyCell('₹${item.price}')),
                _CellWrapper(_BodyCell(showLabour ? '₹${item.labour}' : '₹0')),
                _CellWrapper(_BodyCell(item.warrantyLabel.isEmpty
                    ? 'No Warranty'
                    : item.warrantyLabel)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CellWrapper extends StatelessWidget {
  final Widget child;
  const _CellWrapper(this.child);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: child,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      constraints: const BoxConstraints(
        minHeight: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  const _BodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      constraints: const BoxConstraints(
        minHeight: 32,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//   PARTS LIST + PAYMENT SUMMARY HELPERS
// ---------------------------------------------------------------------------

int computedEstimateTotal(Booking b) {
  final items = b.cartItems;
  final taxes = b.taxAmount ?? 0;

  // labour only once
  final labourTotal = items.isNotEmpty ? (items.first.labour) : 0;

  final partsTotal = items.where((it) {
    final n = it.name.toLowerCase().trim();
    return n != 'labour charge' &&
        n != 'labor charge' &&
        n != 'visit charge' &&
        n != 'diagnosis charge';
  }).fold<int>(0, (sum, it) => sum + (it.price * it.qty));

  if (items.isEmpty) return b.estimateAmount ?? 0;

  return partsTotal + labourTotal + taxes;
}

Widget _partsList(List<CartItem> items) {
  if (items.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Job quote",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: items.map((it) {
            final lineTotal = it.price * it.qty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Qty: ${it.qty}",
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹$lineTotal",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget _paymentSummary(Booking b) {
  final items = b.cartItems;

  final labour = items.isNotEmpty ? items[0].labour : 0;
  final taxes = b.taxAmount ?? 0;

  // ✅ Final total rule:
  // 1) estimateAmount exists => final (already includes tax)
  // 2) else totalPaid + tax
  final int total = (b.estimateAmount != null && b.estimateAmount! > 0)
      ? b.estimateAmount!
      : (items.isNotEmpty
          ? computedEstimateTotal(b)
          : ((b.totalPaid ?? 0) + taxes));

  // ✅ Payment mode display
  final pm = (b.paymentMode ?? 'cash').toLowerCase();
  final pmText = pm.contains('online')
      ? 'Online'
      : pm.contains('upi')
          ? 'UPI'
          : 'Cash';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Payment summary",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 16),

      // ---- Line items (parts) ----
      ...items
          .where((it) => it.name.trim().isNotEmpty)
          .where((it) => it.name.toLowerCase() != 'labour charge') // ✅ optional
          .map((it) {
        final lineTotal = it.price * it.qty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${it.name} - ${it.qty} pcs",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "₹$lineTotal",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),

      const SizedBox(height: 8),

      // Labour charges
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Labour charges", style: TextStyle(fontSize: 15)),
          Text(
            "₹$labour",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Taxes
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Taxes & Fee", style: TextStyle(fontSize: 15)),
          Text(
            "₹$taxes",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),
      const Divider(),

      // Total amount
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total amount",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            "₹$total",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      // Paid via ...
      Text(
        "Paid via $pmText",
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
        ),
      ),

      // Billing date line
      if (b.billingDate != null && b.billingDate!.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          b.billingDate!,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    ],
  );
}

// ignore: unused_element
Widget _summaryRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _BookAgainSheet extends StatefulWidget {
  final String service;
  final Function(String date, String slot) onConfirm;

  const _BookAgainSheet({
    required this.service,
    required this.onConfirm,
  });

  @override
  State<_BookAgainSheet> createState() => _BookAgainSheetState();
}

class _BookAgainSheetState extends State<_BookAgainSheet> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  final List<String> ucSlots = const [
    "08:00 AM",
    "08:30 AM",
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "01:00 PM",
    "01:30 PM",
    "02:00 PM",
    "02:30 PM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
    "05:00 PM",
    "05:30 PM",
    "06:00 PM",
    "06:30 PM",
    "07:00 PM",
    "07:30 PM",
    "08:00 PM",
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Book Again",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.service,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _dateSelector(),
              const SizedBox(height: 20),
              _slotSelector(),
              const SizedBox(height: 30),
              _confirmButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _dateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Date",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? "Choose a date"
                      : "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black, // ensure visible
                  ),
                ),
                const Icon(Icons.calendar_month, color: kBrandBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now.add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandBlue,
              onPrimary: Colors.white, // header text
              onSurface: Colors.black, // date text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kBrandBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _slotSelector() {
    if (_selectedDate == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Time Slot",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 14),

        // 🔹 iOS-style soft container
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // light grey, same family
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ucSlots.map((slot) {
              final bool selected = _selectedSlot == slot;

              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected ? kBrandBlue : Colors.white,
                    border: Border.all(
                      color: selected ? kBrandBlue : Colors.grey.shade300,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _confirmButton() {
    final valid = _selectedDate != null && _selectedSlot != null;

    return GestureDetector(
      onTap: valid
          ? () {
              final d =
                  "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}";
              widget.onConfirm(d, _selectedSlot!);
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: valid ? kBrandBlue : Colors.blue.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: valid
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: const Center(
          child: Text(
            "Confirm Booking",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchingTechCard extends StatefulWidget {
  final Color brandBlue;
  const _SearchingTechCard({required this.brandBlue});

  @override
  State<_SearchingTechCard> createState() => _SearchingTechCardState();
}

class _SearchingTechCardState extends State<_SearchingTechCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final glow = 0.06 + (t * 0.10);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: widget.brandBlue.withValues(alpha: glow),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.brandBlue.withValues(alpha: 0.08),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30 + (t * 10),
                      height: 30 + (t * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            widget.brandBlue.withValues(alpha: 0.10 - t * 0.07),
                      ),
                    ),
                    Icon(
                      Icons.location_searching_rounded,
                      color: widget.brandBlue,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Searching technician near you…",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "We’ll assign the best available technician shortly.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 8,
                        color: Colors.grey.shade200,
                        child: Align(
                          alignment: Alignment(-1 + (t * 2), 0),
                          child: Container(
                            width: 90,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: widget.brandBlue.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.brandBlue.withValues(alpha: 0.55 + (t * 0.35)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
