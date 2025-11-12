class SearchPage<T> {
  const SearchPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
