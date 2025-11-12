class XtreamCategoryDto {
  XtreamCategoryDto({required this.id, required this.name});

  factory XtreamCategoryDto.fromJson(Map<String, dynamic> json) {
    return XtreamCategoryDto(
      id: json['category_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? 'Unknown',
    );
  }

  final String id;
  final String name;
}
