// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burgonde (`bu`).
class AppLocalizationsBu extends AppLocalizations {
  AppLocalizationsBu([String locale = 'bu']) : super(locale);

  @override
  String get welcomeTitle => "Que nenni ! Bienv'nû !";
  @override
  String get welcomeSubtitle =>
      "Remplis tes préférences, c’est point couettos mais utile.";
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
  String get welcomeSourceTitle => "Bienv'nû !";
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
  String resultsCount(int count) => '($count trouvailles)';
  @override
  String get errorUnknown => 'Méprise inconnue';
  @override
  String errorConnectionFailed(String error) => 'Connexion faillie : $error';
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
  String get libraryDataInfo =>
      'Les données s’afficheront quand la couche data/domain sera arrimée.';

  @override
  String get libraryEmpty => 'Likez des films, séries ou acteurs pour les voir apparaître ici.';

  @override
  String get libraryHeader => 'Ta réserve';

  @override
  String get recommendationsTitle => 'Conseils';
  @override
  String get actionChangeMetadata => 'Changer les bilboquets';
  @override
  String get actionAddToList => 'Mettre en la liste';
  @override
  String get actionMarkSeen => 'Marquer comme vu';
  @override
  String get actionMarkUnseen => 'Marquer comme point vu';
  @override
  String get actionReportProblem => 'Signaler un couac';
  @override
  String get featureComingSoon => 'Fonction à venir';
  @override
  String get actionLoadMore => 'Charger davantage';
  @override
  String get iptvServerUrlLabel => 'Adresse du serveur';
  @override
  String get iptvServerUrlHint => 'Adresse du serveur Xtream';
  @override
  String get iptvPasswordLabel => 'Mot de passe';
  @override
  String get iptvPasswordHint => 'Mot de passe Xtream';
  @override
  String get actionConnect => 'Se relier';
  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Rafraîchir les listes IPTV';
  @override
  String get statusActive => 'Actif';
  @override
  String get statusNoActiveSource => 'Point de source active';
  @override
  String get overlayPreparingHome => 'Préparation du gîte…';
  @override
  String get errorPrepareHome => 'Impossible de préparer la page du gîte';
  @override
  String get overlayOpeningHome => 'Ouverture du gîte…';
  @override
  String get overlayRefreshingIptvLists => 'Rafraîchissement des listes IPTV…';
  @override
  String get overlayPreparingMetadata => 'Préparation des billets…';
  @override
  String get errorHomeLoadTimeout => 'Délai de chargement du gîte dépassé';
  @override
  String get faqLabel => 'FAQ';
  @override
  String get iptvUsernameLabel => 'Nom d\'utilisateur';
  @override
  String get iptvUsernameHint => 'Identifiant Xtream';
  @override
  String get actionRefreshMetadata => 'Rafraîchir les billets';
  @override
  String get metadataRefreshed => 'Billets rafraîchis';
  @override
  String get errorRefreshingMetadata =>
      'Couac lors du rafraîchissement des billets';
  @override
  String get actionCollapse => 'Rétrécir';
  @override
  String get actionClearHistory => 'Pourfendre l\'historique';
  @override
  String get serie => 'Feuilletons';
  @override
  String get recherche => 'Quête';
  @override
  String get notYetAvailable => 'Point encore disponible';
}
