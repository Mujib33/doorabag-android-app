// lib/features/checkout/checkout_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateOrderResponse {
  final bool success;
  final String? orderId;
  final String? paymentUrl; // online payment ke liye
  final String? message;

  CreateOrderResponse({
    required this.success,
    this.orderId,
    this.paymentUrl,
    this.message,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> j) {
    return CreateOrderResponse(
      success: j['success'] == true,
      orderId: j['order_id'] as String?,
      paymentUrl: j['payment_url'] as String?,
      message: j['message'] as String?,
    );
  }
}

class CheckoutService {
  CheckoutService._();
  static final CheckoutService instance = CheckoutService._();

  /// NOTE:
  /// Is endpoint ko aap PHP me banayein: /app/api/create_order.php
  /// Input: JSON body with customer/address/slot/items/subtotal/payment_mode
  /// Output JSON:
  /// { "success": true, "order_id": "ORD123", "payment_url": "https://..." }
  final Uri _createOrderUri = Uri.parse(
    'https://www.doorabag.in/app/api/create_order.php',
  );

  Future<CreateOrderResponse> createOrder({
    required Map<String, dynamic> customer,
    required Map<String, dynamic> address,
    required Map<String, dynamic> slot,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required String paymentMode, // "online" | "cod"
    String? couponCode,
    int convenienceFee = 0,
    int discount = 0,
  }) async {
    final body = {
      'source': 'app',
      'customer': customer,
      'address': address,
      'slot': slot,
      'items': items,
      'subtotal': subtotal,
      'payment_mode': paymentMode,
      'coupon': couponCode,
      'convenience_fee': convenienceFee,
      'discount': discount,
    };

    final res = await http.post(
      _createOrderUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CreateOrderResponse.fromJson(data);
    } else {
      return CreateOrderResponse(
        success: false,
        message: 'Server error: ${res.statusCode}',
      );
    }
  }
}
