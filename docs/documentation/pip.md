Voici une **documentation complète** (pratique + “copier-coller”) pour intégrer un **PiP système** dans une app **Flutter** sur **Android + iOS**, avec l’objectif précis :

> **Quand l’utilisateur quitte l’app depuis l’écran Player (Home / swipe), la vidéo passe en PiP** et affiche des **contrôles de lecture natifs** (play/pause, etc.).

---

# 0) Important : ce que “PiP avec contrôles natifs” implique

## Android

Le PiP Android est une **Activity** en mode PiP. Le système peut afficher :

* les boutons système (fermer / plein écran),
* **des actions personnalisées** (play/pause/next/prev) que **ton app fournit**. ([Android Developers][1])

👉 Pour des contrôles “vraiment natifs”, il faut généralement :

1. **entrer en PiP** au bon moment (ex: `onUserLeaveHint()`),
2. exposer le contrôle lecture via :

   * **RemoteActions** dans `PictureInPictureParams`, et/ou
   * une **MediaSession (Media3)** connectée à ExoPlayer (recommandé pour compatibilité contrôles système). ([Android Developers][2])

## iOS

Sur iOS, le PiP natif fonctionne très bien si tu utilises **AVPlayerViewController** (lecteur standard Apple) : le PiP et ses contrôles sont gérés par le système. ([Apple Developer][3])
Et tu peux activer le démarrage automatique de PiP en quittant l’app (selon mode/inline) via `canStartPictureInPictureAutomaticallyFromInline`. ([Apple Developer][4])

---

# 1) Stratégie recommandée en Flutter

> Si tu veux PiP **fiable** + **contrôles natifs**, le plus robuste est de **lire la vidéo via des players natifs** (ExoPlayer / AVPlayerViewController) pilotés par Flutter via **MethodChannel**.

Pourquoi ?

* Le plugin Flutter `video_player` n’offre pas un support PiP complet “out of the box” (il y a des demandes/limitations côté plugin). ([GitHub][5])
* Les contrôles PiP natifs sont plus simples quand le player est **natif**.

> Alternative “plug & play” : certains plugins qui wrap AVPlayerViewController + ExoPlayer annoncent PiP/AirPlay (à vérifier selon ton projet). ([Dart packages][6])
> Je te donne ici la version **maîtrisée** (MethodChannel), qui marche dans un projet pro.

---

# 2) Android — Implémentation complète

## 2.1 Pré-requis

* Android 8.0+ (API 26) pour PiP. ([Android Developers][1])
* Une Activity dédiée au playback (souvent recommandé). ([Android Developers][1])

## 2.2 AndroidManifest.xml

Dans ton `AndroidManifest.xml`, sur l’Activity player :

```xml
<activity
    android:name=".player.PlayerActivity"
    android:supportsPictureInPicture="true"
    android:resizeableActivity="true"
    android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation"
    android:launchMode="singleTask"
    android:exported="false" />
```

* `supportsPictureInPicture="true"` + `configChanges` évite que l’activity redémarre en transition PiP. ([Android Developers][1])
* `launchMode="singleTask"` est souvent conseillé pour une seule activity de playback. ([Android Developers][1])

## 2.3 Entrer automatiquement en PiP quand l’utilisateur quitte l’app

Dans `PlayerActivity` (Kotlin) :

```kotlin
override fun onUserLeaveHint() {
    super.onUserLeaveHint()
    if (shouldEnterPip()) {
        enterPipMode()
    }
}

private fun shouldEnterPip(): Boolean {
    // Exemple : vidéo en cours + pas déjà en PiP
    return player?.isPlaying == true && !isInPictureInPictureMode
}
```

Android conseille justement l’entrée en PiP quand l’utilisateur “home/back to browse”. ([Android Developers][1])

## 2.4 Donner des contrôles natifs dans PiP (RemoteActions)

Le PiP peut afficher **des actions custom** fournies par l’app. ([Android Developers][1])
Tu ajoutes des boutons play/pause via `PictureInPictureParams.Builder.setActions(...)`.

### A) BroadcastReceiver (actions)

```kotlin
const val ACTION_PIP_PLAY = "pip_play"
const val ACTION_PIP_PAUSE = "pip_pause"

class PipActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val activity = context as? PlayerActivity ?: return
        when (intent.action) {
            ACTION_PIP_PLAY -> activity.play()
            ACTION_PIP_PAUSE -> activity.pause()
        }
    }
}
```

*(Souvent on fait un receiver indépendant + on communique au player via singleton/service.)*

### B) Construire les RemoteActions

```kotlin
private fun enterPipMode() {
    val aspectRatio = Rational(16, 9)

    val playIntent = PendingIntent.getBroadcast(
        this, 0,
        Intent(ACTION_PIP_PLAY).setPackage(packageName),
        PendingIntent.FLAG_IMMUTABLE
    )
    val pauseIntent = PendingIntent.getBroadcast(
        this, 1,
        Intent(ACTION_PIP_PAUSE).setPackage(packageName),
        PendingIntent.FLAG_IMMUTABLE
    )

    val actionPlay = RemoteAction(
        Icon.createWithResource(this, R.drawable.ic_play),
        "Play", "Play",
        playIntent
    )
    val actionPause = RemoteAction(
        Icon.createWithResource(this, R.drawable.ic_pause),
        "Pause", "Pause",
        pauseIntent
    )

    val params = PictureInPictureParams.Builder()
        .setAspectRatio(aspectRatio)
        .setActions(listOf(if (player?.isPlaying == true) actionPause else actionPlay))
        .build()

    setPictureInPictureParams(params)
    enterPictureInPictureMode(params)
}
```

