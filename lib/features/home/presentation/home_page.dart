// HomePage – Header + Search (typewriter) + Banner + Grid + Bottom Nav
// AC / WM / Refrigerator category sheets via slide-up dialogs.

import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sheets/ac_category_sheet.dart';
import 'sheets/wm_category_sheet.dart';
import 'sheets/refrigerator_category_sheet.dart';
import 'sheets/microwave_category_sheet.dart';
import 'sheets/ro_category_sheet.dart';
import 'sheets/tv_category_sheet.dart';
import 'sheets/geyser_category_sheet.dart';
import 'sheets/chimney_category_sheet.dart';
import 'sheets/cleaning_category_sheet.dart';
import 'sheets/airpurifier_category_sheet.dart';
import 'widgets/big_header_delegate.dart';
import 'widgets/cart_button.dart';
import 'widgets/service_tile.dart';
import 'video_carousel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 👇 Location picker import
import 'package:doora_app/features/location/location_picker_page.dart';

// -------------------- GLOBAL CATEGORY SHEET OPENER --------------------

void openCategorySheet(BuildContext context, int catIndex, String city) {
  switch (catIndex) {
    case 0:
      _openAcCategorySheet(context, city);
      break;

    case 1:
      _openWmCategorySheet(context, city);
      break;

    case 2:
      _openRefrigeratorCategorySheet(context, city);
      break;

    case 3:
      _openMicrowaveCategorySheet(context, city);
      break;

    case 4:
      _openRoCategorySheet(context, city);
      break;

    case 5:
      _openTvCategorySheet(context, city);
      break;

    case 6:
      _openGeyserCategorySheet(context, city);
      break;

    case 7:
      _openChimneyCategorySheet(context, city);
      break;

    case 8:
      _openCleaningCategorySheet(context, city);
      break;

    case 9:
      _openAirPurifierCategorySheet(context, city);
      break;
  }
}

// -------------------- CATEGORY SHEET FUNCTIONS --------------------

Future<void> _saveLastCategory(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('last_category', index);
}

