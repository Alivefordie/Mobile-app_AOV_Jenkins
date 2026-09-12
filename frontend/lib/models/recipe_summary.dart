class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.price,
    required this.status,
    required this.categoryNames,
  });

  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final double price;
  final String status;
  final List<String> categoryNames;

  factory RecipeSummary.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final categories = json['categories'];

    return RecipeSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['shortDescription'] as String? ?? '',
      coverImageUrl: _resolveUrl(json['coverImageUrl'], apiBaseUrl),
      price: double.tryParse(json['price'].toString()) ?? 0,
      status: json['status'] as String? ?? 'draft',
      categoryNames: categories is List
          ? categories
                .whereType<Map<String, dynamic>>()
                .map((category) => category['name'])
                .whereType<String>()
                .toList(growable: false)
          : const [],
    );
  }

  static String? _resolveUrl(Object? value, String apiBaseUrl) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}