## 2.5 Recommandé : MediaSession (Media3) + ExoPlayer

Pour une expérience “native” sur Android (contrôles système, cohérence OS), utilise une **MediaSession** connectée à ExoPlayer. ([Android Developers][2])

```kotlin
val player = ExoPlayer.Builder(this).build()
val mediaSession = MediaSession.Builder(this, player).build()
```

Le système peut ainsi envoyer des commandes (play/pause etc.) via les contrôles externes. ([Android Developers][2])

> Tip : si tu veux PiP + playback en arrière-plan propre, place player + session dans un `MediaSessionService` (foreground service) quand nécessaire. ([Android Developers][2])

## 2.6 Masquer l’UI Flutter quand on est en PiP

Dans l’Activity :

```kotlin
override fun onPictureInPictureModeChanged(
    isInPictureInPictureMode: Boolean,
    newConfig: Configuration?
) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    if (isInPictureInPictureMode) {
        // cacher contrôles, overlays, etc.
    } else {
        // restaurer UI
    }
}
```

---

# 3) iOS — Implémentation complète

## 3.1 Capabilities / Background Modes

Dans Xcode (Runner) → **Signing & Capabilities** → **Background Modes** :

* ✅ **Audio, AirPlay, and Picture in Picture**

Apple rappelle qu’il faut configurer audio session + background mode pour PiP propre. ([Apple Developer][7])

## 3.2 Utiliser AVPlayerViewController (recommandé)

C’est le plus simple pour avoir :

* PiP natif,
* contrôles natifs,
* comportement Apple standard. ([Apple Developer][3])

### Swift (PlayerViewController natif)

```swift
import AVKit
import AVFoundation

final class NativePlayerController: NSObject, AVPlayerViewControllerDelegate {
    private let playerVC = AVPlayerViewController()
    private var player: AVPlayer?

    func present(url: URL, from rootVC: UIViewController) {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
        try? audioSession.setActive(true)

        player = AVPlayer(url: url)
        playerVC.player = player
        playerVC.delegate = self
        playerVC.allowsPictureInPicturePlayback = true

        // Pour auto PiP quand l’app passe en background (surtout si inline)
        if #available(iOS 14.0, *) {
            playerVC.canStartPictureInPictureAutomaticallyFromInline = true
        }

        rootVC.present(playerVC, animated: true) {
            self.player?.play()
        }
    }

    // Quand l’utilisateur ferme PiP et veut restaurer l’UI
    func playerViewController(_ playerViewController: AVPlayerViewController,
                              restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Représenter le player si besoin
        completionHandler(true)
    }
}
```

* `AVPlayerViewController` fournit PiP standard. ([Apple Developer][3])
* `canStartPictureInPictureAutomaticallyFromInline` existe et sert à démarrer PiP automatiquement lors du passage en background (selon contexte). ([Apple Developer][4])
* Apple décrit aussi que PiP peut démarrer automatiquement quand la vidéo est en plein écran et que l’utilisateur quitte l’app (standard player). ([Apple Developer][8])

## 3.3 Si tu as un player custom iOS

Tu peux aussi utiliser **AVPictureInPictureController**. ([Apple Developer][9])
Mais pour ton besoin (PiP + contrôles natifs), **AVPlayerViewController** reste le plus direct.

---

# 4) Pont Flutter ↔ Natifs (MethodChannel)

## 4.1 Dart (API simple)

```dart
import 'package:flutter/services.dart';

class NativePip {
  static const _ch = MethodChannel('movi/native_player');

  static Future<void> playUrl(String url) => _ch.invokeMethod('playUrl', {'url': url});

  static Future<void> enterPip() => _ch.invokeMethod('enterPip'); // Android seulement
}
```

## 4.2 Android (Kotlin) — recevoir `playUrl`, lancer PlayerActivity

* `MainActivity` reçoit l’appel `playUrl`, lance `PlayerActivity` avec l’URL.
* `PlayerActivity` contient ExoPlayer + PiP.

## 4.3 iOS (Swift) — recevoir `playUrl`, présenter AVPlayerViewController

Dans `AppDelegate` / `FlutterViewController` :

* `MethodChannel('movi/native_player')`
* sur `playUrl` → `NativePlayerController.present(...)`

---

# 5) UX “le but” : PiP quand on quitte l’écran player

✅ Android : garanti avec `onUserLeaveHint()` + `enterPictureInPictureMode(...)`. ([Android Developers][1])
✅ iOS : avec AVPlayerViewController, PiP est standard et peut démarrer auto selon contexte/param. ([Apple Developer][8])

---

# 6) Checklist de validation

## Android

* [ ] API 26+ device/emulator
* [ ] Activity Player déclarée `supportsPictureInPicture=true` ([Android Developers][1])
* [ ] `onUserLeaveHint()` appelle `enterPipMode()`
* [ ] Actions PiP testées (play/pause)
* [ ] (Recommandé) MediaSession Media3 active ([Android Developers][2])

## iOS

* [ ] Background Modes: Audio/AirPlay/PiP ([Apple Developer][7])
* [ ] AudioSession `.playback`
* [ ] AVPlayerViewController utilisé ([Apple Developer][3])
* [ ] `canStartPictureInPictureAutomaticallyFromInline=true` si tu veux auto-start ([Apple Developer][4])