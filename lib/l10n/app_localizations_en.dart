// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle => 'Fill your preferences to personalize Movi.';

  @override
  String get labelUsername => 'Nickname';

  @override
  String get labelPreferredLanguage => 'Preferred Language';

  @override
  String get actionContinue => 'Continue';

  @override
  String get hintUsername => 'Your nickname';

  @override
  String get errorFillFields => 'Please fill the fields correctly.';

  @override
  String get homeWatchNow => 'Watch now';

  @override
  String get welcomeSourceTitle => 'Welcome!';

  @override
  String get welcomeSourceSubtitle =>
      'Add a source to personalize your experience in Movi.';

  @override
  String get welcomeSourceAdd => 'Add a source';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Type your search';

  @override
  String get clear => 'Clear';

  @override
  String get moviesTitle => 'Movies';

  @override
  String get seriesTitle => 'Shows';

  @override
  String get noResults => 'No results';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No recent searches';

  @override
  String get delete => 'Delete';

  @override
  String resultsCount(int count) {
    return '($count results)';
  }

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String errorConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get errorConnectionGeneric => 'Connection failed';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalidUrl => 'Invalid URL';

  @override
  String get snackbarSourceAddedBackground =>
      'IPTV source added. Sync in background…';

  @override
  String get snackbarSourceAddedSynced => 'IPTV source added and synchronized';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageLabel => 'Application Language';

  @override
  String get settingsGeneralTitle => 'General Preferences';

  @override
  String get settingsDarkModeTitle => 'Dark Mode';

  @override
  String get settingsDarkModeSubtitle => 'Enable a night-friendly theme.';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Be notified of new releases.';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsProfileInfoTitle => 'Profile information';

  @override
  String get settingsProfileInfoSubtitle => 'Name, avatar, preferences';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsLegalMentionsTitle => 'Legal mentions';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy policy';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionRetry => 'Retry';

  @override
  String get homeErrorSwipeToRetry => 'An error occurred. Swipe down to retry.';

  @override
  String get homeContinueWatching => 'Continue watching';

  @override
  String get homeNoIptvSources =>
      'No IPTV source active. Add a source in Settings to see your categories.';

  @override
  String get homeNoTrends => 'No trending content available';

  @override
  String get actionChangeMetadata => 'Change metadata';

  @override
  String get actionAddToList => 'Add to a list';

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
  String get actionBack => 'Back';

  @override
  String get actionExpand => 'Expand';

  @override
  String get castTitle => 'Cast';

  @override
  String get recommendationsTitle => 'Recommendations';

  @override
  String get libraryHeader => 'Your library';

  @override
  String get libraryDataInfo =>
      'Data will be displayed when data/domain is implemented.';

  @override
  String get libraryEmpty => 'No content available yet.';
}
