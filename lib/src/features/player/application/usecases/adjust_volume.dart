import 'package:movi/src/features/player/domain/repositories/system_control_repository.dart';

/// Use case pour ajuster le volume système.
/// 
/// Prend un delta (positif ou négatif) et ajuste le volume
/// en conséquence par rapport à la valeur actuelle.
class AdjustVolume {
  AdjustVolume(this._repository);

  final SystemControlRepository _repository;

  /// Ajuste le volume d'un delta donné.
  /// 
  /// [delta] peut être positif (augmenter) ou négatif (diminuer).
  /// La valeur finale sera automatiquement clampée entre 0.0 et 1.0.
  Future<void> call(double delta) async {
    final currentVolume = await _repository.getVolume();
    final newVolume = (currentVolume + delta).clamp(0.0, 1.0);
    await _repository.setVolume(newVolume);
  }
}

