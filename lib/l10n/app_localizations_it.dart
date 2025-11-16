// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get welcomeTitle => 'Benvenuto!';

  @override
  String get welcomeSubtitle =>
      'Compila le tue preferenze per personalizzare Movi.';

  @override
  String get labelUsername => 'Nickname';

  @override
  String get labelPreferredLanguage => 'Lingua preferita';

  @override
  String get actionContinue => 'Continua';

  @override
  String get hintUsername => 'Il tuo nickname';

  @override
  String get errorFillFields => 'Compila correttamente i campi.';

  @override
  String get homeWatchNow => 'Guarda ora';

  @override
  String get welcomeSourceTitle => 'Benvenuto!';

  @override
  String get welcomeSourceSubtitle =>
      'Aggiungi una sorgente per personalizzare la tua esperienza su Movi.';

  @override
  String get welcomeSourceAdd => 'Aggiungi una sorgente';

  @override
  String get searchTitle => 'Cerca';

  @override
  String get searchHint => 'Scrivi la tua ricerca';

  @override
  String get clear => 'Cancella';

  @override
  String get moviesTitle => 'Film';

  @override
  String get seriesTitle => 'Serie';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get historyEmpty => 'Nessuna ricerca recente';

  @override
  String get delete => 'Elimina';

  @override
  String resultsCount(int count) {
    return '($count risultati)';
  }

  @override
  String get errorUnknown => 'Errore sconosciuto';

  @override
  String errorConnectionFailed(String error) {
    return 'Connessione non riuscita: $error';
  }

  @override
  String get errorConnectionGeneric => 'Connessione non riuscita';

  @override
  String get validationRequired => 'Obbligatorio';

  @override
  String get validationInvalidUrl => 'URL non valido';

  @override
  String get snackbarSourceAddedBackground =>
      'Sorgente IPTV aggiunta. Sincronizzazione in background…';

  @override
  String get snackbarSourceAddedSynced =>
      'Sorgente IPTV aggiunta e sincronizzata';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Cerca';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguageLabel => 'Lingua dell’app';

  @override
  String get settingsGeneralTitle => 'Preferenze generali';

  @override
  String get settingsDarkModeTitle => 'Modalità scura';

  @override
  String get settingsDarkModeSubtitle => 'Abilita un tema adatto alla notte.';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsNotificationsSubtitle =>
      'Ricevi avvisi sulle nuove uscite.';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsProfileInfoTitle => 'Informazioni profilo';

  @override
  String get settingsProfileInfoSubtitle => 'Nome, avatar, preferenze';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsLegalMentionsTitle => 'Note legali';

  @override
  String get settingsPrivacyPolicyTitle => 'Informativa sulla privacy';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionConfirm => 'Conferma';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get homeErrorSwipeToRetry =>
      'Si è verificato un errore. Scorri verso il basso per riprovare.';

  @override
  String get homeContinueWatching => 'Continua a guardare';

  @override
  String get homeNoIptvSources =>
      'Nessuna sorgente IPTV attiva. Aggiungi una sorgente in Impostazioni per vedere le tue categorie.';

  @override
  String get homeNoTrends => 'Nessun contenuto di tendenza disponibile';

  @override
  String get actionBack => 'Indietro';

  @override
  String get actionExpand => 'Espandi';

  @override
  String get castTitle => 'Cast';

  @override
  String get recommendationsTitle => 'Consigli';

  @override
  String get libraryHeader => 'La tua videoteca';

  @override
  String get libraryDataInfo =>
      'I dati verranno mostrati quando data/domain sarà implementato.';

  @override
  String get libraryEmpty => 'Nessun contenuto disponibile al momento.';
}
