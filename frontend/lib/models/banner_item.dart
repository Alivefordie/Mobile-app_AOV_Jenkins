/// แบนเนอร์ด้านบนของหน้า Home (มีแค่ id กับรูป)
class BannerItem {
  const BannerItem({required this.id, required this.imageUrl});

  final String id;
  final String imageUrl;

  factory BannerItem.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    return BannerItem(
      id: json['id'].toString(),
      imageUrl: _resolveUrl(json['imageUrl'] ?? json['image_url'], apiBaseUrl),
    );
  }

  /// รูปที่เก็บเป็น path สั้น ๆ (เช่น /uploads/images/a.jpg) ต้องต่อ base url ให้ครบก่อน
  static String _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return '';
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}
