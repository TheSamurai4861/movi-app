// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeTitle => 'Bienvenue !';

  @override
  String get welcomeSubtitle =>
      'Renseigne tes préférences pour personnaliser Movi.';

  @override
  String get labelUsername => 'Pseudo';

  @override
  String get labelPreferredLanguage => 'Langue préférée';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get hintUsername => 'Ton pseudo';

  @override
  String get errorFillFields => 'Merci de remplir correctement les champs.';

  @override
  String get homeWatchNow => 'Regarder maintenant';

  @override
  String get welcomeSourceTitle => 'Bienvenue !';

  @override
  String get welcomeSourceSubtitle =>
      'Ajoute une source pour personnaliser ton expérience dans Movi.';

  @override
  String get welcomeSourceAdd => 'Ajouter une source';

  @override
  String get searchTitle => 'Recherche';

  @override
  String get searchHint => 'Tapez votre recherche';

  @override
  String get clear => 'Effacer';

  @override
  String get moviesTitle => 'Films';

  @override
  String get seriesTitle => 'Séries';

  @override
  String get noResults => 'Pas de résultats';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Aucune recherche récente';

  @override
  String get delete => 'Supprimer';

  @override
  String resultsCount(int count) {
    return '($count résultats)';
  }

  @override
  String get errorUnknown => 'Erreur inconnue';

  @override
  String errorConnectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get errorConnectionGeneric => 'Échec de la connexion';

  @override
  String get validationRequired => 'Requis';

  @override
  String get validationInvalidUrl => 'URL invalide';

  @override
  String get snackbarSourceAddedBackground =>
      'Source IPTV ajoutée. Synchronisation en arrière-plan…';

  @override
  String get snackbarSourceAddedSynced => 'Source IPTV ajoutée et synchronisée';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguageLabel => 'Langue de l’application';

  @override
  String get settingsGeneralTitle => 'Préférences générales';

  @override
  String get settingsDarkModeTitle => 'Mode sombre';

  @override
  String get settingsDarkModeSubtitle => 'Active un thème adapté à la nuit.';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Soyez averti des nouvelles sorties.';

  @override
  String get settingsAccountTitle => 'Compte';

  @override
  String get settingsProfileInfoTitle => 'Informations du profil';

  @override
  String get settingsProfileInfoSubtitle => 'Nom, avatar, préférences';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsLegalMentionsTitle => 'Mentions légales';

  @override
  String get settingsPrivacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionConfirm => 'Valider';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get homeErrorSwipeToRetry =>
      'Une erreur est survenue. Balayez vers le bas pour réessayer.';

  @override
  String get homeContinueWatching => 'En cours';

  @override
  String get homeNoIptvSources =>
      'Aucune source IPTV active. Ajoutez une source dans Paramètres pour voir vos catégories.';

  @override
  String get homeNoTrends => 'Aucune tendance disponible';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionExpand => 'Agrandir';

  @override
  String get castTitle => 'Distribution';

  @override
  String get recommendationsTitle => 'Recommandations';

  @override
  String get libraryHeader => 'Votre vidéothèque';

  @override
  String get libraryDataInfo =>
      'Les données seront affichées lorsque la couche data/domain sera implémentée.';

  @override
  String get libraryEmpty => 'Aucun contenu disponible pour le moment.';
}

/// The translations for French, as used in Myanmar (`fr_MM`).
class AppLocalizationsFrMm extends AppLocalizationsFr {
  AppLocalizationsFrMm() : super('fr_MM');

  @override
  String get welcomeTitle => 'Que nenni ! Bienv\'nû !';

  @override
  String get welcomeSubtitle =>
      'Remplis tes préférences, c’est point couettos mais utile.';

  @override
  String get labelUsername => 'Sobriquet';

  @override
  String get labelPreferredLanguage => 'Langage de la bourgogne';

  @override
  String get actionContinue => 'Avançons';

  @override
  String get hintUsername => 'Ton sobriquet';

  @override
  String get errorFillFields => 'Faut point oublier d’emplir les champs.';

  @override
  String get homeWatchNow => 'Regarder toutim';

  @override
  String get welcomeSourceTitle => 'Bienv\'nû !';

  @override
  String get welcomeSourceSubtitle =>
      'Ajoute une source, que diable, pour personnaliser Movi.';

  @override
  String get welcomeSourceAdd => 'Ajouter la souce';

  @override
  String get searchTitle => 'Quérir';

  @override
  String get searchHint => 'Tape ta quête';

  @override
  String get clear => 'Ôter';

  @override
  String get moviesTitle => 'Bobines';

  @override
  String get seriesTitle => 'Feuilletons';

  @override
  String get noResults => 'Point de résultat';

  @override
  String get historyTitle => 'Chronique';

  @override
  String get historyEmpty => 'Point de recherche récente';

  @override
  String get delete => 'Pourfendre';

  @override
  String resultsCount(int count) {
    return '($count trouvailles)';
  }

  @override
  String get errorUnknown => 'Méprise inconnue';

  @override
  String errorConnectionFailed(String error) {
    return 'Connexion faillie : $error';
  }

  @override
  String get errorConnectionGeneric => 'Connexion faillie';

  @override
  String get validationRequired => 'Obligé';

  @override
  String get validationInvalidUrl => 'L’adresse est point bonne';

  @override
  String get snackbarSourceAddedBackground =>
      'Source IPTV ajoutée. Ça s’active en coulisse…';

  @override
  String get snackbarSourceAddedSynced => 'Source IPTV ajoutée et arrimée';

  @override
  String get navHome => 'Gîte';

  @override
  String get navSearch => 'Quête';

  @override
  String get navLibrary => 'Réserve';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageLabel => 'Langage de l’appli';

  @override
  String get settingsGeneralTitle => 'Préférences générales';

  @override
  String get settingsDarkModeTitle => 'Nuit noire';

  @override
  String get settingsDarkModeSubtitle =>
      'Active un thème pour besogner la nuit.';

  @override
  String get settingsNotificationsTitle => 'Avises';

  @override
  String get settingsNotificationsSubtitle => 'Soyez prévenus des nouveautés.';

  @override
  String get settingsAccountTitle => 'Comptoir';

  @override
  String get settingsProfileInfoTitle => 'Billets du profil';

  @override
  String get settingsProfileInfoSubtitle => 'Nom, effigie, préférences';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsLegalMentionsTitle => 'Mentions légales';

  @override
  String get settingsPrivacyPolicyTitle => 'Privautés';

  @override
  String get actionCancel => 'Abandonner';

  @override
  String get actionConfirm => 'Valider la chose';

  @override
  String get actionRetry => 'Recommencer';

  @override
  String get homeErrorSwipeToRetry =>
      'Un couac est advenu. Tire en bas pour réessayer.';

  @override
  String get homeContinueWatching => 'En cours';

  @override
  String get homeNoIptvSources =>
      'Point de source IPTV. Ajoute-en dans Ajustes pour voir tes catégories.';

  @override
  String get homeNoTrends => 'Point de tendances';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionExpand => 'Élargir';

  @override
  String get castTitle => 'Troupe';

  @override
  String get recommendationsTitle => 'Conseils';

  @override
  String get libraryHeader => 'Ta réserve';

  @override
  String get libraryDataInfo =>
      'Les données s’afficheront quand la couche data/domain sera arrimée.';

  @override
  String get libraryEmpty => 'Point de contenu pour l’instant.';
}
