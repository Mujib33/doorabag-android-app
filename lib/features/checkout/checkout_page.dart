// lib/features/checkout/checkout_page.dart — Map + Address sync + Slots + Multi-category split
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:doora_app/features/cart/cart_service.dart';
import 'package:doora_app/features/checkout/widgets/stable_checkout_map.dart';
import 'package:http/http.dart' as http;
import 'package:doora_app/features/checkout/booking_success_page.dart';
// ⬇️ HomePage import HATA diya, ab MainShell use hoga
// import 'package:doora_app/features/home/presentation/home_page.dart';
import 'package:doora_app/main_shell.dart'; // ⭐ MainShell jahan footer hai

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final cart = CartService.instance;

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();

  final _address1Focus = FocusNode();

  bool _loading = true;

  GoogleMapController? _mapController;
  static const LatLng _nagpur = LatLng(21.1458, 79.0882);
  // ignore: unused_field
  LatLng _cameraTarget = _nagpur;
  Timer? _addrDebounce;

  LatLng? _selectedLatLng;
  bool _posting = false;

  DateTime? _slotDate;
  String? _slotTime;

  @override
  void initState() {
    super.initState();
    _prefill();

    _address1.addListener(() {
      _addrDebounce?.cancel();
      _addrDebounce = Timer(const Duration(milliseconds: 600), () async {
        final txt = _address1.text.trim();
        if (txt.length < 5) return;
        await _geocodeFromAddressFields();
      });
    });

    final now = DateTime.now();
    final startIndex = now.hour >= 17 ? 1 : 0;
    _slotDate =
        DateTime(now.year, now.month, now.day).add(Duration(days: startIndex));
  }

  @override
  void dispose() {
    _addrDebounce?.cancel();
    _address1Focus.dispose();
    _name.dispose();
    _mobile.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final p = await SharedPreferences.getInstance();
    _name.text = p.getString('user_name') ?? '';
    _mobile.text = p.getString('user_mobile') ?? '';
    _city.text = p.getString('last_city') ?? '';
    setState(() => _loading = false);
  }

  // ⭐ CITY CHANGE LOGIC: ab yahin se MainShell + pending_sheet set hoga
  Future<void> _applyCityChange(String newCity) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Last city update karo
    await prefs.setString('last_city', newCity);

    // 2) Cart ke LAST item se sheet ke liye category string nikaalo
    //    (HomePage me _openCategorySheetForCity isi string pe switch kar raha hai)
    String pendingCategory = 'ac'; // default

    if (cart.items.isNotEmpty) {
      final String catName = cart.items.last.category;

      switch (catName) {
        case 'AC':
          pendingCategory = 'ac';
          break;
        case 'Washing Machine':
          pendingCategory = 'washing machine';
          break;
        case 'Refrigerator':
          pendingCategory = 'refrigerator';
          break;
        case 'Microwave':
          pendingCategory = 'microwave';
          break;
        case 'RO':
          pendingCategory = 'ro';
          break;
        case 'TV':
          pendingCategory = 'tv';
          break;
        case 'Geyser':
          pendingCategory = 'geyser';
          break;
        case 'Chimney':
          pendingCategory = 'chimney';
          break;
        case 'Cleaning':
          pendingCategory = 'cleaning';
          break;
        default:
          pendingCategory = 'ac';
          break;
      }
    }

    // 3) HomePage ke liye pending sheet info store karo
    await prefs.setString('pending_sheet_category', pendingCategory);
    await prefs.setString('pending_sheet_city', newCity);

    // 4) City change pe cart clear
    CartService.instance.clear();

    // 5) HAMESHA MainShell ko root bana do (footer isi me hai)
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
    // HomePage initState me _openPendingSheetIfAny() chalega → sheet auto open
  }

  // ---------------- MAP + LOCATION -----------------
  Future<void> _locateMe() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location service')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final newPos = LatLng(pos.latitude, pos.longitude);

    // Map center + pin location
    _selectedLatLng = newPos;
    _cameraTarget = newPos;

    await _animateTo(newPos, zoom: 17);
    await _updateAddressFromLatLng(newPos);

    setState(() {});
  }

  Future<void> _animateTo(LatLng target, {double zoom = 16}) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _updateAddressFromLatLng(LatLng pos) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _address1.text = [
            if ((p.name ?? '').isNotEmpty) p.name,
            if ((p.subLocality ?? '').isNotEmpty) p.subLocality,
            if ((p.locality ?? '').isNotEmpty) p.locality,
          ].whereType<String>().join(', ');
          _city.text = p.locality ?? _city.text;
          _pincode.text = p.postalCode ?? _pincode.text;
        });
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }
  }

  Future<void> _geocodeFromAddressFields() async {
    final addr = _address1.text.trim();
    final city = _city.text.trim();
    final query = [addr, city].where((e) => e.isNotEmpty).join(', ');
    if (query.isEmpty) return;
    try {
      final list = await locationFromAddress(query);
      if (list.isNotEmpty) {
        final loc = list.first;
        final point = LatLng(loc.latitude, loc.longitude);
        _cameraTarget = point;
        await _animateTo(point, zoom: 17);
        _selectedLatLng = point;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Manual geocode failed: $e');
    }
  }

  // ---------------- SLOTS HELPERS -----------------
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  static const List<String> _slotTimes = [
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

  static const Map<String, double> _timeToHour = {
    "08:00 AM": 8,
    "08:30 AM": 8.5,
    "09:00 AM": 9,
    "09:30 AM": 9.5,
    "10:00 AM": 10,
    "10:30 AM": 10.5,
    "11:00 AM": 11,
    "11:30 AM": 11.5,
    "12:00 PM": 12,
    "12:30 PM": 12.5,
    "01:00 PM": 13,
    "01:30 PM": 13.5,
    "02:00 PM": 14,
    "02:30 PM": 14.5,
    "03:00 PM": 15,
    "03:30 PM": 15.5,
    "04:00 PM": 16,
    "04:30 PM": 16.5,
    "05:00 PM": 17,
    "05:30 PM": 17.5,
    "06:00 PM": 18,
    "06:30 PM": 18.5,
    "07:00 PM": 19,
    "07:30 PM": 19.5,
    "08:00 PM": 20,
  };

  List<String> _availableTimesFor(DateTime d) {
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (!isToday) return _slotTimes;

    final nowHourExact = now.hour + (now.minute / 60.0);
    if (nowHourExact > 19.0) return [];

    return _slotTimes
        .where((t) => (_timeToHour[t] ?? 0) > nowHourExact)
        .toList();
  }

  // ---------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ignore: unused_local_variable
    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : Colors.white;
    final border = cs.outline.withValues(alpha: 0.18);
    final shadow = cs.shadow.withValues(alpha: isDark ? 0.20 : 0.30);
    final titleColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final primary = cs.primary;

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _CheckoutHeader(
                  primary: primary,
                  titleColor: Colors.white,
                  subtitleColor: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryCard(
                            cart: cart,
                            cardBg: cardBg,
                            border: border,
                            shadow: shadow,
                            titleColor: titleColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Customer Details', color: titleColor),
                          const SizedBox(height: 8),
                          _Input(
                            label: 'Full Name',
                            controller: _name,
                            color: textColor,
                          ),
                          _Input(
                            label: 'Mobile Number',
                            controller: _mobile,
                            keyboardType: TextInputType.phone,
                            color: textColor,
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Location', color: titleColor),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _locateMe,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Locate Me'),
                          ),
                          const SizedBox(height: 12),
                          StableCheckoutMap(
                            apiKey: 'AIzaSyBoU-gf0J0ZeIDcW1Rl56vierhhgzFwoc4',
                            onChanged: (latLng) async {
                              _selectedLatLng = latLng;
                              _cameraTarget = latLng;

                              try {
                                final placemarks =
                                    await placemarkFromCoordinates(
                                  latLng.latitude,
                                  latLng.longitude,
                                );

                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;

                                  _address1.text = [
                                    if ((p.name ?? '').isNotEmpty) p.name,
                                    if ((p.subLocality ?? '').isNotEmpty)
                                      p.subLocality,
                                    if ((p.locality ?? '').isNotEmpty)
                                      p.locality,
                                  ].join(', ');

                                  _city.text = p.locality ?? _city.text;
                                  _pincode.text = p.postalCode ?? _pincode.text;
                                }
                              } catch (e) {
                                debugPrint('Reverse geocode failed: $e');
                              }

                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Preferred Visit', color: titleColor),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 54,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final base = DateTime.now();
                                final startIndex =
                                    DateTime.now().hour >= 17 ? 1 : 0;
                                final d =
                                    DateTime(base.year, base.month, base.day)
                                        .add(Duration(days: startIndex + i));
                                final isSelected = _slotDate != null &&
                                    _slotDate!.year == d.year &&
                                    _slotDate!.month == d.month &&
                                    _slotDate!.day == d.day;
                                return ChoiceChip(
                                  label: Text(
                                    '${_dayLabel(d)}  ${d.day.toString().padLeft(2, '0')}',
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _slotDate = d;
                                      _slotTime = null;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (_) {
                              final d = _slotDate ?? DateTime.now();
                              final times = _availableTimesFor(d);
                              return times.isEmpty
                                  ? Text(
                                      'No slots available',
                                      style: TextStyle(color: subTextColor),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: times.map((t) {
                                        final sel = _slotTime == t;
                                        return ChoiceChip(
                                          label: Text(t),
                                          selected: sel,
                                          onSelected: (_) =>
                                              setState(() => _slotTime = t),
                                        );
                                      }).toList(),
                                    );
                            },
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Address', color: titleColor),
                          const SizedBox(height: 8),
                          _Input(
                            label: 'Address Line 1',
                            controller: _address1,
                            color: textColor,
                          ),
                          _Input(
                            label: 'Apartment / Flat No. / Plot No. (optional)',
                            controller: _address2,
                            color: textColor,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _Input(
                                  label: 'City',
                                  controller: _city,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Input(
                                  label: 'Pincode',
                                  controller: _pincode,
                                  keyboardType: TextInputType.number,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Payment Mode', color: titleColor),
                          const SizedBox(height: 8),
                          _Pill(
                            label: 'Pay After Service',
                            bg: cardBg,
                            border: border,
                            textColor: textColor,
                            iconColor: titleColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                        color: cs.shadow.withValues(
                          alpha: isDark ? 0.25 : 0.30,
                        ),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total payable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${cart.subtotal}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You pay directly to the technician after service.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.82),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: (_posting || cart.items.isEmpty)
                                ? null
                                : _placeOrder,
                            child: _posting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Place Order',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                      ),
                                    ],
                                  ),
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

  // ---------------- PLACE ORDER (CITY CHECK + CLEAN VERSION) -----------------
  Future<void> _placeOrder() async {
    // ---------- Basic validations ----------
    if (_name.text.trim().isEmpty || _mobile.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid name & mobile')),
      );
      return;
    }
    if (_address1.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full address & city')),
      );
      return;
    }
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick your location on map')),
      );
      return;
    }
    if (_slotDate == null || _slotTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select preferred date & time')),
      );
      return;
    }

    // ---------- City mismatch check (cart vs entered city) ----------
    if (cart.items.isNotEmpty) {
      final enteredCity = _city.text.trim();
      final cartCities = cart.items
          .map((it) => it.city.trim())
          .where((c) => c.isNotEmpty)
          .toSet();

      if (enteredCity.isNotEmpty &&
          cartCities.isNotEmpty &&
          !cartCities.contains(enteredCity)) {
        // Show dialog
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final Color primary = Theme.of(context).colorScheme.primary;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Are you really want to change city?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'NO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Popup band karo
                              Navigator.of(ctx).pop();

                              // ✅ Ab city change apply karo → MainShell + pending sheet
                              final String selectedCity = _city.text.trim();
                              _applyCityChange(selectedCity);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'YES',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
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

        // 🔥 Always STOP here. DO NOT continue with checkout.
        return;
      }
    }

    // ---------- All good, place order (category-wise split) ----------
    setState(() => _posting = true);

    final Map<String, List<CartItem>> byCat = {};
    for (final it in cart.items) {
      byCat.putIfAbsent(it.category, () => []).add(it);
    }

    final createdIds = <String>[];

    try {
      for (final entry in byCat.entries) {
        final category = entry.key;
        final items = entry.value;

        final subtotalForCat =
            items.fold<int>(0, (s, it) => s + it.price * it.qty);

        final payload = {
          'name': _name.text.trim(),
          'mobile': _mobile.text.trim(),
          'address1': _address1.text.trim(),
          'address2': _address2.text.trim(),
          'city': _city.text.trim(),
          'pincode': _pincode.text.trim(),
          'lat': _selectedLatLng!.latitude.toStringAsFixed(6),
          'lng': _selectedLatLng!.longitude.toStringAsFixed(6),
          'payment_mode': 'Cash',
          'subtotal': subtotalForCat.toString(),
          'booking_date': _fmtDate(_slotDate!),
          'booking_time': _slotTime,
          'items': items
              .map((it) => {
                    'title': it.title,
                    'price': it.price,
                    'qty': it.qty,
                    'category': it.category,
                    'city': it.city,
                  })
              .toList(),
        };

        final url = Uri.parse('https://www.doorabag.in/api/create_order.php');

        http.Response res;
        try {
          res = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          throw Exception('Network error: $e');
        }

        if (res.statusCode != 200) {
          throw Exception('HTTP ${res.statusCode} (category: $category)');
        }

        final raw = utf8.decode(res.bodyBytes).trimLeft();
        final start = raw.indexOf('{');
        if (start == -1) {
          throw Exception('Server did not return JSON (category: $category)');
        }
        final data = jsonDecode(raw.substring(start)) as Map<String, dynamic>;

        final ok = data['success'] == true || data['success'] == 'true';
        if (!ok) {
          throw Exception(
            (data['message'] ?? 'Order failed') + ' (category: $category)',
          );
        }

        if (data['order_ids'] != null) {
          final list =
              List.from(data['order_ids']).map((e) => e.toString()).toList();
          createdIds.addAll(list);
        } else if (data['order_id'] != null) {
          createdIds.add(data['order_id'].toString());
        } else {
          createdIds.add('(no id)');
        }
      }

      if (!mounted) return;

      cart.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            orderIds: createdIds,
            bookingDate: _fmtDate(_slotDate!),
            bookingTime: _slotTime!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }
}

// ---------------------------------------------------------------------------
// PRIVATE UI WIDGETS
// ---------------------------------------------------------------------------

class _CheckoutHeader extends StatelessWidget {
  final Color primary;
  final Color titleColor;
  final Color subtitleColor;

  const _CheckoutHeader({
    required this.primary,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confirm address & time for your service',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CartService cart;
  final Color cardBg;
  final Color border;
  final Color shadow;
  final Color titleColor;
  final Color textColor;
  final Color subTextColor;

  const _SummaryCard({
    required this.cart,
    required this.cardBg,
    required this.border,
    required this.shadow,
    required this.titleColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = cart.items;
    final int total = cart.subtotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: shadow,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.take(3).map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          it.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '×${it.qty}',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${it.price * it.qty}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${items.length - 3} more item(s)',
                style: TextStyle(fontSize: 11, color: subTextColor),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total payable',
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                ),
              ),
              const Spacer(),
              Text(
                '₹$total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Color color;

  const _Input({
    required this.label,
    required this.controller,
    this.keyboardType,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: color, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: cs.outline.withValues(alpha: 0.9),
            fontSize: 13,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outline.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color border;
  final Color textColor;
  final Color iconColor;

  const _Pill({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
