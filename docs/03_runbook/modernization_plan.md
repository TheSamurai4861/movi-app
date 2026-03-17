# Plan de modernisation du projet

## But

Ce document decrit l'ordre d'analyse recommande pour faire evoluer le projet vers un niveau plus professionnel, en partant des dossiers racine.

L'objectif est d'ameliorer progressivement :

- la qualite du code ;
- la conformite aux bonnes pratiques Flutter et Dart ;
- la gestion des assets et des images ;
- la maintenabilite du projet ;
- la capacite a builder, tester et livrer proprement.

---

## Principe general

Toujours avancer du plus structurant vers le plus local.

Autrement dit :

1. stabiliser le socle du projet ;
2. nettoyer la racine et les configurations ;
3. clarifier les plateformes cibles ;
4. normaliser les assets ;
5. refactorer le code applicatif ;
6. renforcer les tests et la livraison.

Cela evite de corriger du code dans un cadre encore flou ou instable.

---

## Ordre d'analyse en partant des dossiers racine

### 1. `pubspec.yaml`

Point d'entree technique du projet.

Verifier en priorite :

- les dependances reelles et celles devenues inutiles ;
- la coherence des versions ;
- les plugins lies aux plateformes ;
- la declaration des assets ;
- la configuration `flutter`, `generate`, `flutter_launcher_icons` ;
- la presence de packages specifiques desktop, mobile ou web vraiment assumes.

Attendu :

- un fichier propre, comprehensible et justifie ;
- aucun package conserve "au cas ou" ;
- des assets declares de facon explicite et coherente.

---

### 2. Fichiers racine de gouvernance et de qualite

Fichiers a analyser ensuite :

- `analysis_options.yaml`
- `.gitignore`
- `codemagic.yaml`
- `l10n.yaml`
- `devtools_options.yaml`
- `.metadata`

Objectifs :

- renforcer les lints Dart/Flutter ;
- supprimer les exceptions de lint non justifiees ;
- ignorer correctement les fichiers generes et locaux ;
- verifier la coherence CI/CD ;
- verifier la generation de localisation.

Attendu :

- des regles d'analyse strictes mais realistes ;
- un depot sans bruit inutile ;
- une base saine pour industrialiser le projet.

---

### 3. Dossiers racine non produit

Dossiers a passer en revue :

- `docs/`
- `scripts/`
- `tool/`
- `output/`
- `.cursor/`
- `.idea/`
- `build/`
- `.dart_tool/`

Questions a se poser :

- le dossier est-il utile au produit, au workflow, ou a rien ?
- son contenu est-il documente, maintenu et versionnable ?
- contient-il des artefacts temporaires, locaux ou regenerables ?

Decisions typiques :

- garder `docs/`, `scripts/`, `tool` si leur role est clair ;
- supprimer ou ignorer `output/`, `build/`, `.dart_tool/`, `.idea/` ;
- conserver `.cursor/` seulement si ce workflow est assume par l'equipe.

---

### 4. Plateformes Flutter

Dossiers concernes :

- `android/`
- `ios/`
- `windows/`
- `macos/`
- `linux/`
- `web/`

Ordre conseille :

1. garder seulement les plateformes reelles du produit ;
2. verifier la configuration de build et de lancement ;
3. verifier les permissions, icones, noms d'application et configurations release ;
4. supprimer les plateformes hors perimetre si elles ne sont pas maintenues.

Points de controle :

- signatures et flavours Android ;
- coherence iOS si la plateforme est supportee ;
- rationalisation desktop si Windows/macOS/Linux ne sont pas tous cibles ;
- utilite reelle de `web/`.

Attendu :

- moins de bruit dans le depot ;
- moins de maintenance implicite ;
- des cibles officiellement supportees et propres.

---

### 5. `assets/`

Le dossier assets doit ensuite etre normalise.

Verifier :

- l'organisation des sous-dossiers ;
- les conventions de nommage ;
- les formats utilises ;
- le poids des fichiers ;
- les doublons ;
- les assets non references ;
- la coherence entre les assets presents et ceux declares dans `pubspec.yaml`.

