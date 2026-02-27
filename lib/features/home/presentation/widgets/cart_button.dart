import 'package:flutter/material.dart';
import '../../../cart/cart_service.dart';
import '../../../cart/cart_page.dart';

class CartButton extends StatefulWidget {
  const CartButton({super.key});

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton> {
  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = CartService.instance.totalCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CartPage()),
              );
            },
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
