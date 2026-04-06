# Sous-phase 1.6 - Wireframes low-fi textuels du tunnel d'entree

## Objectif

Traduire les decisions UX des sous-phases `1.1` a `1.5` en wireframes basse fidelite textuels, lisibles et exploitables avant le travail de design detaille.

Ces wireframes servent a valider:
- la structure des ecrans
- la hierarchie de l'information
- l'action primaire dominante
- les variantes majeures
- les differences utiles entre mobile et TV

## Regle generale de lecture

Notation:
- `[Bloc]` = zone visuelle ou fonctionnelle
- `(Primaire)` = action principale
- `(Secondaire)` = action secondaire
- `Inline` = variation integree a la surface, pas un nouvel ecran

## 1. Preparation systeme

## Mobile

```text
[Fond plein ecran / ambiance marque]

    [Logo]

    [Titre court]
    Preparation de votre experience

    [Sous-texte optionnel]
    Verification de votre acces

    [Indicateur discret]
    spinner ou barre tres fine

    [Zone inline degragee - seulement si necessaire]
    message explicatif
    (Primaire) Reessayer
```

Points de hierarchie:
- le logo et le message principal dominent
- le sous-texte reste secondaire
- le `Retry` n'apparait qu'en cas degrade

## TV

```text
[Fond plein ecran / logo plus grand / centre ecran]

            [Logo XL]

     [Titre principal tres lisible]
     Preparation de votre experience

     [Sous-texte court]
     Recuperation de vos donnees

     [Indicateur discret]

     [Zone inline degragee]
     message bref
     (Primaire) Reessayer
```

Difference TV:
- plus de respiration
- texte plus court
- action unique si degrade

## 2. Auth

## Mobile

```text
[Header simple]
Retour

[Titre]
Connectez-vous pour continuer

[Champ email]

[Aide courte]
Nous vous enverrons un code a 8 chiffres.

[Etat code visible seulement apres envoi]
[Champ code]

[Erreur inline]
message clair si besoin

[Actions]
(Primaire) Recevoir le code / Continuer
(Secondaire) Retour
```

Variante majeure:
- avant envoi du code: champ email + CTA
- apres envoi du code: email + champ code + CTA de validation

## TV

```text
[Carte centrale]

[Titre]
Connectez-vous pour continuer

[Description courte]

[Champ email ou future zone QR]

[Champ code si necessaire]

[Erreur inline]

[Actions verticales]
(Primaire) Recevoir le code / Continuer
(Secondaire) Retour
```

Difference TV:
- composition en carte unique
- moins d'elements simultanes

## 3. Creation profil

## Mobile

```text
[Header]
Retour

[Titre]
Creez votre premier profil

[Champ nom profil]

[Choix simple optionnel]
avatar / couleur

[Aide courte]

[Actions]
(Primaire) Creer le profil
(Secondaire) Retour
```

## TV

```text
[Carte centrale]

[Titre]
Creez votre premier profil

[Champ nom ou choix predefinis]

[Choix avatar / couleur en ligne]

[Actions]
(Primaire) Creer le profil
(Secondaire) Retour
```

Difference TV:
- idealement moins de saisie libre
- plus de presets

## 4. Choix profil

## Mobile

```text
[Header]
Retour

[Titre]
Choisissez un profil pour continuer

[Grille / liste de profils]
  [Profil A]
  [Profil B]
  [Profil C]

[Actions]
(Primaire) Selection via le profil
(Secondaire) Retour
```

## TV

```text
[Titre centre]
Choisissez un profil

[Grille large focusable]
 [Profil A] [Profil B] [Profil C]

[Action secondaire discrete]
Retour
```

Difference TV:
- le profil lui-meme devient l'action primaire
- pas de bouton primaire supplementaire

## 5. Choix / ajout source

## Mobile

```text
[Header]
Retour

[Titre]
Choisissez ou ajoutez une source

[Message contextuel]
Votre source n'est plus disponible.

[Bloc sources existantes - si applicable]
  [Source 1] (selection)
  [Source 2] (selection)

[Separateur visuel]
ou

[Bloc ajout source]
  [Nom source]
  [Adresse]
  [Identifiant]
  [Mot de passe]

[Erreur inline sous le formulaire ou le CTA]
Impossible d'utiliser cette source

[Actions]
(Primaire) Ajouter / Continuer avec cette source
(Secondaire) Retour
```

Variante majeure:
- premiere connexion: bloc `sources existantes` masque
- retour utilisateur: bloc `sources existantes` visible si pertinent

## TV

```text
[Titre]
Choisissez ou ajoutez une source

[Message contextuel]

[Layout deux zones]
Zone gauche:
  [Sources existantes focusables]

Zone droite:
  [Formulaire simplifie ou resume de la source]

[Erreur inline]

[Actions bas d'ecran]
(Primaire) Utiliser / Ajouter
(Secondaire) Retour
```

Difference TV:
- separation visuelle plus forte entre inventaire et edition
- peu d'actions visibles en meme temps

## 6. Chargement medias

## Mobile

```text
[Fond simple]

    [Logo ou icone]

    [Titre]
    Chargement de vos films et series

    [Sous-texte optionnel]
    Preparation de votre accueil

    [Indicateur de progression]

    [Zone inline degragee - si chargement long]
    Le chargement prend plus de temps que prevu
    (Primaire) Reessayer
    (Secondaire) Attendre
```

## TV

```text
[Fond plein ecran]

         [Logo]

   [Titre grand format]
   Chargement de vos films et series

   [Sous-texte bref]

   [Progression]

   [Zone degragee]
   message
   (Primaire) Reessayer
   (Secondaire) Attendre
```

Difference TV:
- plus de respiration
- texte encore plus court

## 7. Home vide

## Mobile

```text
[Home normale]

[Banniere / carte vide en haut]
Votre source est connectee, mais aucun contenu n'est disponible pour le moment.

[Actions dans la carte]
(Primaire) Compris
(Secondaire) Voir mes sources plus tard
```

## TV

```text
[Home normale]

[Carte vide large]
Votre source est connectee, mais aucun contenu n'est disponible pour le moment.

[Actions]
(Primaire) Compris
(Secondaire) Voir mes sources plus tard
```

Decision structurelle:
- reste un etat de `Home`
- ne devient pas un ecran du tunnel

## Variantes majeures a conserver

Les variantes qui changent vraiment la structure et meritent un wireframe dedie ensuite sont:
- `Preparation systeme` nominal vs degrade
- `Auth` avant code vs apres envoi du code
- `Choix / ajout source` premiere connexion vs retour utilisateur
- `Chargement medias` nominal vs chargement long

## Variantes qui doivent rester inline

Ne pas creer un nouvel ecran pour:
- erreur source
- source active invalide avec message contextuel
- sync cloud partielle
- chargement plus long que prevu
- `Home vide`

## Checklist de validation low-fi

Chaque wireframe doit respecter:
- une action primaire dominante
- une information critique unique au sommet
- un nombre d'actions visibles limite
- aucun jargon systeme
- une lecture simple en mobile comme en TV

## Gate de sortie de la sous-phase 1.6

La sous-phase 1.6 peut etre consideree comme valide si:
- chaque ecran cible a un wireframe low-fi textuel
- les variantes majeures sont identifiees
- les differences mobile / TV sont explicites
- les etats inline sont clairement separes des vrais ecrans

## Conclusion

Les wireframes low-fi confirment la structure du tunnel: peu d'ecrans, chacun centre sur une seule tache, avec un maximum de clarte et un minimum de transitions inutiles.
