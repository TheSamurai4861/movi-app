import 'package:movi/src/features/player/domain/repositories/system_control_repository.dart';

/// Use case pour ajuster la luminosité de l'écran.
/// 
/// Prend un delta (positif ou négatif) et ajuste la luminosité
/// en conséquence par rapport à la valeur actuelle.
class AdjustBrightness {
  AdjustBrightness(this._repository);

  final SystemControlRepository _repository;

  /// Ajuste la luminosité d'un delta donné.
  /// 
  /// [delta] peut être positif (augmenter) ou négatif (diminuer).
  /// La valeur finale sera automatiquement clampée entre 0.0 et 1.0.
  Future<void> call(double delta) async {
    final currentBrightness = await _repository.getBrightness();
    final newBrightness = (currentBrightness + delta).clamp(0.0, 1.0);
    await _repository.setBrightness(newBrightness);
  }
}

