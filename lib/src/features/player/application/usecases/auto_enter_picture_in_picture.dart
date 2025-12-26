import 'package:movi/src/features/player/domain/repositories/picture_in_picture_repository.dart';

/// Use case pour entrer automatiquement en mode Picture-in-Picture.
/// 
/// Vérifie les conditions nécessaires (vidéo en lecture, PiP supporté, pas déjà en PiP)
/// avant d'entrer en PiP.
class AutoEnterPictureInPicture {
  AutoEnterPictureInPicture(
    this._pipRepository,
  );

  final PictureInPictureRepository _pipRepository;

  /// Entre automatiquement en PiP si les conditions sont remplies.
  /// 
  /// [isPlaying] : true si la vidéo est actuellement en lecture
  Future<void> call(bool isPlaying) async {
    // Ne pas entrer en PiP si la vidéo n'est pas en lecture
    if (!isPlaying) return;

    // Vérifier si le PiP est supporté
    if (!await _pipRepository.isSupported()) return;

    // Entrer en PiP
    await _pipRepository.enter();
  }
}

