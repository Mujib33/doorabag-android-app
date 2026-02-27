import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'https://doorabag.in';

class BookingServiceRow {
  final int id;
  final String title;
  final String category;
  final int price;

  BookingServiceRow({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
  });

  factory BookingServiceRow.fromJson(Map<String, dynamic> j) {
    return BookingServiceRow(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      price: int.tryParse('${j['price']}') ?? 0,
    );
  }
}

class BookingRatesService {
  // Cache: key = "CITY|CATEGORY"
  final Map<String, List<BookingServiceRow>> _servicesCache = {};
  final Map<String, Map<String, int>> _ratesCache = {}; // title -> price

  String _key(String city, String category) =>
      '${city.trim()}|${category.trim()}';

  /// ✅ NEW: load full list (title + price) from backend
  Future<List<BookingServiceRow>> loadCategoryServices({
    required String city,
    required String category,
    bool forceRefresh = false,
  }) async {
    final k = _key(city, category);
    if (!forceRefresh && _servicesCache.containsKey(k)) {
      return _servicesCache[k]!;
    }

    final uri = Uri.parse(
      '$kBaseUrl/api/booking_citywise_api.php'
      '?category=${Uri.encodeComponent(category.trim())}'
      '&city=${Uri.encodeComponent(city.trim())}',
    );

    debugPrint('API HIT => $uri'); // 👈 add this

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception((data['message'] ?? 'API error').toString());
    }

    final list = (data['data'] as List).cast<dynamic>();
    final services = list
        .map((e) => BookingServiceRow.fromJson(e as Map<String, dynamic>))
        .toList();

    _servicesCache[k] = services;

    // Also build rates cache
    final Map<String, int> rates = {};
    for (final s in services) {
      rates[s.title] = s.price;
    }
    _ratesCache[k] = rates;

    if (kDebugMode) {
      debugPrint('✅ bookingRates loaded: $k -> ${services.length} services');
    }

    return services;
  }

  /// Old-style: only map (title -> price)
  Future<Map<String, int>> loadCategoryRates({
    required String city,
    required String category,
    bool forceRefresh = false,
  }) async {
    final k = _key(city, category);
    if (!forceRefresh && _ratesCache.containsKey(k)) return _ratesCache[k]!;

    await loadCategoryServices(
        city: city, category: category, forceRefresh: forceRefresh);
    return _ratesCache[k] ?? {};
  }

  /// Return cached city-wise price if available else basePrice
  int priceOrBase({
    required String city,
    required String category,
    required String title,
    required int basePrice,
  }) {
    final k = _key(city, category);
    final rates = _ratesCache[k];
    if (rates == null) return basePrice;

    final p = rates[title];
    if (p == null || p <= 0) return basePrice;
    return p;
  }
}

// ✅ Global singleton (same style you were using)
final bookingRates = BookingRatesService();
