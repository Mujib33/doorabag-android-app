import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:doora_app/features/cart/cart_service.dart';
import 'package:doora_app/features/cart/cart_page.dart';
import 'package:doora_app/features/home/services/booking_rates_service.dart';
import 'package:doora_app/features/common/in_app_webview_page.dart';

class AcCategorySheet extends StatelessWidget {
  final double height;
  final String cityLabel;
  final VoidCallback onClose;

  const AcCategorySheet({
    super.key,
    required this.height,
    required this.cityLabel,
    required this.onClose,
  });

  // ✅ Only META locally (subtitle + image + basePrice fallback)
  Map<String, Map<String, dynamic>> get _acMeta => {
        'AC Checkup': {
          'subtitle': 'Full AC checkup and problem finding',
          'basePrice': 199,
          'image': 'assets/photos/1000317810.webp',
        },
        'Foam Jet Service': {
          'subtitle': 'Indoor unit cleaning with foam & jet spray',
          'basePrice': 549,
          'image': 'assets/photos/1000317814.webp',
        },
        'AC Installation': {
          'subtitle': 'Complete AC installation by expert technician',
          'basePrice': 1200,
          'image': 'assets/icons/ac installation.png',
        },
        'AC Uninstallation': {
          'subtitle': 'Safe and quick AC removal',
          'basePrice': 600,
          'image': 'assets/photos/ac repair.webp',
        },
        'Window AC Service Lite': {
          'subtitle': 'Basic service for window AC',
          'basePrice': 449,
          'image': 'assets/icons/Window AC.png',
        },
        'Split AC Service Lite': {
          'subtitle': 'Filter & Dust Cleaning Only Whithout Foam and Jet',
          'basePrice': 349,
          'image': 'assets/icons/AC Filter Cleaning.png',
        },
        'AC Water Leakage': {
          'subtitle': 'Fix indoor unit water leakage issue',
          'basePrice': 499,
          'image': 'assets/photos/ac repair.webp',
        },
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFF5F5F7), // iOS-style background
            child: Column(
              children: [
                // ---------- HEADER ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 48, 6),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 8, 8, 8)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'AC Repair & Services in ${cityLabel.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ---------- BODY ----------
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is OverscrollNotification && n.overscroll < 0) {
                        onClose();
                        return true;
                      }
                      if (n is ScrollUpdateNotification &&
                          n.metrics.pixels <= 0 &&
                          (n.scrollDelta ?? 0) < -10) {
                        onClose();
                        return true;
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        // 🔹 Clean vertical list – 1 card per row
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // ✅ NOW: load list from backend (title + city-wise price)
                              FutureBuilder<List<BookingServiceRow>>(
                                future: bookingRates.loadCategoryServices(
                                  city: cityLabel,
                                  category: 'AC',
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Failed to load services Closed the page and Re-Open: ${snapshot.error}',
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                    );
                                  }

                                  final services = snapshot.data ?? [];

                                  return Column(
                                    children: List.generate(
                                      services.length,
                                      (i) {
                                        final s = services[i];

                                        final meta = _acMeta[s.title] ?? {};
                                        final String subtitle =
                                            (meta['subtitle'] ??
                                                    'Service details')
                                                .toString();
                                        final String image = (meta['image'] ??
                                                'assets/photos/ac repair.webp')
                                            .toString();
                                        final int basePrice =
                                            (meta['basePrice'] is int)
                                                ? meta['basePrice'] as int
                                                : 0;

                                        // ✅ backend price priority
                                        final int finalPrice =
                                            (s.price > 0) ? s.price : basePrice;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: _ServiceCard(
                                            title: s.title, // ✅ backend title
                                            subtitle: subtitle,
                                            price:
                                                finalPrice, // ✅ backend price
                                            image: image,
                                            onAdd: () {
                                              final cart = CartService.instance;
                                              debugPrint(
                                                  'ADD -> {identityHashCode(cart)} @AC');

                                              try {
                                                final int price = finalPrice;
                                                final String title = s.title;
                                                const String category = 'AC';
                                                final String city = cityLabel;

                                                final int existing = cart.items
                                                    .indexWhere((it) =>
                                                        it.title == title &&
                                                        it.category ==
                                                            category &&
                                                        it.city == city &&
                                                        it.price == price);

                                                if (existing >= 0) {
                                                  cart.increment(existing);
                                                } else {
                                                  cart.add(CartItem(
                                                    title: title,
                                                    subtitle: subtitle,
                                                    price: price,
                                                    image: image,
                                                    category: category,
                                                    city: cityLabel,
                                                  ));
                                                }
                                              } catch (e, st) {
                                                debugPrint(
                                                    'ADD ERROR: $e\n$st');
                                              }

                                              Navigator.of(context,
                                                      rootNavigator: true)
                                                  .maybePop();
                                              Future.microtask(() {
                                                if (!context.mounted) return;
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => CartPage(),
                                                  ),
                                                );
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ]),
                          ),
                        ),

                        // 🔹 Rate card section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              children: [
                                Text(
                                  'AC Spare Parts Standard Rate Card — ${cityLabel.trim()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 42,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final url = Uri.parse(
                                        'https://www.doorabag.in/standard_rate_card.php'
                                        '?category=${Uri.encodeComponent('AC')}'
                                        '&city=${Uri.encodeComponent(cityLabel.trim())}',
                                      );

                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => InAppWebViewPage(
                                            title: 'Standard Rate Card',
                                            url: url,
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: kAccent.withValues(alpha: 0.85),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Rate Card',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- CLOSE BUTTON ----------
          Positioned(
            right: 12,
            top: -21,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== CLEAN HYBRID SERVICE CARD ==================
class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int price;
  final String image;
  final VoidCallback onAdd;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 247, 249),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        // 🔹 FLEXIBLE HEIGHT — overflow ka problem solved!
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE — FULL DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // PRICE
                    Text(
                      "₹$price",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // SUBTITLE
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 VIEW DETAILS — clickable
                    GestureDetector(
                      onTap: () {
                        _openDetailsSheet(context);
                      },
                      child: const Text(
                        "View details",
                        style: TextStyle(
                          color: Color(0xFF2E6FF2),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT SIDE — IMAGE + ADD BUTTON (updated)
              Column(
                children: [
                  // IMAGE BOX (slightly smaller)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 100,
                      height: 85,
                      child: _SmartImage(image: image),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ADD BUTTON now below image
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF2E6FF2),
                        foregroundColor:
                            const Color.fromARGB(255, 254, 255, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Color(0xFF2E6FF2)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text(
                        "Add",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 View Details Bottom Sheet
  void _openDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 👈 iOS style: transparent bg
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewPadding.bottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Bottom me chipka hua sheet, rounded + shadow
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7), // light iOS grey
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),

                          // 🔹 Top card: Image + title + price pill
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _SmartImage(image: image),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0ECFF),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '₹$price',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 🔹 Info card: timing + visit info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service overview',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Approx. 60–90 mins work • Certified technician • Standard safety protocols followed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 🔹 "How it works" card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How it works',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _BulletPoint(
                                    'Doorabag verified technician visits your location.'),
                                _BulletPoint(
                                    'Technician checks the appliance and confirms the issue.'),
                                _BulletPoint(
                                    'Final estimate is shared with you before starting the work.'),
                                _BulletPoint(
                                    'Work is completed and you get warranty as per policy.'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 CTA button full width
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                onAdd();
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: kAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
      },
    );
  }
}

// Small bullet point widget for details sheet
// ignore: unused_element
class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== IMAGE HELPER ==================
class _SmartImage extends StatelessWidget {
  final String image;
  const _SmartImage({required this.image});

  @override
  Widget build(BuildContext context) {
    final isNet = image.startsWith('http');
    if (isNet) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/photos/ac repair.webp', fit: BoxFit.cover),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}
