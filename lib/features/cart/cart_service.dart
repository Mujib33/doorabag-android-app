import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  // Internal list
  final List<CartItem> _items = [];

  // Public accessor – NORMAL list (no unmodifiable wrapper)
  List<CartItem> get items => _items;

  // Total amount (₹)
  int get subtotal => _items.fold(0, (sum, it) => sum + it.price * it.qty);

  // ⭐ Ye hi use ho raha hai: final count = CartService.instance.totalCount;
  int get totalCount => _items.fold(0, (sum, it) => sum + it.qty);

  // CRUD operations
  void add(CartItem it) {
    _items.add(it);
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void increment(int index) {
    _items[index].qty++;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].qty > 1) {
      _items[index].qty--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // ⭐ Checkout ke baad cart साफ करने के लिए
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class CartItem {
  CartItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.category,
    required this.city,
    this.qty = 1,
  });

  String title;
  String subtitle;
  String image;
  String category;
  String city;
  int price;
  int qty;
}
