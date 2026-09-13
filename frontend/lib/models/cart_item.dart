class CartItem {
  const CartItem({
    required this.id,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.price,
  });

  /// id ของแถวใน cart_items ใช้ตอนลบออกจากตะกร้า
  final String id;

  /// id ของสูตร ใช้เช็คว่าการ์ดใบไหนอยู่ในตะกร้าแล้ว
  final String recipeId;

  // ชื่อ รูป ราคา ไม่ได้เก็บใน cart_items แต่ join มาจาก recipe ตอน GET
  final String title;
  final String? imageUrl;
  final double price;

  factory CartItem.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final recipe = json['recipe'] as Map<String, dynamic>? ?? const {};

    return CartItem(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      title: recipe['title'] as String? ?? '',
      imageUrl: _resolveUrl(recipe['coverImageUrl'], apiBaseUrl),
      price: _toDouble(recipe['price']),
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // รูปที่ backend เก็บเป็น path สัมพัทธ์ ต้องเติม host ให้ก่อนถึงโหลดได้
  static String? _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}
