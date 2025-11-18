// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get welcomeTitle => 'Welkom!';

  @override
  String get welcomeSubtitle =>
      'Vul je voorkeuren in om Movi te personaliseren.';

  @override
  String get labelUsername => 'Bijnaam';

  @override
  String get labelPreferredLanguage => 'Voorkeurstaal';

  @override
  String get actionContinue => 'Doorgaan';

  @override
  String get hintUsername => 'Je bijnaam';

  @override
  String get errorFillFields => 'Vul de velden correct in.';

  @override
  String get homeWatchNow => 'Nu kijken';

  @override
  String get welcomeSourceTitle => 'Welkom!';

  @override
  String get welcomeSourceSubtitle =>
      'Voeg een bron toe om je Movi-ervaring te personaliseren.';

  @override
  String get welcomeSourceAdd => 'Bron toevoegen';

  @override
  String get searchTitle => 'Zoeken';

  @override
  String get searchHint => 'Typ je zoekopdracht';

  @override
  String get clear => 'Wissen';

  @override
  String get moviesTitle => 'Films';

  @override
  String get seriesTitle => 'Series';

  @override
  String get noResults => 'Geen resultaten';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String get historyEmpty => 'Geen recente zoekopdrachten';

  @override
  String get delete => 'Verwijderen';

  @override
  String resultsCount(int count) {
    return '($count resultaten)';
  }

  @override
  String get errorUnknown => 'Onbekende fout';

  @override
  String errorConnectionFailed(String error) {
    return 'Verbinding mislukt: $error';
  }

  @override
  String get errorConnectionGeneric => 'Verbinding mislukt';

  @override
  String get validationRequired => 'Vereist';

  @override
  String get validationInvalidUrl => 'Ongeldige URL';

  @override
  String get snackbarSourceAddedBackground =>
      'IPTV-bron toegevoegd. Synchronisatie op de achtergrond…';

  @override
  String get snackbarSourceAddedSynced =>
      'IPTV-bron toegevoegd en gesynchroniseerd';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Zoeken';

  @override
  String get navLibrary => 'Bibliotheek';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguageLabel => 'App-taal';

  @override
  String get settingsGeneralTitle => 'Algemene voorkeuren';

  @override
  String get settingsDarkModeTitle => 'Donkere modus';

  @override
  String get settingsDarkModeSubtitle =>
      'Schakel een nachtvriendelijk thema in.';

  @override
  String get settingsNotificationsTitle => 'Meldingen';

  @override
  String get settingsNotificationsSubtitle =>
      'Ontvang bericht over nieuwe releases.';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsProfileInfoTitle => 'Profielinformatie';

  @override
  String get settingsProfileInfoSubtitle => 'Naam, avatar, voorkeuren';

  @override
  String get settingsAboutTitle => 'Over';

  @override
  String get settingsLegalMentionsTitle => 'Juridische vermeldingen';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacybeleid';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionConfirm => 'Bevestigen';

  @override
  String get actionRetry => 'Opnieuw proberen';

  @override
  String get homeErrorSwipeToRetry =>
      'Er is een fout opgetreden. Veeg omlaag om opnieuw te proberen.';

  @override
  String get homeContinueWatching => 'Verder kijken';

  @override
  String get homeNoIptvSources =>
      'Geen IPTV-bron actief. Voeg een bron toe in Instellingen om je categorieën te zien.';

  @override
  String get homeNoTrends => 'Geen trending inhoud beschikbaar';

  @override
  String get actionRefreshMetadata => 'Metadata vernieuwen';

  @override
  String get actionChangeMetadata => 'Metadata wijzigen';

  @override
  String get actionAddToList => 'Toevoegen aan een lijst';

  @override
  String get metadataRefreshed => 'Metadata vernieuwd';

  @override
  String get errorRefreshingMetadata => 'Fout bij vernieuwen van metadata';

  @override
  String get actionMarkSeen => 'Mark as seen';

  @override
  String get actionMarkUnseen => 'Mark as unseen';

  @override
  String get actionReportProblem => 'Report a problem';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get actionLoadMore => 'Load more';

  @override
  String get iptvServerUrlLabel => 'Server URL';

  @override
  String get iptvServerUrlHint => 'Xtream server URL';

  @override
  String get iptvPasswordLabel => 'Password';

  @override
  String get iptvPasswordHint => 'Xtream password';

  @override
  String get actionConnect => 'Connect';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Refresh IPTV playlists';

  @override
  String get statusActive => 'Active';

  @override
  String get statusNoActiveSource => 'No active source';

  @override
  String get overlayPreparingHome => 'Preparing home…';

  @override
  String get errorPrepareHome => 'Unable to prepare the home page';

  @override
  String get overlayOpeningHome => 'Opening home…';

  @override
  String get overlayRefreshingIptvLists => 'Refreshing IPTV lists…';

  @override
  String get overlayPreparingMetadata => 'Preparing metadata…';

  @override
  String get errorHomeLoadTimeout => 'Home load timeout';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Username';

  @override
  String get iptvUsernameHint => 'Xtream username';

  @override
  String get actionBack => 'Terug';

  @override
  String get actionExpand => 'Uitklappen';

  @override
  String get actionCollapse => 'Inklappen';

  @override
  String get actionClearHistory => 'Geschiedenis wissen';

  @override
  String get castTitle => 'Cast';

  @override
  String get recommendationsTitle => 'Aanbevelingen';

  @override
  String get libraryHeader => 'Jouw videotheek';

  @override
  String get libraryDataInfo =>
      'Gegevens worden getoond zodra data/domain is geïmplementeerd.';

  @override
  String get libraryEmpty => 'Geen inhoud beschikbaar op dit moment.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Zoeken';

  @override
  String get notYetAvailable => 'Nog niet beschikbaar';
}
