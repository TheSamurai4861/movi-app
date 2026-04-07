# Sous-phase 2.6 - Checklist d'implementation UX/UI

## Objectif

Fournir une checklist directement exploitable au moment de l'implementation des ecrans et composants du tunnel.

## Checklist globale

### Fondations

- la palette Movi existante est conservee
- la typo reste coherente avec le theme de l'app
- le tunnel reste sombre par defaut
- le tunnel reste coherent avec `home`
- `Lucide Icons` est la reference iconographique de la nouvelle spec

### Structure

- chaque ecran utilise un `TunnelPageShell`
- aucun ecran ne reconstruit son propre hero ou son propre header sans passer par les composants communs
- un seul CTA principal est visible par surface
- les actions secondaires restent discretes et coherentes

### Formulaires

- tous les champs passent par une meme logique `TunnelField`
- les erreurs de champ restent inline
- les aides restent courtes
- le CTA principal est visible rapidement

### Galeries de choix

- les profils sont affiches avec avatar rond et nom en dessous
- les cartes profil sont l'action primaire de `Choix profil`
- les sources existantes utilisent une brique commune
- le focus est distinct de l'etat `selected`

### Etats et feedbacks

- les messages critiques utilisent `TunnelInlineMessage` ou `TunnelRecoveryBanner`
- un etat critique ne cree pas un nouvel ecran si une solution inline suffit
- `Chargement medias` reste simple et lisible
- `Home vide` garde un ton informatif, pas un ton d'erreur

### Responsive

- mobile et TV gardent le meme ordre logique
- les seules differences portent sur taille, densite, respiration et focus
- la TV ne declenche pas une branche UI autonome

### Accessibilite

- contrastes valides sur fond sombre
- ordre de lecture logique
- relation claire entre champ, aide, erreur et CTA
- pas de message critique encode uniquement par couleur

### TV et focus

- le focus est toujours visible
- le focus ne saute pas sur les messages inline sans raison
- le focus order suit la logique de l'ecran
- aucun focus trap involontaire
- un changement d'etat conserve le focus au plus pres de la prochaine action utile

## Checklist par ecran

### `Preparation systeme`

- logo centre
- message principal bref
- indicateur discret
- recovery seulement si necessaire
- aucun focus visible en nominal

### `Auth`

- pattern `hero + form`
- message `code envoye` inline
- erreurs inline
- CTA principal dominant
- ordre de focus coherent

### `Creation profil`

- form tres courte
- options avatar / couleur simples
- pas de surcharge informationnelle

### `Choix profil`

- galerie de cartes premium
- carte = action primaire
- nom lisible sous l'avatar
- retour secondaire seulement

### `Choix / ajout source`

- inventaire source + ajout dans une meme surface
- message contextuel clair
- erreur source inline
- pas d'ecran d'erreur dedie

### `Chargement medias`

- surface plus explicite que le splash
- recovery seulement si seuil depasse
- pas de details techniques

### `Home vide`

- empty state integre dans `Home`
- ton informatif
- action sobre

## Definition de done UX/UI pour un ecran du tunnel

Un ecran du tunnel peut etre considere comme pret si:

1. sa structure correspond a la spec UI
2. il s'appuie sur les composants communs prevus
3. ses etats critiques sont traites correctement
4. son comportement mobile / TV est coherent
5. son focus order est stable
6. ses messages restent courts, clairs et actionnables

## Conclusion

Cette checklist sert de garde-fou. Elle doit eviter qu'une implementation locale reintroduise des ecarts de structure, de ton ou de comportement entre les ecrans du tunnel.
