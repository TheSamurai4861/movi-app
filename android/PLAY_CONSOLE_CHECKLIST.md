# Checklist Play Console - Points critiques

## ✅ Configuration technique (déjà fait)

- [x] ProGuard/R8 configuré avec `proguard-rules.pro`
- [x] Signature release configurée (support variables d'environnement + gradle.properties)
- [x] Version définie dans `pubspec.yaml` : `1.0.0+1`
- [x] Build type release avec minification et shrink resources

## ⚠️ Points à vérifier avant soumission

### 1. Politique de confidentialité (OBLIGATOIRE)

**Action requise :**
- Créer une page web avec votre politique de confidentialité
- URL accessible publiquement
- Doit couvrir :
  - Types de données collectées (même si c'est "aucune")
  - Utilisation des données
  - Partage avec des tiers
  - Droits des utilisateurs (RGPD si applicable)

**Exemple de contenu minimal :**
```
- Aucune donnée personnelle n'est collectée automatiquement
- Les données de connexion (email) sont stockées via Supabase
- Les préférences utilisateur sont stockées localement
- Aucun partage avec des tiers pour la publicité
```

### 2. Data Safety (Play Console)

**Dans Play Console → Politique de l'app → Sécurité des données :**

Déclarez :
- ✅ **Données collectées** : 
  - Identifiants (email) - nécessaire pour l'authentification
  - Données de profil (nom, avatar) - stockées localement et sur Supabase
- ✅ **Données partagées** : 
  - Avec Supabase (hébergement backend) - nécessaire au fonctionnement
- ✅ **Pratiques de sécurité** : 
  - Chiffrement des données en transit (HTTPS)
  - Authentification requise pour accéder aux données

### 3. Permissions AndroidManifest.xml

**Actuellement déclarées :**
- ✅ `INTERNET` - Justifiée (accès réseau)
- ✅ `ACCESS_NETWORK_STATE` - Justifiée (vérification connectivité)
- ⚠️ `usesCleartextTraffic="true"` - **À justifier**

**Justification pour `usesCleartextTraffic` :**
- Nécessaire pour les sources IPTV qui utilisent HTTP (non HTTPS)
- Les utilisateurs configurent leurs propres sources IPTV
- L'app ne contrôle pas le protocole utilisé par les sources externes

**Recommandation :**
- Garder `usesCleartextTraffic="true"` si vous supportez IPTV HTTP
- Documenter dans la description Play Store que l'app permet de se connecter à des sources IPTV personnelles
- Considérer une option pour désactiver HTTP si l'utilisateur le souhaite (amélioration future)

### 4. Contenu IPTV - Risques de rejet

**Points d'attention :**

1. **Description Play Store :**
   - Ne pas mentionner explicitement "streaming gratuit" ou "accès illégal"
   - Mettre l'accent sur : "Gestion de vos sources IPTV personnelles"
   - Exemple : "Movi vous permet de gérer et regarder vos contenus depuis vos sources IPTV personnelles"

2. **Fonctionnalités déclarées :**
   - ✅ Gestion de bibliothèque personnelle
   - ✅ Synchronisation cloud (Supabase)
   - ✅ Contrôle parental
   - ✅ Organisation de playlists

3. **Justification légale :**
   - L'app est un outil de gestion de contenu
   - Les utilisateurs sont responsables de leurs sources
   - L'app ne fournit pas de contenu, seulement l'interface

### 5. Captures d'écran et assets

**Requis :**
- [ ] Minimum 2 captures d'écran (recommandé 8)
- [ ] Icône haute résolution 512x512 px
- [ ] Bannière de fonctionnalité 1024x500 px (optionnel mais recommandé)

**Conseils :**
- Montrer les fonctionnalités principales (accueil, lecture, bibliothèque)
- Inclure des captures avec du contenu réel (si possible)
- Respecter les guidelines Material Design

### 6. Catégorie et cible

**Recommandations :**
- Catégorie : **Divertissement** ou **Multimédia**
- Cible d'âge : Selon le contenu (si contrôle parental : tous âges avec restrictions)

### 7. Contact support

**Requis :**
- Email de support (déjà défini : `support@movi.app` dans `AppMetadata`)
- URL du site web (si disponible)
- Politique de confidentialité (URL)

### 8. Notes de version

**Pour la première version (1.0.0) :**
```
Version initiale de Movi

Fonctionnalités principales :
- Gestion de bibliothèque personnelle
- Synchronisation cloud
- Contrôle parental (PEGI + PIN)
- Support IPTV
- Interface moderne et intuitive
```

## 🧪 Tests avant soumission

### Build et test local

```bash
# Nettoyer
flutter clean
flutter pub get

# Build AAB (avec variables d'environnement si nécessaire)
flutter build appbundle --release --flavor prod -t lib/main.dart

# Le fichier sera dans :
# build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Tests fonctionnels

- [ ] Connexion/déconnexion
- [ ] Création et sélection de profil
- [ ] Contrôle parental (PIN, restrictions PEGI)
- [ ] Lecture vidéo
- [ ] Gestion IPTV
- [ ] Synchronisation cloud
- [ ] Navigation générale

### Tests sur différents appareils

- [ ] Smartphone Android (version récente)
- [ ] Smartphone Android (version ancienne, si minSdk le permet)
- [ ] Tablette (si supporté)

## 📤 Upload Play Console

### Piste de test interne (recommandé en premier)

1. Play Console → Votre app → **Testing** → **Internal testing**
2. Créer une nouvelle release
3. Uploader le fichier `.aab`
4. Ajouter des testeurs (emails Google)
5. Publier la release interne
6. Tester via le lien de test

### Après validation en test interne

1. Créer une release de production
2. Uploader le même `.aab` (ou un nouveau avec versionCode incrémenté)
3. Remplir toutes les sections requises
4. Soumettre pour révision

## 🔍 Vérifications finales

- [ ] Tous les champs obligatoires remplis
- [ ] Politique de confidentialité accessible
- [ ] Data Safety déclarée correctement
- [ ] Captures d'écran ajoutées
- [ ] Description claire et conforme
- [ ] Version et versionCode corrects
- [ ] AAB signé correctement

## 📝 Commandes utiles

### Vérifier la signature de l'AAB

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Vérifier les informations de l'AAB

```bash
bundletool build-apks --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab --output=temp.apks --mode=universal
unzip -l temp.apks
```

## ⚠️ Mots de passe avec caractères spéciaux

Si votre mot de passe contient `#` ou d'autres caractères spéciaux :

### Dans `~/.gradle/gradle.properties` :
```properties
MOVI_STORE_PASSWORD=ab#cd123
MOVI_KEY_PASSWORD=xy#z
```
✅ Fonctionne directement

### Dans variables d'environnement Windows :
```cmd
set "MOVI_STORE_PASSWORD=ab#cd123"
set "MOVI_KEY_PASSWORD=xy#z"
```

### Dans PowerShell :
```powershell
$env:MOVI_STORE_PASSWORD = "ab#cd123"
$env:MOVI_KEY_PASSWORD = "xy#z"
```

### Dans CI/CD (GitHub Actions, etc.) :
Utilisez les secrets GitHub et mettez les valeurs directement (pas besoin de guillemets dans les secrets).

