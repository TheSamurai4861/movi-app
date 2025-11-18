// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get welcomeTitle => 'Witamy!';

  @override
  String get welcomeSubtitle =>
      'Uzupełnij preferencje, aby spersonalizować Movi.';

  @override
  String get labelUsername => 'Pseudonim';

  @override
  String get labelPreferredLanguage => 'Preferowany język';

  @override
  String get actionContinue => 'Kontynuuj';

  @override
  String get hintUsername => 'Twój pseudonim';

  @override
  String get errorFillFields => 'Proszę poprawnie wypełnić pola.';

  @override
  String get homeWatchNow => 'Oglądaj teraz';

  @override
  String get welcomeSourceTitle => 'Witamy!';

  @override
  String get welcomeSourceSubtitle => 'Dodaj źródło, aby spersonalizować Movi.';

  @override
  String get welcomeSourceAdd => 'Dodaj źródło';

  @override
  String get searchTitle => 'Szukaj';

  @override
  String get searchHint => 'Wpisz wyszukiwanie';

  @override
  String get clear => 'Wyczyść';

  @override
  String get moviesTitle => 'Filmy';

  @override
  String get seriesTitle => 'Seriale';

  @override
  String get noResults => 'Brak wyników';

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyEmpty => 'Brak ostatnich wyszukiwań';

  @override
  String get delete => 'Usuń';

  @override
  String resultsCount(int count) {
    return '($count wyników)';
  }

  @override
  String get errorUnknown => 'Nieznany błąd';

  @override
  String errorConnectionFailed(String error) {
    return 'Połączenie nieudane: $error';
  }

  @override
  String get errorConnectionGeneric => 'Połączenie nieudane';

  @override
  String get validationRequired => 'Wymagane';

  @override
  String get validationInvalidUrl => 'Nieprawidłowy URL';

  @override
  String get snackbarSourceAddedBackground =>
      'Źródło IPTV dodane. Synchronizacja w tle…';

  @override
  String get snackbarSourceAddedSynced =>
      'Źródło IPTV dodane i zsynchronizowane';

  @override
  String get navHome => 'Strona główna';

  @override
  String get navSearch => 'Szukaj';

  @override
  String get navLibrary => 'Biblioteka';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLanguageLabel => 'Język aplikacji';

  @override
  String get settingsGeneralTitle => 'Preferencje ogólne';

  @override
  String get settingsDarkModeTitle => 'Tryb ciemny';

  @override
  String get settingsDarkModeSubtitle => 'Włącz motyw przyjazny nocy.';

  @override
  String get settingsNotificationsTitle => 'Powiadomienia';

  @override
  String get settingsNotificationsSubtitle =>
      'Bądź powiadamiany o nowych wydaniach.';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsProfileInfoTitle => 'Informacje profilu';

  @override
  String get settingsProfileInfoSubtitle => 'Imię, avatar, preferencje';

  @override
  String get settingsAboutTitle => 'O aplikacji';

  @override
  String get settingsLegalMentionsTitle => 'Informacje prawne';

  @override
  String get settingsPrivacyPolicyTitle => 'Polityka prywatności';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionConfirm => 'Zatwierdź';

  @override
  String get actionRetry => 'Spróbuj ponownie';

  @override
  String get homeErrorSwipeToRetry =>
      'Wystąpił błąd. Przeciągnij w dół, aby spróbować ponownie.';

  @override
  String get homeContinueWatching => 'Oglądane';

  @override
  String get homeNoIptvSources =>
      'Brak aktywnego źródła IPTV. Dodaj źródło w Ustawieniach, aby zobaczyć kategorie.';

  @override
  String get homeNoTrends => 'Brak treści na czasie';

  @override
  String get actionRefreshMetadata => 'Odśwież metadane';

  @override
  String get actionChangeMetadata => 'Zmień metadane';

  @override
  String get actionAddToList => 'Dodaj do listy';

  @override
  String get metadataRefreshed => 'Metadane odświeżone';

  @override
  String get errorRefreshingMetadata => 'Błąd podczas odświeżania metadanych';

  @override
  String get actionMarkSeen => 'Oznacz jako obejrzane';

  @override
  String get actionMarkUnseen => 'Oznacz jako nieobejrzane';

  @override
  String get actionReportProblem => 'Zgłoś problem';

  @override
  String get featureComingSoon => 'Funkcja wkrótce dostępna';

  @override
  String get actionLoadMore => 'Załaduj więcej';

  @override
  String get iptvServerUrlLabel => 'URL serwera';

  @override
  String get iptvServerUrlHint => 'URL serwera Xtream';

  @override
  String get iptvPasswordLabel => 'Hasło';

  @override
  String get iptvPasswordHint => 'Hasło Xtream';

  @override
  String get actionConnect => 'Połącz';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Odśwież listy IPTV';

  @override
  String get statusActive => 'Aktywne';

  @override
  String get statusNoActiveSource => 'Brak aktywnego źródła';

  @override
  String get overlayPreparingHome => 'Przygotowywanie strony głównej…';

  @override
  String get errorPrepareHome => 'Nie można przygotować strony głównej';

  @override
  String get overlayOpeningHome => 'Otwieranie strony głównej…';

  @override
  String get overlayRefreshingIptvLists => 'Odświeżanie list IPTV…';

  @override
  String get overlayPreparingMetadata => 'Przygotowywanie metadanych…';

  @override
  String get errorHomeLoadTimeout =>
      'Przekroczono czas oczekiwania ładowania strony głównej';

  @override
  String get faqLabel => 'Najczęściej zadawane pytania';

  @override
  String get iptvUsernameLabel => 'Nazwa użytkownika';

  @override
  String get iptvUsernameHint => 'Nazwa użytkownika Xtream';

  @override
  String get actionBack => 'Wstecz';

  @override
  String get actionExpand => 'Rozwiń';

  @override
  String get actionCollapse => 'Zwiń';

  @override
  String get actionClearHistory => 'Wyczyść historię';

  @override
  String get castTitle => 'Obsada';

  @override
  String get recommendationsTitle => 'Polecane';

  @override
  String get libraryHeader => 'Twoja wideoteka';

  @override
  String get libraryDataInfo =>
      'Dane zostaną wyświetlone po implementacji warstw data/domain.';

  @override
  String get libraryEmpty =>
      'Polub filmy, seriale lub aktorów, aby zobaczyć je tutaj.';

  @override
  String get serie => 'Serial';

  @override
  String get recherche => 'Szukaj';

  @override
  String get notYetAvailable => 'Jeszcze niedostępne';
}
