import 'package:equatable/equatable.dart';

class MoviePlaybackVariantDescriptor extends Equatable {
  const MoviePlaybackVariantDescriptor({
    required this.title,
    required this.tags,
  });

  final String title;
  final List<String> tags;

  @override
  List<Object?> get props => <Object?>[title, tags];
}
