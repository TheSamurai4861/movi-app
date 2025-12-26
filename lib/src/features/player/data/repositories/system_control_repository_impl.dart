import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import 'package:movi/src/features/player/domain/repositories/system_control_repository.dart';

/// Implémentation du contrôle système utilisant les packages Flutter.
class SystemControlRepositoryImpl implements SystemControlRepository {
  SystemControlRepositoryImpl() {
    // Initialisation lazy pour éviter les erreurs au démarrage sur certaines plateformes
    // (ex: Windows peut afficher "Problem getting monitor brightness")
    _volumeController = VolumeController();
    // Initialiser le listener pour obtenir le volume actuel
    _volumeController.listener((volume) {
      _currentVolume = volume;
    });
  }

  ScreenBrightness? _screenBrightness;
  late final VolumeController _volumeController;
  double _currentVolume = 0.5;

  ScreenBrightness get _brightness {
    _screenBrightness ??= ScreenBrightness();
    return _screenBrightness!;
  }

  @override
  Future<double> getBrightness() async {
    try {
      final brightness = await _brightness.current;
      return brightness.clamp(0.0, 1.0);
    } catch (e) {
      // En cas d'erreur, retourner une valeur par défaut
      return 0.5;
    }
  }

  @override
  Future<void> setBrightness(double brightness) async {
    try {
      final clampedBrightness = brightness.clamp(0.0, 1.0);
      await _brightness.setScreenBrightness(clampedBrightness);
    } catch (e) {
      // Ignorer silencieusement les erreurs pour ne pas bloquer l'UI
      // Les erreurs peuvent survenir sur certaines plateformes (ex: Web)
    }
  }

  @override
  Future<void> resetBrightness() async {
    try {
      await _brightness.resetScreenBrightness();
    } catch (e) {
      // Ignorer silencieusement les erreurs pour ne pas bloquer l'UI
      // Les erreurs peuvent survenir sur certaines plateformes (ex: Web)
    }
  }

  @override
  Future<double> getVolume() async {
    try {
      // volume_controller utilise un listener pour obtenir le volume
      // On retourne la dernière valeur connue
      return _currentVolume.clamp(0.0, 1.0);
    } catch (e) {
      // En cas d'erreur, retourner une valeur par défaut
      return 0.5;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      // volume_controller.setVolume retourne void, pas Future<void>
      _volumeController.setVolume(clampedVolume);
    } catch (e) {
      // Ignorer silencieusement les erreurs pour ne pas bloquer l'UI
      // Les erreurs peuvent survenir sur certaines plateformes (ex: Web)
    }
  }
}

