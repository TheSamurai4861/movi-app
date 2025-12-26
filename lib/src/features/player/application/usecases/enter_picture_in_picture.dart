import 'package:movi/src/features/player/domain/repositories/picture_in_picture_repository.dart';

/// Use case pour entrer en mode Picture-in-Picture
class EnterPictureInPicture {
  EnterPictureInPicture(this._repository);

  final PictureInPictureRepository _repository;

  /// Entre en mode PiP si supporté
  Future<void> call() async {
    if (await _repository.isSupported()) {
      await _repository.enter();
    }
  }
}