void _openAcCategorySheet(BuildContext context, String city) {
  _saveLastCategory(0);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AcCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openWmCategorySheet(BuildContext context, String city) {
  _saveLastCategory(1);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => WmCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openRefrigeratorCategorySheet(BuildContext context, String city) {
  _saveLastCategory(2);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => RefrigeratorCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openMicrowaveCategorySheet(BuildContext context, String city) {
  _saveLastCategory(3);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MicrowaveCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openRoCategorySheet(BuildContext context, String city) {
  _saveLastCategory(4);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => RoCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openTvCategorySheet(BuildContext context, String city) {
  _saveLastCategory(5);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TvCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openGeyserCategorySheet(BuildContext context, String city) {
  _saveLastCategory(6);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => GeyserCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openChimneyCategorySheet(BuildContext context, String city) {
  _saveLastCategory(7);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChimneyCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openCleaningCategorySheet(BuildContext context, String city) {
  _saveLastCategory(8);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => CleaningCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

void _openAirPurifierCategorySheet(BuildContext context, String city) {
  _saveLastCategory(9);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AirPurifierCategorySheet(
      height: MediaQuery.of(context).size.height * 0.85,
      cityLabel: city,
      onClose: () => Navigator.pop(context),
    ),
  );
}

// -----------------------------------------------------------------------

// 🔹 Search ke liye internal model (service + category index)
class _ServiceEntry {
  final String label; // e.g. "Foam Jet Service"
  final int categoryIndex; // 0 = AC, 1 = WM, etc.

  const _ServiceEntry(this.label, this.categoryIndex);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 🔹 UPPER LINE = CITY, LOWER LINE = LOCAL ADDRESS
  String _locArea = 'Detecting…'; // city
  String _locAddress = 'Please wait'; // local address

  // ✅ PHP se aane wala availability data
  Map<int, String> _catStatus = {}; // categoryIndex -> "live"/"coming_soon"
  bool _serviceAreaAvailable = true;
  String _serviceAreaMsg = '';

  final PageController _bannerCtrl = PageController(viewportFraction: 1);
  final List<String> _banners = const [
    'assets/banners/warranty.jpg',
  ];
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // 👇 Scroll controller + anchor key
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _servicesAnchorKey = GlobalKey();

  final List<String> _searchHints = const [
    // AC
    'Foam Jet Service',
    'AC Gas Refill',
    'AC Installation',
    'AC Uninstallation',
    'AC Checkup',
    'AC Water Leakage',

    // Washing Machine
    'Semi-automatic Repair',
    'Fully-Automatic Repair',
    'Drum Cleaning Service',
    'Washing Machine Installation',
    'Washing Machine Uninstallation',

    // Refrigerator
    'Fridge Not Cooling',
    'Refrigerator Check-up',
    'Fridge Gas Refill',
    'Double Door Refrigerator Service',

    // Microwave
    'Microwave Not Heating',
    'Microwave Buttons Not Working',
    'Microwave Door Issue',

    // RO
    'RO Filter Change',
    'RO Service',
    'RO Installation',
    'RO Uninstallation',

    // TV
    'LED / TV No Display',
    'TV Wall Mount Installation',
    'TV No Power',

    // Geyser
    'Geyser Not Heating',
    'Geyser Installation',
    'Geyser Uninstallation',

    // Chimney
    'Chimney Deep Cleaning',
    'Chimney Installation',
    'Chimney Uninstallation',

    // Cleaning
    'Sofa Shampooing',
    'Full Home Deep Cleaning',
    'Kitchen Cleaning',
    'Bathroom Cleaning',

    // Air Purifier
    'Air Purifier Checkup',
    'Air Purifier Servicing',
    'Air Purifier Deep Cleaning',
  ];

  int _hintIndex = 0;
  int _charIndex = 0;
  String _typed = '';
  Timer? _typeTimer;

  static const List<String> _labels = [
    'AC Repair',
    'Washing Machine Rep',
    'Refrigerator Repair',
    'Microwave Repair',
    'RO / Purifier Repair',
    'LED / TV Repair',
    'Geyser Repair',
    'Chimney Repair',
    'Cleaning',
    'Air Purifier',
  ];

  // 🔍 Search mapping (category index)
  static const List<_ServiceEntry> _searchEntries = [
    // AC (0)
    _ServiceEntry('Foam Jet Service', 0),
    _ServiceEntry('AC Installation', 0),
    _ServiceEntry('AC Uninstallation', 0),
    _ServiceEntry('Window AC Service Lite', 0),
    _ServiceEntry('Split AC Service Lite', 0),
    _ServiceEntry('AC Checkup', 0),
    _ServiceEntry('AC Water Leakage', 0),

    // Washing Machine (1)
    _ServiceEntry('Washing Machine Semi-automatic Check-up & Repair', 1),
    _ServiceEntry(
        'Washing Machine Fully-automatic Check-up & Repair (Top load)', 1),
    _ServiceEntry(
        'Washing Machine Fully-automatic Check-up & Repair (Front load)', 1),
    _ServiceEntry('Washing Machine Installation', 1),
    _ServiceEntry('Washing Machine Uninstallation', 1),
    _ServiceEntry(
        'Washing Machine Fully-automatic (Top load) Chemical Drum Servicing',
        1),
    _ServiceEntry(
        'Washing Machine Fully-automatic (Front load) Chemical Drum Servicing',
        1),

    // Refrigerator (2)
    _ServiceEntry('Refrigerator Single Door Refrigerator Check-up', 2),
    _ServiceEntry(
        'Refrigerator Double Door Refrigerator Check-up (non-inverter)', 2),
    _ServiceEntry(
        'Refrigerator Double Door Refrigerator Check-up (inverter)', 2),
    _ServiceEntry('Refrigerator Side-By-Side Door Refrigerator Check-up', 2),
    _ServiceEntry('Refrigerator Single Door Refrigerator Full Servicing', 2),
    _ServiceEntry('Refrigerator Double Door Refrigerator Full Servicing', 2),
    _ServiceEntry('Fridge Single Door Refrigerator Check-up', 2),
    _ServiceEntry('Fridge Double Door Refrigerator Check-up (non-inverter)', 2),
    _ServiceEntry('Fridge Double Door Refrigerator Check-up (inverter)', 2),
    _ServiceEntry('Fridge Side-By-Side Door Refrigerator Check-up', 2),
    _ServiceEntry('Fridge Single Door Refrigerator Full Servicing', 2),
    _ServiceEntry('Fridge Double Door Refrigerator Full Servicing', 2),

    // Microwave (3)
    _ServiceEntry('Microwave Check-up', 3),
    _ServiceEntry('Buttons Not Working', 3),
    _ServiceEntry('Microwave Not Working', 3),
    _ServiceEntry('Microwave Noise Issue', 3),
    _ServiceEntry('Microwave Not Heating', 3),
    _ServiceEntry('Microwave Unknown Issue', 3),

    // RO (4)
    _ServiceEntry('RO / Purifier Check-up', 4),
    _ServiceEntry('RO Installation', 4),
    _ServiceEntry('RO Uninstallation', 4),
    _ServiceEntry('Filter / Candle Replacement', 4),
    _ServiceEntry('Membrane Replacement', 4),

    // TV (5)
    _ServiceEntry('LED/TV Check-up', 5),
    _ServiceEntry('No Power / Auto Off', 5),
    _ServiceEntry('No Display / Lines on Screen', 5),
    _ServiceEntry('No Sound / Distorted Audio', 5),
    _ServiceEntry('Wall Mount Installation', 5),

    // Geyser (6)
    _ServiceEntry('Geyser Check-up', 6),
    _ServiceEntry('Geyser Installation', 6),
    _ServiceEntry('Geyser Uninstallation', 6),
    _ServiceEntry('Heating Element Replacement', 6),
    _ServiceEntry('Thermostat / Cut-out Replacement', 6),

    // Chimney (7)
    _ServiceEntry('Chimney Check-up', 7),
    _ServiceEntry('Chimney Installation', 7),
    _ServiceEntry('Chimney Uninstallation', 7),
    _ServiceEntry('Chimney Deep Cleaning', 7),
    _ServiceEntry('Filter Replacement', 7),

    // Cleaning (8)
    _ServiceEntry('Kitchen Deep Cleaning', 8),
    _ServiceEntry('Bathroom Deep Cleaning', 8),
    _ServiceEntry('Sofa Shampooing (per 5-seater)', 8),
    _ServiceEntry('Full Home Deep Cleaning (1 BHK)', 8),
    _ServiceEntry('Full Home Deep Cleaning (2 BHK)', 8),

    // Air Purifier
    _ServiceEntry('Air Purifier Checkup', 9),
    _ServiceEntry('Air Purifier Servicing', 9),
    _ServiceEntry('Air Purifier Deep Cleaning', 9),
  ];

  static const List<String> _iconFiles = [
    'ac.png',
    'washing_machine.png',
    'fridge.png',
    'microwave.png',
    'ro.png',
    'tv.png',
    'geyser checkup.png',
    'chimney checkup.png',
    'cleaning.png',
    'air purifier checkup.png',
  ];

  @override
  void initState() {
    super.initState();

    _fetchCity().then((_) {
      _fetchAvailabilityFromPhp();
    });

    _startBannerAutoSlide();
    _startTypewriter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingSheetIfAny();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _typeTimer?.cancel();
    _bannerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showComingSoonDialog(String msg) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9FAFB), // light off-white
        surfaceTintColor: Colors.transparent, // Material 3 fix
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          "Not Available",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E6FF2), // DooraBag blue
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Checkout se wapas aate time – agar user ne city change ki hogi
  // to SharedPreferences me pending sheet + city store hote hain.
  // Yaha read karke correct sheet auto-open kar dete hain.
  Future<void> _openPendingSheetIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCategory = prefs.getString('pending_sheet_category');
    final pendingCity = prefs.getString('pending_sheet_city');

    if (pendingCategory == null ||
        pendingCity == null ||
        pendingCity.trim().isEmpty) {
      return;
    }

    // One-time use
    await prefs.remove('pending_sheet_category');
    await prefs.remove('pending_sheet_city');

    if (!mounted) return;
    _openCategorySheetForCity(pendingCategory, pendingCity.trim());
  }

  // 🔹 Generic helper: given category + city, same iOS-style sheet open kare
  void _openCategorySheetForCity(String category, String cityLabel) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '$category Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        Widget sheet;

        switch (category.toLowerCase()) {
          case 'ac':
            sheet = AcCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'washing machine':
            sheet = WmCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'refrigerator':
            sheet = RefrigeratorCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'microwave':
            sheet = MicrowaveCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'ro':
            sheet = RoCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'tv':
            sheet = TvCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'geyser':
            sheet = GeyserCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'chimney':
            sheet = ChimneyCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'cleaning':
            sheet = CleaningCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          case 'air purifier':
            sheet = AirPurifierCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;

          default:
            sheet = AcCategorySheet(
              height: h,
              cityLabel: cityLabel,
              onClose: () => Navigator.of(ctx).maybePop(),
            );
            break;
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          child: Stack(
            children: [
              // Blur + dim background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: const Color(0x40000000)),
                ),
              ),

              // Bottom sheet
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: sheet,
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  // 🔹 COMMON HELPER: kisi bhi lat/lng se CITY + LOCAL ADDRESS set kare
  Future<void> _updateLocationHeader(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return;

      final m = marks.first;

      // CITY (sirf city name)
      final city = (m.locality?.isNotEmpty == true)
          ? m.locality!
          : (m.subAdministrativeArea?.isNotEmpty == true)
              ? m.subAdministrativeArea!
              : (m.administrativeArea?.isNotEmpty == true)
                  ? m.administrativeArea!
                  : 'Your City';

      // LOCAL ADDRESS (city ke bina)
      final parts = <String>[];

      if ((m.subLocality ?? '').isNotEmpty) {
        parts.add(m.subLocality!);
      }
      if ((m.street ?? '').isNotEmpty) {
        parts.add(m.street!);
      }
      if ((m.postalCode ?? '').isNotEmpty) {
        parts.add(m.postalCode!);
      }

      final localAddress = parts.join(', ');

      setState(() {
        _locArea = city;
        _locAddress =
            localAddress.isNotEmpty ? localAddress : 'Near your location';
      });
    } catch (e) {
      debugPrint('update header error: $e');
    }
  }

  // 🔹 App start hote hi: GPS se city + address
  Future<void> _fetchCity() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied ||
            p == LocationPermission.deniedForever) {
          return;
        }
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _updateLocationHeader(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // 🔹 Location picker open karega, wapas lat/lng se header update karega
  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (result != null) {
      await _updateLocationHeader(result.lat, result.lng);
      await _fetchAvailabilityFromPhp();
    }
  }

  Future<void> _fetchAvailabilityFromPhp() async {
    try {
      final city = _locArea.trim();
      if (city.isEmpty) return;

      final url = Uri.parse(
        "https://doorabag.in/api/service_availability.php?city=${Uri.encodeComponent(city)}",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      final available = data["service_area_available"] == true;
      final msg = (data["message"] ?? "").toString();

      if (!mounted) return;

      if (!available) {
        setState(() {
          _serviceAreaAvailable = false;
          _serviceAreaMsg =
              msg.isNotEmpty ? msg : "Service not available in your area";
          _catStatus = {};
        });

        // ✅ Direct popup
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => AlertDialog(
              title: const Text("Not Available"),
              content: Text(_serviceAreaMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        });
        return;
      }

      final List cats = (data["categories"] ?? []) as List;
      final map = <int, String>{};

      for (final c in cats) {
        final idx = c["index"];
        final status = (c["status"] ?? "coming_soon").toString();
        if (idx is int) map[idx] = status;
      }

      setState(() {
        _serviceAreaAvailable = true;
        _serviceAreaMsg = "";
        _catStatus = map;
      });
    } catch (e) {
      debugPrint("availability error: $e");
    }
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _banners.isEmpty) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _bannerIndex = next);
    });
  }

  void _startTypewriter() {
    _typeTimer?.cancel();
    const tick = Duration(milliseconds: 70);
    const hold = Duration(milliseconds: 900);

    _typed = '';
    _charIndex = 0;

    _typeTimer = Timer.periodic(tick, (t) {
      if (!mounted) return;
      final full = _searchHints[_hintIndex];

      if (_charIndex < full.length) {
        setState(() {
          _charIndex++;
          _typed = full.substring(0, _charIndex);
        });
      } else {
        t.cancel();
        Future.delayed(hold, () {
          if (!mounted) return;
          setState(() {
            _hintIndex = (_hintIndex + 1) % _searchHints.length;
            _typed = '';
            _charIndex = 0;
          });
          _startTypewriter();
        });
      }
    });
  }

  // 🔍 SEARCH OVERLAY OPEN + RESULT HANDLE
  Future<void> _openSearch() async {
    final String? result = await showSearch<String>(
      context: context,
      delegate: ServiceSearchDelegate(
        entries: _searchEntries,
      ),
    );

    if (result == null || result.isEmpty) return;

    final _ServiceEntry entry = _searchEntries.firstWhere(
      (e) => e.label == result,
      orElse: () => const _ServiceEntry('', -1),
    );
    if (entry.categoryIndex < 0 || entry.categoryIndex >= _labels.length) {
      return;
    }

    if (!_serviceAreaAvailable) {
      _showComingSoonDialog("Service not available in your area");
      return;
    }

    final status = _catStatus[entry.categoryIndex] ?? "live";
    if (status != "live") {
      _showComingSoonDialog(
          "${_labels[entry.categoryIndex]} is coming soon in $_locArea");
      return;
    }

    switch (entry.categoryIndex) {
      case 0:
        _openAcCategorySheet();
        break;
      case 1:
        _openWmCategorySheet();
        break;
      case 2:
        _openRefrigeratorCategorySheet();
        break;
      case 3:
        _openMicrowaveCategorySheet();
        break;
      case 4:
        _openRoCategorySheet();
        break;
      case 5:
        _openTvCategorySheet();
        break;
      case 6:
        _openGeyserCategorySheet();
        break;
      case 7:
        _openChimneyCategorySheet();
        break;
      case 8:
        _openCleaningCategorySheet();
        break;
      case 9:
        _openAirPurifierCategorySheet();
        break;
      default:
        break;
    }
  }

// 👇 "Go To Book Now" – iOS glossy bottom sheet with all services
  void _scrollToServices() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'All Services',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              // 🔹 Blur + dim background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: const Color(0x40000000)),
                ),
              ),

              // 🔹 Bottom sheet (Glossy)
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 10,
                  right: 10,
                  bottom: mq.padding.bottom + 10,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xF7FFFFFF), // glossy white
                              Color(0xEEF3F7FF), // light blue tint
                            ],
                          ),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Handle
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // ✅ HomePage style title + subtitle
                                const SizedBox(height: 6),
                                const Text(
                                  'Choose category to book instantly',
                                  style: TextStyle(
                                    fontSize: 14, // ✅ Home secondary text size
                                    color: Colors.black54,
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // soft divider
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: const Color(0x11000000),
                                ),
                                const SizedBox(height: 14),

                                // Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _labels.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemBuilder: (gridCtx, i) {
                                    return ServiceTile(
                                      label: _labels[i],
                                      assetPath:
                                          'assets/icons/${_iconFiles[i]}',
                                      onTap: () async {
                                        if (!_serviceAreaAvailable) {
                                          _showComingSoonDialog(
                                              "Service not available in your area");
                                          return;
                                        }

                                        final status = _catStatus[i] ?? "live";
                                        if (status != "live") {
                                          _showComingSoonDialog(
                                              "${_labels[i]} is coming soon in $_locArea");
                                          return;
                                        }

                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setInt('last_category', i);

                                        if (!mounted) return;

                                        Navigator.of(context).maybePop();

                                        Future.microtask(() {
                                          switch (i) {
                                            case 0:
                                              _openAcCategorySheet();
                                              break;
                                            case 1:
                                              _openWmCategorySheet();
                                              break;
                                            case 2:
                                              _openRefrigeratorCategorySheet();
                                              break;
                                            case 3:
                                              _openMicrowaveCategorySheet();
                                              break;
                                            case 4:
                                              _openRoCategorySheet();
                                              break;
                                            case 5:
                                              _openTvCategorySheet();
                                              break;
                                            case 6:
                                              _openGeyserCategorySheet();
                                              break;
                                            case 7:
                                              _openChimneyCategorySheet();
                                              break;
                                            case 8:
                                              _openCleaningCategorySheet();
                                              break;
                                            case 9:
                                              _openAirPurifierCategorySheet();
                                              break;
                                            default:
                                              break;
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 100),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  // 🟦 Helper wrappers so search + tiles same functions use karein
  void _openAcCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AC Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0x40000000), // 25% black
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AcCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openWmCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Washing Machine Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: WmCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openRefrigeratorCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Refrigerator Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: h,
                    child: RefrigeratorCategorySheet(
                      height: h,
                      cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                      onClose: () => Navigator.of(ctx).maybePop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openMicrowaveCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Microwave Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: MicrowaveCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openRoCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RO Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: RoCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openTvCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TV Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TvCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openGeyserCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Geyser Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GeyserCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openChimneyCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chimney Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ChimneyCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openCleaningCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cleaning Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) {
              Navigator.of(ctx).maybePop();
            }
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CleaningCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  void _openAirPurifierCategorySheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Air Purifier Category',
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, a1, a2) {
        final mq = MediaQuery.of(ctx);
        const double topGap = 60.0;
        final double h = mq.size.height - topGap;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(ctx).maybePop();
          },
          onPanEnd: (d) {
            if (d.velocity.pixelsPerSecond.dy > 600) {
              Navigator.of(ctx).maybePop();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0x40000000),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 260),
                padding: EdgeInsets.only(
                  top: topGap,
                  left: 8,
                  right: 8,
                  bottom: mq.padding.bottom + 8,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AirPurifierCategorySheet(
                    height: h,
                    cityLabel: _locArea.isNotEmpty ? _locArea : 'Nagpur',
                    onClose: () => Navigator.of(ctx).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 80),
          child: Opacity(opacity: curved, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 👇 kahin bhi tap → sab videos pause
          pauseAllVideoCarousels();
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🔹 Sticky header (location + search + cart)
            SliverPersistentHeader(
              pinned: true,
              delegate: BigHeaderDelegate(
                maxExtentHeight: 170,
                minExtentHeight: 170,
                headerBuilder: (context, t) => _buildHeaderContent(context, t),
              ),
            ),

            // ⬇️ Home Services card directly under search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: HomeServiceIntroCard(
                  onGoToBookNow: _scrollToServices,
                ),
              ),
            ),

            // ⬇️ Warranty banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: const WarrantyBanner(),
              ),
            ),

            // Anchor
            SliverToBoxAdapter(
              child: SizedBox(
                key: _servicesAnchorKey,
                height: 0,
              ),
            ),

            // 🔹 Category grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (c, i) => ServiceTile(
                    label: _labels[i],
                    assetPath: 'assets/icons/${_iconFiles[i]}',
                    onTap: () {
                      if (!_serviceAreaAvailable) {
                        _showComingSoonDialog(
                            "Service not available in your area");
                        return;
                      }

                      final status = _catStatus[i] ?? "live";
                      if (status != "live") {
                        _showComingSoonDialog(
                            "${_labels[i]} is coming soon in $_locArea");
                        return;
                      }
                      if (i == 0) {
                        _openAcCategorySheet();
                      } else if (i == 1) {
                        _openWmCategorySheet();
                      } else if (i == 2) {
                        _openRefrigeratorCategorySheet();
                      } else if (i == 3) {
                        _openMicrowaveCategorySheet();
                      } else if (i == 4) {
                        _openRoCategorySheet();
                      } else if (i == 5) {
                        _openTvCategorySheet();
                      } else if (i == 6) {
                        _openGeyserCategorySheet();
                      } else if (i == 7) {
                        _openChimneyCategorySheet();
                      } else if (i == 8) {
                        _openCleaningCategorySheet();
                      } else if (i == 9) {
                        _openAirPurifierCategorySheet();
                      }
                    },
                  ),
                  childCount: _labels.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 128,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 🔹 Video carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VideoCarousel(
                  height: 200,
                  assetVideos: const [
                    'assets/video/ac_servicing.mp4',
                    'assets/video/washing_machine_1.mp4',
                  ],
                ),
              ),
            ),

            // 🔹 Serving Brands section
            const SliverToBoxAdapter(
              child: ServingBrandsSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context, double t) {
    final safeTop = MediaQuery.of(context).padding.top;
    final double collapse = t.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E6FF2),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(
              ((0x55 / 255) * (0.15 + 0.10 * collapse) * 255).toInt(),
              0,
              0,
              0,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: safeTop + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: Location + Cart
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: _openLocationPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: 0.95 - 0.15 * collapse,
                          child: Text(
                            _locArea,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Opacity(
                          opacity: 0.80 - 0.20 * collapse,
                          child: Text(
                            _locAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const CartButton(),
              ],
            ),
            const SizedBox(height: 12),

            // SEARCH BAR
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    color: Color(0x1A000000),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSearch,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search $_typed',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.search_rounded,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------- ANIMATED SERVING BRANDS SECTION -----------
class ServingBrandsSection extends StatefulWidget {
  const ServingBrandsSection({super.key});

  @override
  State<ServingBrandsSection> createState() => _ServingBrandsSectionState();
}

class _ServingBrandsSectionState extends State<ServingBrandsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F7FF),
                  Color(0xFFE3F2FD),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "We Provide Service For Most Major Brands",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "From refrigerators to ACs, washing machines, microwaves and more.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const Image(
                      image: AssetImage("assets/brands/brands_wall.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Brand names and logos are used only for identification. "
                    "We are an independent service provider and are not "
                    "affiliated with or endorsed by any brand.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------- WARRANTY BANNER -----------
class WarrantyBanner extends StatelessWidget {
  const WarrantyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E6FF2),
              Color(0xFF2E6FF2),
            ],
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Doorabag Warranty",
                    style: TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "100 % Service Warranty",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Free re-visit if issue comes back. No hidden charges.",
                    style: TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromARGB(255, 251, 252, 252),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "WARRANTY",
                    style: TextStyle(
                      color: Color.fromARGB(255, 9, 9, 9),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "ON EVERY REPAIR",
                    style: TextStyle(
                      color: Color.fromARGB(255, 36, 37, 39),
                      fontSize: 8.5,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ----------- HOME SERVICES CARD -----------
class HomeServiceIntroCard extends StatelessWidget {
  final VoidCallback onGoToBookNow;

  const HomeServiceIntroCard({
    super.key,
    required this.onGoToBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Home Services At Your Doorstep",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "We provide the best and certified professional home service at your doorstep.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2E6FF2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onGoToBookNow,
              child: const Text(
                "Go To Book Now",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== 🔍 SERVICE SEARCH DELEGATE ==================
class ServiceSearchDelegate extends SearchDelegate<String> {
  // ignore: library_private_types_in_public_api
  final List<_ServiceEntry> entries;

  ServiceSearchDelegate({required this.entries})
      : super(searchFieldLabel: 'Search services (AC, RO, Fridge...)');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''), // back → empty result
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final lowerQ = query.toLowerCase();

    final filtered = lowerQ.isEmpty
        ? entries
        : entries.where((e) => e.label.toLowerCase().contains(lowerQ)).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No services found for your search'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final e = filtered[index];
        return ListTile(
          title: Text(e.label),
          leading: const Icon(Icons.search),
          onTap: () {
            close(context, e.label);
          },
        );
      },
    );
  }
}
