import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:doora_app/features/cart/cart_service.dart';
import 'package:doora_app/features/cart/cart_page.dart';
import 'package:doora_app/features/home/services/booking_rates_service.dart';
import 'package:doora_app/features/common/in_app_webview_page.dart';

class RoCategorySheet extends StatelessWidget {
  final double height;
  final String cityLabel;
  final VoidCallback onClose;

  const RoCategorySheet({
    super.key,
    required this.height,
    required this.cityLabel,
    required this.onClose,
  });

  // ✅ Only META locally (subtitle + image + basePrice fallback) — AC file jaisa
  Map<String, Map<String, dynamic>> get _roMeta => {
        'RO / Purifier Check-up': {
          'subtitle': 'Basic diagnosis & water flow checks',
          'basePrice': 199,
          'image': 'assets/icons/ro.png',
        },
        'RO Installation': {
          'subtitle': 'Wall mount / under-sink installation',
          'basePrice': 399,
          'image': 'assets/icons/roinstallation.png',
        },
        'RO Uninstallation': {
          'subtitle': 'Safe removal & line sealing',
          'basePrice': 349,
          'image': 'assets/icons/rouninstallation.png',
        },
        'Filter / Candle Checkup': {
          'subtitle': 'Sediment / Carbon / Post-Carbon',
          'basePrice': 199,
          'image': 'assets/icons/filtercange.png',
        },
        'Water Taste Issue Checkup': {
          'subtitle': 'Taste / TDS issue diagnosis & estimate',
          'basePrice': 199,
          'image': 'assets/icons/watertaste.png',
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
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'RO / Purifier Services in ${cityLabel.trim()}',
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
                        // 🔹 Clean vertical list – backend linked (AC jaisa)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              FutureBuilder<List<BookingServiceRow>>(
                                future: bookingRates.loadCategoryServices(
                                  city: cityLabel,
                                  category: 'RO',
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

                                        final meta = _roMeta[s.title] ?? {};
                                        final String subtitle =
                                            (meta['subtitle'] ??
                                                    'Service details')
                                                .toString();
                                        final String image = (meta['image'] ??
                                                'assets/icons/ro.png')
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
                                            title: s.title,
                                            subtitle: subtitle,
                                            price: finalPrice,
                                            image: image,
                                            onAdd: () {
                                              final cart = CartService.instance;
                                              debugPrint(
                                                  'ADD -> {identityHashCode(cart)} @RO');

                                              try {
                                                final int price = finalPrice;
                                                final String title = s.title;
                                                const String category = 'RO';
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
                                  'RO / Purifier Spare Parts Standard Rate Card — ${cityLabel.trim()}',
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
                                        '?category=${Uri.encodeComponent('RO')}'
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      "₹$price",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
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

              // RIGHT
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 100,
                      height: 85,
                      child: _SmartImage(image: image),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF2E6FF2),
                        foregroundColor: Colors.white,
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

  // 🔹 View Details Bottom Sheet – RO content
  void _openDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
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

                          // Top card
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

                          // Service overview
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
                                  'Approx. 30–60 mins work • RO / Purifier specialist • Standard safety protocols followed',
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

                          // How it works
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
                                    'Technician checks the RO / Purifier and confirms the issue.'),
                                _BulletPoint(
                                    'Final estimate is shared with you before starting the work.'),
                                _BulletPoint(
                                    'Work is completed and you get warranty as per policy.'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

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

// Bullet point widget
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

// SmartImage helper
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
            Image.asset('assets/icons/ro.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}
