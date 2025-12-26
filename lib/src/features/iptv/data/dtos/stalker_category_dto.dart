class StalkerCategoryDto {
  StalkerCategoryDto({
    required this.id,
    required this.title,
    this.alias,
    this.censored,
  });

  factory StalkerCategoryDto.fromJson(Map<String, dynamic> json) {
    return StalkerCategoryDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      alias: json['alias']?.toString(),
      censored: json['censored'] == 1 || json['censored'] == true,
    );
  }

  final String id;
  final String title;
  final String? alias;
  final bool? censored;
}

