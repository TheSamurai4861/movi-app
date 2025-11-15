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
}
