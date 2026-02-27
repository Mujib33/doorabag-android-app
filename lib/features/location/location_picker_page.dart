import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

// 👇 Yahan apni REAL Google API key daalo (jo Maps + Places ke liye enabled hai)
const String kGoogleApiKey = 'AIzaSyBoU-gf0J0ZeIDcW1Rl56vierhhgzFwoc4';

class LocationResult {
  final double lat;
  final double lng;
  final String address;

  LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _userLatLng; // bias for nearby suggestions

  // Default: Nagpur
  static const LatLng _defaultLatLng = LatLng(21.1458, 79.0882);

  LatLng _cameraTarget = _defaultLatLng;
  LatLng? _pickedLatLng;
  String _addressLine = 'Tap on map to select your location';

  // ---- Search / autocomplete state ----
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _isProgrammaticChange = false;

  List<_PlacePrediction> _predictions = [];

  @override
  void initState() {
    super.initState();

    _searchController.text = _addressLine;
    _searchController.addListener(_onSearchTextChanged);

    // ✅ ADD THIS: focus change par rebuild
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });

    _initCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ---------------- LOCATION / MAP ----------------

  Future<void> _initCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _addressLine = 'Location services are disabled';
          _setSearchText(_addressLine);
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _addressLine = 'Location permission denied';
          _setSearchText(_addressLine);
        });
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng latLng = LatLng(pos.latitude, pos.longitude);
      _userLatLng = latLng;
      _cameraTarget = latLng;
      _pickedLatLng = latLng;

      final controller = await _mapController.future;
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );

      await _reverseGeocode(latLng);
    } catch (e) {
      setState(() {
        _addressLine = 'Could not get current location';
        _setSearchText(_addressLine);
      });
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];

        if ((p.name ?? '').isNotEmpty) parts.add(p.name!);
        if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
        if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
        if ((p.administrativeArea ?? '').isNotEmpty) {
          parts.add(p.administrativeArea!);
        }
        if ((p.postalCode ?? '').isNotEmpty) parts.add(p.postalCode!);

        final line = parts.join(', ');

        setState(() {
          _addressLine = line.isNotEmpty ? line : 'Selected location';
          _setSearchText(_addressLine);
        });
      }
    } catch (_) {
      setState(() {
        _addressLine = 'Selected location';
        _setSearchText(_addressLine);
      });
    } finally {
      if (mounted) {}
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
  }

  void _onMarkerDragEnd(LatLng latLng) {
    setState(() {
      _pickedLatLng = latLng;
      _cameraTarget = latLng;
      _userLatLng = latLng; // next search nearby from here
    });
    _reverseGeocode(latLng);
  }

  void _confirmLocation() {
    if (_pickedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on map')),
      );
      return;
    }

    final result = LocationResult(
      lat: _pickedLatLng!.latitude,
      lng: _pickedLatLng!.longitude,
      address: _addressLine,
    );

    Navigator.of(context).pop(result);
  }

  // ---------------- SEARCH + AUTOCOMPLETE ----------------

  void _setSearchText(String text) {
    _isProgrammaticChange = true;
    _searchController.text = text;
    _searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: text.length));
    _isProgrammaticChange = false;
  }

  void _onSearchTextChanged() {
    if (_isProgrammaticChange) return;

    // ✅ Clear icon show/hide ke liye rebuild
    if (mounted) setState(() {});

    final input = _searchController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    // Debounce to avoid too many API calls
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (input.length < 3) {
        setState(() {
          _predictions = [];
        });
        return;
      }
      _fetchAutocomplete(input);
    });
  }

  Future<void> _fetchAutocomplete(String input) async {
    try {
      final params = <String, String>{
        'input': input,
        'key': kGoogleApiKey,
        'types': 'geocode',
        'components': 'country:in', // sirf India
      };

      // nearby bias from user location / current pin
      if (_userLatLng != null) {
        params['location'] =
            '${_userLatLng!.latitude},${_userLatLng!.longitude}';
        params['radius'] = '10000'; // ~10 km
      }

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        params,
      );

      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        setState(() {
          _predictions = [];
        });
        return;
      }

      final preds = (data['predictions'] as List)
          .map((e) => _PlacePrediction.fromJson(e))
          .toList();

      setState(() {
        _predictions = preds;
      });
    } catch (_) {
      // ignore (no suggestions)
    }
  }

  Future<void> _onPredictionTap(_PlacePrediction p) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _predictions = [];
      _addressLine = p.description;
      _setSearchText(p.description);
    });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        <String, String>{
          'place_id': p.placeId,
          'key': kGoogleApiKey,
          'fields': 'geometry',
        },
      );

      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        return;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        return;
      }

      final loc = data['result']['geometry']['location'];
      final latLng = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );

      setState(() {
        _userLatLng = latLng;
        _pickedLatLng = latLng;
        _cameraTarget = latLng;
      });

