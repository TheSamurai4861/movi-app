import 'package:movi/src/features/player/domain/repositories/system_control_repository.dart';

/// Use case pour libérer le contrôle de la luminosité de l'écran.
/// 
/// Libère le contrôle de la luminosité, permettant au système
/// de reprendre le contrôle et à l'utilisateur de modifier
/// la luminosité via le menu système.
class ResetBrightness {
  ResetBrightness(this._repository);

  final SystemControlRepository _repository;

  /// Libère le contrôle de la luminosité.
  Future<void> call() async {
    await _repository.resetBrightness();
  }
}

