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
  String get actionMarkSeen => 'Markeren als gezien';

  @override
  String get actionMarkUnseen => 'Markeren als niet gezien';

  @override
  String get actionReportProblem => 'Een probleem melden';

  @override
  String get featureComingSoon => 'Functie binnenkort beschikbaar';

  @override
  String get actionLoadMore => 'Meer laden';

  @override
  String get iptvServerUrlLabel => 'Server-URL';

  @override
  String get iptvServerUrlHint => 'Xtream server-URL';

  @override
  String get iptvPasswordLabel => 'Wachtwoord';

  @override
  String get iptvPasswordHint => 'Xtream wachtwoord';

  @override
  String get actionConnect => 'Verbinden';

  @override
  String get settingsRefreshIptvPlaylistsTitle =>
      'IPTV-afspeellijsten vernieuwen';

  @override
  String get statusActive => 'Actief';

  @override
  String get statusNoActiveSource => 'Geen actieve bron';

  @override
  String get overlayPreparingHome => 'Startpagina voorbereiden…';

  @override
  String get errorPrepareHome => 'Kan de startpagina niet voorbereiden';

  @override
  String get overlayOpeningHome => 'Startpagina openen…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV-lijsten vernieuwen…';

  @override
  String get overlayPreparingMetadata => 'Metadata voorbereiden…';

  @override
  String get errorHomeLoadTimeout => 'Time-out bij laden startpagina';

  @override
  String get faqLabel => 'Veelgestelde vragen';

  @override
  String get iptvUsernameLabel => 'Gebruikersnaam';

  @override
  String get iptvUsernameHint => 'Xtream gebruikersnaam';

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
  String get libraryEmpty =>
      'Like films, series of acteurs om ze hier te zien verschijnen.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Zoeken';

  @override
  String get notYetAvailable => 'Nog niet beschikbaar';
}
