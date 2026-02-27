import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _city = 'Nagpur'; // fallback

  @override
  void initState() {
    super.initState();
    _initCity(); // fetch current city
  }

  Future<void> _initCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final possible = (p.locality?.isNotEmpty ?? false)
            ? p.locality!
            : (p.subAdministrativeArea?.isNotEmpty ?? false)
                ? p.subAdministrativeArea!
                : (p.administrativeArea?.isNotEmpty ?? false)
                    ? p.administrativeArea!
                    : null;
        if (possible != null) {
          setState(() {
            _city = possible;
          });
          return;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(city: _city)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _SearchBar()),
          // Sticky warranty header just below search:
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeader(
              minExtent: 48,
              maxExtent: 48,
              child: const _WarrantyBanner(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _HeroPromoCard()),

          // ...yahan aap “Most Booked Services” etc. add kar sakte ho
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
      bottomNavigationBar: _BottomBar(),
    );
  }
}

/* -------------------- UI Parts -------------------- */

class _TopBar extends StatelessWidget {
  final String city;
  const _TopBar({required this.city});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          16, 14 + 8, 16, 0), // statusbar spacing + a little
      child: Row(
        children: [
          // Your LOGO in place of "D"
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 159, 127, 127),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6)],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 65,
              height: 65,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1F3C),
                  ),
                ),
              ],
            ),
          ),
          // Notification + Cart on right
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
        ),
        height: 48,
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services, e.g. AC Repair',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyBanner extends StatelessWidget {
  const _WarrantyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE28A), Color(0xFFFFD24D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF0F7A2B)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Warranty on Every Repairs + 100% Service Guarantee',
              style: TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPromoCard extends StatelessWidget {
  const _HeroPromoCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2166F3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // “Home Services at your doorstep” version of earlier banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'UP TO 30% OFF',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Home Services At\nYour Doorstep',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Expert technicians • Genuine parts • Best prices',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2166F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text('Go To Book Now',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            // small service thumbs row (placeholders — replace with your images)
            Row(
              children: [
                _serviceThumb('assets/images/wm.png'),
                _serviceThumb('assets/images/ac.png'),
                _serviceThumb('assets/images/mw.png'),
                _serviceThumb('assets/images/fridge.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceThumb(String path) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(path),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StickyHeader extends SliverPersistentHeaderDelegate {
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget child;

  _StickyHeader({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child); // important for sticky effect
  }

  @override
  bool shouldRebuild(covariant _StickyHeader oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

/* ----------- Optional bottom bar (icons already in assets/icons) ----------- */
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), label: 'My Bookings'),
        BottomNavigationBarItem(
            icon: Icon(Icons.help_outline_rounded), label: 'Help'),
        BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined), label: 'Warranty'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded), label: 'Account'),
      ],
    );
  }
}

// Put this OUTSIDE of any widget class (e.g., at bottom of the file).
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(minHeight, maxHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child); // important so it fills header space
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate old) {
    return minHeight != old.minHeight ||
        maxHeight != old.maxHeight ||
        child != old.child;
  }
}
