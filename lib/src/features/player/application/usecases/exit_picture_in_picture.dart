import 'package:movi/src/features/player/domain/repositories/picture_in_picture_repository.dart';

/// Use case pour sortir du mode Picture-in-Picture
class ExitPictureInPicture {
  ExitPictureInPicture(this._repository);

  final PictureInPictureRepository _repository;

  /// Sort du mode PiP
  Future<void> call() async {
    await _repository.exit();
  }
}

