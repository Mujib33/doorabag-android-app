// lib/features/checkout/widgets/stable_checkout_map.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Center-fixed pin + Google-like search (Places Autocomplete) with
/// a clean, iOS-style premium look.
class StableCheckoutMap extends StatefulWidget {
  const StableCheckoutMap({
    super.key,
    required this.apiKey,
    this.height = 300,
    this.countryCode = 'in', // restrict autocomplete (optional)
    this.onChanged,
  });

  final String apiKey; // ← Places/Maps key
  final double height;
  final String countryCode;
  final ValueChanged<LatLng>? onChanged;

  @override
  State<StableCheckoutMap> createState() => _StableCheckoutMapState();
}

class _StableCheckoutMapState extends State<StableCheckoutMap> {
  GoogleMapController? _ctrl;
  static const _fallback = LatLng(21.1458, 79.0882); // Nagpur

  LatLng _cameraTarget = _fallback;
  LatLng? _userLocation; // last known user location
  bool _ready = false;

  // search state
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _deb;
  String _sessionToken = _newToken();
  List<_Suggestion> _sugs = [];
  bool _loadingSugs = false;

  @override
  void initState() {
    super.initState();
    _init();
    _search.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      // focus change → rebuild, taki suggestion panel hide/show ho
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _searchFocus.dispose();
    _deb?.cancel();
    super.dispose();
  }

  static String _newToken() {
    final r = Random();
    return List.generate(24, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  Future<void> _init() async {
    // Permissions (optional – blue dot ke liye)
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      _cameraTarget = here;
      _userLocation = here;
    } catch (_) {
      // fallback Nagpur
      _cameraTarget = _fallback;
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  // ── AUTOCOMPLETE ────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 350), () async {
      final q = _search.text.trim();
      if (q.length < 2) {
        setState(() => _sugs = []);
        return;
      }
      setState(() => _loadingSugs = true);
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(q)}'
          '&sessiontoken=$_sessionToken'
          '&components=country:${widget.countryCode}'
          '&key=${widget.apiKey}',
        );

        final res = await http.get(url).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
        final data = json.decode(res.body) as Map<String, dynamic>;
        if ((data['status'] ?? '') != 'OK') {
          throw Exception(
            'Places status: ${data['status']} '
            '${data['error_message'] ?? ''}',
          );
        }

        final preds = (data['predictions'] as List?) ?? [];
        setState(() {
          _sugs = preds.map((e) => _Suggestion.fromJson(e)).toList();
        });
      } catch (e) {
        setState(() => _sugs = []);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Places error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loadingSugs = false);
        }
      }
    });
  }

  Future<void> _chooseSuggestion(_Suggestion s) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(s.placeId)}'
        '&fields=geometry,name,formatted_address'
        '&sessiontoken=$_sessionToken'
        '&key=${widget.apiKey}',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      if ((data['status'] ?? '') != 'OK') {
        throw Exception(
          'Places status: ${data['status']} '
          '${data['error_message'] ?? ''}',
        );
      }

      final loc = data['result']?['geometry']?['location'];
      if (loc != null) {
        final target = LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
        _cameraTarget = target;

        await _ctrl?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16),
          ),
        );

        widget.onChanged?.call(target);

        // nayi session start karo (Google pricing best-practice)
        _sessionToken = _newToken();
        _searchFocus.unfocus();
        setState(() => _sugs = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Places details error: $e')),
        );
      }
    }
  }

  // ── RECENTER TO CURRENT LOCATION (for FAB) ──────────────────────────────────

  Future<void> _recenterToMyLocation() async {
    try {
      // agar pehle se user location hai to pehle ussi pe try karo
      if (_userLocation != null) {
        _cameraTarget = _userLocation!;
        await _ctrl?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _cameraTarget, zoom: 16),
          ),
        );
        widget.onChanged?.call(_cameraTarget);
        return;
      }

      // warna fresh GPS lo
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      _userLocation = here;
      _cameraTarget = here;

      await _ctrl?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: here, zoom: 16),
        ),
      );
      widget.onChanged?.call(here);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch current location: $e')),
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    if (!_ready) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final showSuggestions =
        _searchFocus.hasFocus && (_loadingSugs || _sugs.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                initialCameraPosition:
                    CameraPosition(target: _cameraTarget, zoom: 15),
                onMapCreated: (c) => _ctrl = c,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onCameraMove: (pos) => _cameraTarget = pos.target,
                onCameraIdle: () => widget.onChanged?.call(_cameraTarget),
              ),

              // Center-fixed pin (iOS-ish, primary color)
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 38,
                      color: primary,
                    ),
                    Container(
                      width: 10,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),

              // Top search bar + suggestions
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Column(
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 7,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search area, society, landmark…',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (showSuggestions)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: Material(
                          color: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                          child: _loadingSugs
                              ? const SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: _sugs.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final s = _sugs[i];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.place_outlined,
                                        color: primary,
                                      ),
                                      title: Text(
                                        s.mainText,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        s.secondaryText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      onTap: () => _chooseSuggestion(s),
                                    );
                                  },
                                ),
                        ),
                      ),
                  ],
                ),
              ),

              // Recenter button (iOS-style white pill)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _recenterToMyLocation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Suggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;

  _Suggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory _Suggestion.fromJson(Map<String, dynamic> j) {
    final st = (j['structured_formatting'] ?? {}) as Map<String, dynamic>;
    return _Suggestion(
      placeId: j['place_id'] as String,
      mainText: (st['main_text'] ?? j['description']) as String,
      secondaryText: (st['secondary_text'] ?? '') as String,
    );
  }
}
