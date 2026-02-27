import 'package:flutter/material.dart';
import 'package:doora_app/features/common/in_app_webview_page.dart';
import '../constants.dart';
import 'package:doora_app/features/cart/cart_service.dart';
import 'package:doora_app/features/cart/cart_page.dart';
import 'package:doora_app/features/home/services/booking_rates_service.dart';

class GeyserCategorySheet extends StatelessWidget {
  final double height;
  final String cityLabel;
  final VoidCallback onClose;

  const GeyserCategorySheet({
    super.key,
    required this.height,
    required this.cityLabel,
    required this.onClose,
  });

  // ✅ Only META locally (subtitle + image + basePrice fallback) — AC jaisa
  Map<String, Map<String, dynamic>> get _gyMeta => {
        'Geyser Check-up': {
          'subtitle': 'No heating / tripping / leakage diagnosis',
          'basePrice': 199,
          'image': 'assets/icons/geyser checkup.png',
        },
        'Geyser Installation': {
          'subtitle': 'Standard wall mount install',
          'basePrice': 499,
          'image': 'assets/icons/geyser installation.png',
        },
        'Geyser Uninstallation': {
          'subtitle': 'Safe removal & line capping',
          'basePrice': 349,
          'image': 'assets/icons/geyser uninstallation.png',
        },
        'Geyser Servicing': {
          'subtitle': 'Element change + testing',
          'basePrice': 599,
          'image': 'assets/icons/geyser not heating.png',
        },

        // ✅ Optional: DB titles for size variants (if you store them like this)
        'Geyser Servicing - Small (6-10 L)': {
          'subtitle': 'Servicing for small geyser capacity',
          'basePrice': 599,
          'image': 'assets/icons/geyser not heating.png',
        },
        'Geyser Servicing - Medium (15-25 L)': {
          'subtitle': 'Servicing for medium geyser capacity',
          'basePrice': 699,
          'image': 'assets/icons/geyser not heating.png',
        },
        'Geyser Servicing - Large (25+ L)': {
          'subtitle': 'Servicing for large geyser capacity',
          'basePrice': 899,
          'image': 'assets/icons/geyser not heating.png',
        },
      };

  // ✅ Normalize title to avoid dash/space mismatches
  static String _normalizeTitle(String s) {
    return s
        .trim()
        .replaceAll('–', '-') // en-dash -> hyphen
        .replaceAll(RegExp(r'\s+'), ' '); // multi spaces -> one
  }

