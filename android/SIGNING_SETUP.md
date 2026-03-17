# Configuration de la signature pour Movi

Ce guide explique comment configurer la signature de l'application pour les builds release.

## 📋 Prérequis

- Java JDK installé (pour utiliser `keytool`)
- Accès à la ligne de commande

## 🔐 Étape 1 : Générer le keystore

### Option A : Script automatique (recommandé)

**Sur Linux/Mac :**
```bash
chmod +x scripts/generate_keystore.sh
./scripts/generate_keystore.sh
```

**Sur Windows :**

**Option 1 : Script batch (recommandé - fonctionne sans configuration)**
```cmd
scripts\generate_keystore.bat
```

**Option 2 : Script PowerShell (si la politique d'exécution le permet)**
```powershell
# Si vous obtenez une erreur de politique d'exécution, utilisez :
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\scripts\generate_keystore.ps1

# Ou exécutez directement avec bypass :
powershell -ExecutionPolicy Bypass -File .\scripts\generate_keystore.ps1
```

### Option B : Commande manuelle

```bash
keytool -genkeypair -v \
  -keystore android/app/movi-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias movi
```

⚠️ **Important** : Notez bien ces informations :
- Le chemin du fichier `.jks` généré
- Le `storePassword` (mot de passe du keystore)
- Le `keyPassword` (mot de passe de la clé, peut être identique au storePassword)
- L'`alias` (par défaut : `movi`)

## 🔑 Étape 2 : Configurer les variables d'environnement

Vous devez stocker les informations du keystore dans un fichier de propriétés Gradle.

### Option A : Fichier global (recommandé - plus sécurisé)

Créez ou modifiez `~/.gradle/gradle.properties` (dans votre répertoire utilisateur) :

```properties
MOVI_KEYSTORE=/chemin/absolu/vers/android/app/movi-release.jks
MOVI_STORE_PASSWORD=votre_mot_de_passe_keystore
MOVI_ALIAS=movi
MOVI_KEY_PASSWORD=votre_mot_de_passe_cle
```

**Exemple Windows :**
```properties
MOVI_KEYSTORE=C:\Users\matte\Documents\DEV\Flutter\movi-app\android\app\movi-release.jks
MOVI_STORE_PASSWORD=monMotDePasse123
MOVI_ALIAS=movi
MOVI_KEY_PASSWORD=monMotDePasse123
```

**Exemple Linux/Mac :**
```properties
MOVI_KEYSTORE=/home/matte/projects/movi-app/android/app/movi-release.jks
MOVI_STORE_PASSWORD=monMotDePasse123
MOVI_ALIAS=movi
MOVI_KEY_PASSWORD=monMotDePasse123
```

### Option B : Fichier local (moins sécurisé)

Vous pouvez aussi ajouter ces variables dans `android/gradle.properties`, mais **NE COMMITEZ JAMAIS** ce fichier avec les mots de passe !

## ✅ Étape 3 : Vérifier la configuration

La configuration dans `android/app/build.gradle.kts` est déjà correcte :

```kotlin
signingConfigs {
    val keystorePath = project.findProperty("MOVI_KEYSTORE") as String?
    val storePass = project.findProperty("MOVI_STORE_PASSWORD") as String?
    val alias = project.findProperty("MOVI_ALIAS") as String?
    val keyPass = project.findProperty("MOVI_KEY_PASSWORD") as String?
    if (keystorePath != null && storePass != null && alias != null && keyPass != null) {
        create("release") {
            storeFile = file(keystorePath)
            storePassword = storePass
            keyAlias = alias
            keyPassword = keyPass
        }
    }
}

buildTypes {
    getByName("release") {
        val sc = signingConfigs.findByName("release")
        if (sc != null) {
            signingConfig = sc
        }
        // ...
    }
}
```

## 🧪 Étape 4 : Tester le build signé

Testez que le build fonctionne avec la signature :

```bash
flutter build appbundle --release --flavor prod
```

Le fichier `.aab` généré sera automatiquement signé si les variables sont correctement configurées.

## 🔒 Sécurité

⚠️ **IMPORTANT** :
- **NE COMMITEZ JAMAIS** le fichier `.jks` ou `.keystore`
- **NE COMMITEZ JAMAIS** les mots de passe dans `gradle.properties` (sauf si c'est dans `~/.gradle/`)
- Gardez une copie de sauvegarde du keystore dans un endroit sûr
- Si vous perdez le keystore, vous ne pourrez plus mettre à jour l'application sur Play Store !

## 📝 Template

Un fichier template est disponible dans `android/gradle.properties.template` pour référence.