// ✅ Map platform view ko 1 frame do
      await Future.delayed(const Duration(milliseconds: 120));

      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }

// ✅ reverse geocode after camera move
      await _reverseGeocode(latLng);
    } catch (_) {
      // ignore error
    } finally {
      if (mounted) {}
    }
  }

  // ---------------- UI ----------------
  static const Color kText = Color(0xFF0B1220);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ ADD THIS
      backgroundColor: const Color(0xFFF2F2F7), // iOS-style grey
      appBar: AppBar(
        backgroundColor: const Color(0xEBFFFFFF), // 92% white
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: kText,
        centerTitle: true,
        title: const Text(
          'Choose Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F8FC),
                Color(0xFFF2F2F7),
              ],
            ),
          ),
          child: Column(
            children: [
              // 🔹 TOP SCROLLABLE CONTENT (address + suggestions)
              // ✅ TOP CONTENT (NO Expanded) + safe height using Flexible
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // 🔹 Address card (glossy)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xEBFFFFFF), // 92% white
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFE6E8EF)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 20,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Selected location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // ✅ SEARCH PILL (fixed radius + focus border + perfect height)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          child: Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF7F7FA),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      28), // ✅ same as ClipRRect
                                              border: Border.all(
                                                color: _searchFocus.hasFocus
                                                    ? const Color(
                                                        0xFF2563EB) // 🔵 focus blue
                                                    : const Color(0xFFE5E7EB),
                                                width: 1.6,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                    14), // ✅ no vertical padding
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _searchController,
                                                    focusNode: _searchFocus,
                                                    maxLines: 1,
                                                    textInputAction:
                                                        TextInputAction.search,
                                                    cursorColor:
                                                        const Color(0xFF2563EB),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Color(0xFF0B1220),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: -0.2,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'Search or enter address',
                                                      hintStyle: TextStyle(
                                                        color:
                                                            Color(0xFF9CA3AF),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      border: InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              vertical:
                                                                  14), // ✅ center text
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                if (_searchController.text
                                                    .trim()
                                                    .isNotEmpty)
                                                  InkWell(
                                                    onTap: () {
                                                      _searchController.clear();
                                                      setState(() =>
                                                          _predictions = []);
                                                      FocusScope.of(context)
                                                          .requestFocus(
                                                              _searchFocus);
                                                    },
                                                    child: Container(
                                                      height: 38,
                                                      width: 38,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFF3F4F6),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFE5E7EB)),
                                                      ),
                                                      child: const Icon(
                                                        Icons.close_rounded,
                                                        size: 18,
                                                        color:
                                                            Color(0xFF6B7280),
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 🔹 Suggestions
                      if (_predictions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xF5FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6E8EF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _predictions.length,
                            itemBuilder: (_, i) {
                              final p = _predictions[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.place_outlined,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                                title: Text(
                                  p.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF0B1220),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                onTap: () => _onPredictionTap(p),
                              );
                            },
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFEDEFF5),
                            ),
                          ),
                        ),

                      // 🔹 Use current location
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _initCurrentLocation,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF2563EB),
                            ),
                            icon:
                                const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text(
                              'Use current location',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔹 MAP (glossy card + floating button)
              SizedBox(
                height: (MediaQuery.of(context).viewInsets.bottom > 0)
                    ? MediaQuery.of(context).size.height * 0.32
                    : MediaQuery.of(context).size.height * 0.45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _cameraTarget,
                            zoom: 16,
                          ),
                          onMapCreated: _onMapCreated,
                          markers: {
                            if (_pickedLatLng != null)
                              Marker(
                                markerId: const MarkerId('picked'),
                                position: _pickedLatLng!,
                                draggable: true,
                                onDragEnd: _onMarkerDragEnd,
                              ),
                          },
                          zoomControlsEnabled: false,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                        ),

                        // subtle top fade
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              height: 44,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x22000000),
                                    Color(0x00000000)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // floating iOS button
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Material(
                                color: const Color(0xCCFFFFFF), // 80% white
                                child: InkWell(
                                  onTap: _initCurrentLocation,
                                  child: const SizedBox(
                                    height: 44,
                                    width: 44,
                                    child: Icon(
                                      Icons.near_me_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                ),
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

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------

class _PlacePrediction {
  final String description;
  final String placeId;

  _PlacePrediction({
    required this.description,
    required this.placeId,
  });

  factory _PlacePrediction.fromJson(Map<String, dynamic> json) {
    return _PlacePrediction(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
    );
  }
}
