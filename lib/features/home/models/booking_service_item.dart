class BookingServiceItem {
  final int id;
  final String title;
  final String category;
  final int price;

  BookingServiceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
  });

  factory BookingServiceItem.fromJson(Map<String, dynamic> j) {
    return BookingServiceItem(
      id: int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      price: int.tryParse('${j['price']}') ?? 0,
    );
  }
}
