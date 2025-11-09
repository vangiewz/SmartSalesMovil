import 'product_model.dart';

class ListingResponse {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<ProductModel> results;

  ListingResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.results,
  });

  factory ListingResponse.fromJson(Map<String, dynamic> json) {
    return ListingResponse(
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
      results: (json['results'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