Bonnes pratiques recommandees :

- `svg` pour les icones simples ;
- `png` ou `webp` pour les images raster selon le besoin ;
- dimensions et poids optimises ;
- noms explicites et stables ;
- regroupement par fonction plutot que par historique.

Exemple de structure cible :

```text
assets/
  icons/
  images/
  illustrations/
  logos/
```

---

### 6. `lib/`

C'est la phase centrale du chantier.

Ordre conseille dans le code :

1. `lib/main.dart`
2. `lib/src/app.dart`
3. `lib/src/core/`
4. `lib/src/shared/`
5. `lib/src/features/`
6. `lib/l10n/`

Pour chaque zone, verifier :

- responsabilites claires ;
- separation UI / logique / data ;
- gestion d'etat lisible ;
- navigation propre ;
- dependances bien bornees ;
- nommage coherent ;
- widgets pas trop volumineux ;
- erreurs et logs geres proprement ;
- absence de couplage inutile avec la plateforme.

Priorites de refactorisation :

- bootstrap et startup ;
- configuration et environnement ;
- core transverse ;
- services partages ;
- features produit ;
- localisation.

---

### 7. `test/`

Une fois le code clarifie, consolider la qualite par les tests.

Priorites :

- tests unitaires sur la logique metier ;
- tests des services et repositories ;
- tests des providers ou couches d'etat ;
- widget tests sur les ecrans critiques ;
- reduction des tests fragiles ou trop relies au rendu complet.

Attendu :

- une base de tests utile au refactoring ;
- une couverture ciblee sur les zones sensibles ;
- des tests rapides et stables.

---

## Marche a suivre dossier par dossier

Pour chaque dossier racine, appliquer toujours la meme grille d'analyse :

1. Role
2. Necessite
3. Qualite
4. Conformite Flutter/Dart
5. Decision

Detail :

1. Role
   A quoi sert ce dossier dans le produit ou dans le workflow ?
2. Necessite
   Est-il indispensable, optionnel, local, genere ou obsolete ?
3. Qualite
   Le contenu est-il bien nomme, structure, documente, sans doublons ?
4. Conformite Flutter/Dart
   Respecte-t-il les conventions et bonnes pratiques ?
5. Decision
   Faut-il garder, nettoyer, refactorer, documenter ou supprimer ?

---

## Plan de modernisation en phases

### Phase 1. Socle projet

Traiter :

- `pubspec.yaml`
- `analysis_options.yaml`
- `.gitignore`
- `l10n.yaml`
- `codemagic.yaml`

Objectif :

- rendre le socle fiable et propre.

### Phase 2. Nettoyage racine

Traiter :

- dossiers generes ;
- dossiers locaux ;
- documents temporaires ;
- scripts utilitaires non justifies.

Objectif :

- reduire le bruit et clarifier ce qui fait partie du projet.

### Phase 3. Plateformes

Traiter :

- `android/`
- `ios/`
- `windows/`
- `macos/`
- `linux/`
- `web/`

Objectif :

- aligner le depot sur les plateformes vraiment supportees.

### Phase 4. Assets et design system

Traiter :

- `assets/`
- theming ;
- typographie ;
- icones ;
- images.

Objectif :

- obtenir une base visuelle et media propre, legere et maintenable.

### Phase 5. Code applicatif

Traiter :

- `lib/`

Objectif :

- rendre l'architecture lisible, evolutive et testable.

### Phase 6. Qualite de livraison

Traiter :

- `test/`
- CI
- documentation de debug et de release

Objectif :

- fiabiliser les evolutions et les livraisons.

---

## Priorite recommandee pour ce projet

Ordre recommande actuellement :

1. `pubspec.yaml`
2. `analysis_options.yaml` et `.gitignore`
3. `output/`, `.idea/`, `build/`, `.dart_tool/`, `.cursor/`
4. `docs/`
5. `android/`, `windows/`, `ios/`, puis decision pour `linux/`, `macos/`, `web`
6. `assets/`
7. `lib/`
8. `test/`

Cet ordre permet de commencer par les points qui structurent tout le reste, avant de rentrer dans le detail du code.