  // ✅ Common add-to-cart + navigate
  void _addToCartAndGo(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int price,
    required String image,
    required String category,
    required String city,
  }) {
    final cart = CartService.instance;
    debugPrint('ADD -> {identityHashCode(cart)} @Geyser');

    try {
      final normalizedTitle = _normalizeTitle(title);
      final normalizedCity = city.trim();

      final int existing = cart.items.indexWhere((it) =>
          _normalizeTitle(it.title) == normalizedTitle &&
          it.category == category &&
          it.city.trim() == normalizedCity &&
          it.price == price);

      if (existing >= 0) {
        cart.increment(existing);
      } else {
        cart.add(CartItem(
          title: normalizedTitle,
          subtitle: subtitle,
          price: price,
          image: image,
          category: category,
          city: normalizedCity,
        ));
      }
    } catch (e, st) {
      debugPrint('ADD ERROR: $e\n$st');
    }

    Navigator.of(context, rootNavigator: true).maybePop();
    Future.microtask(() {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CartPage(),
        ),
      );
    });
  }

  // ✅ Size option model
  Future<_GeyserSizeOption?> _pickServicingSize(BuildContext context) {
    final String city = cityLabel.trim();

    final List<_GeyserSizeOption> options = const [
      _GeyserSizeOption(label: 'Small (6-10 L)', basePrice: 599),
      _GeyserSizeOption(label: 'Medium (15-25 L)', basePrice: 699),
      _GeyserSizeOption(label: 'Large (25+ L)', basePrice: 899),
    ];

    return showModalBottomSheet<_GeyserSizeOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewPadding.bottom;
        _GeyserSizeOption? selected;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: bottom + 8,
                ),
                child: Container(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const Text(
                          'Select Geyser Size',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Servicing charges depend on capacity — $city',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...options.map((opt) {
                          final String rateTitle = _normalizeTitle(
                              'Geyser Servicing - ${opt.label}');

                          // ✅ price from backend if exists, else base
                          final int finalPrice = bookingRates.priceOrBase(
                            city: city,
                            category: 'Geyser',
                            title: rateTitle,
                            basePrice: opt.basePrice,
                          );

                          final bool isSelected = selected?.label == opt.label;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2E6FF2)
                                    : Colors.black.withValues(alpha: 0.06),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => selected = opt),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(
                                  height: 56,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? const Color(0xFF2E6FF2)
                                            : Colors.black26,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
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
                                          '₹$finalPrice',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: selected == null
                                ? null
                                : () => Navigator.of(ctx).pop(selected),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: kAccent,
                              disabledBackgroundColor:
                                  Colors.black.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
            );
          },
        );
      },
    );
  }

  // ✅ Service add handler
  void _handleAddService(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int price,
    required String image,
  }) async {
    const String category = 'Geyser';
    final String city = cityLabel.trim();

    if (_normalizeTitle(title) == 'Geyser Servicing') {
      final picked = await _pickServicingSize(context);
      if (picked == null) return;

      final String rateTitle =
          _normalizeTitle('Geyser Servicing - ${picked.label}');
      final int sizePrice = bookingRates.priceOrBase(
        city: city,
        category: category,
        title: rateTitle,
        basePrice: picked.basePrice,
      );

      _addToCartAndGo(
        // ignore: use_build_context_synchronously
        context,
        title: rateTitle,
        subtitle: subtitle,
        price: sizePrice,
        image: image,
        category: category,
        city: city,
      );
      return;
    }

    _addToCartAndGo(
      context,
      title: title,
      subtitle: subtitle,
      price: price,
      image: image,
      category: category,
      city: city,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String city = cityLabel.trim();

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFF5F5F7),
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
                        'Geyser Services in $city',
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
                        // ✅ AC jaisa: backend services list
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              FutureBuilder<List<BookingServiceRow>>(
                                future: bookingRates.loadCategoryServices(
                                  city: city,
                                  category: 'Geyser',
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
                                    children:
                                        List.generate(services.length, (i) {
                                      final s = services[i];

                                      final meta =
                                          _gyMeta[_normalizeTitle(s.title)] ??
                                              _gyMeta[s.title] ??
                                              {};

                                      final String subtitle =
                                          (meta['subtitle'] ??
                                                  'Service details')
                                              .toString();
                                      final String image = (meta['image'] ??
                                              'assets/icons/geyser checkup.png')
                                          .toString();
                                      final int basePrice =
                                          (meta['basePrice'] is int)
                                              ? meta['basePrice'] as int
                                              : 0;

                                      final int finalPrice =
                                          (s.price > 0) ? s.price : basePrice;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: _ServiceCard(
                                          title: s.title,
                                          subtitle: subtitle,
                                          price: finalPrice,
                                          image: image,
                                          onAdd: () => _handleAddService(
                                            context,
                                            title: s.title,
                                            subtitle: subtitle,
                                            price: finalPrice,
                                            image: image,
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ]),
                          ),
                        ),

                        // ✅ Rate Card section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              children: [
                                Text(
                                  'Geyser Spare Parts Standard Rate Card — $city',
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
                                        '?category=${Uri.encodeComponent('Geyser')}'
                                        '&city=${Uri.encodeComponent(city)}',
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
                  child:
                      Icon(Icons.close_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ helper model
class _GeyserSizeOption {
  final String label;
  final int basePrice;
  const _GeyserSizeOption({required this.label, required this.basePrice});
}

// ================== CARD ==================
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
                      onTap: () => _openDetailsSheet(context),
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
                                  'Approx. 30–60 mins work • Geyser specialist • Standard safety protocols followed',
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
                                    'Technician checks the geyser and confirms the issue.'),
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
            Image.asset('assets/icons/geyser checkup.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}
