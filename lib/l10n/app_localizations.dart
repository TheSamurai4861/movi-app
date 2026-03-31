import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill your preferences to personalize Movi.'**
  String get welcomeSubtitle;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get labelUsername;

  /// No description provided for @labelPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get labelPreferredLanguage;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get hintUsername;

  /// No description provided for @errorFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill the fields correctly.'**
  String get errorFillFields;

  /// No description provided for @homeWatchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get homeWatchNow;

  /// No description provided for @welcomeSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeSourceTitle;

  /// No description provided for @welcomeSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a source to personalize your experience in Movi.'**
  String get welcomeSourceSubtitle;

  /// No description provided for @welcomeSourceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a source'**
  String get welcomeSourceAdd;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Type your search'**
  String get searchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @moviesTitle.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get moviesTitle;

  /// No description provided for @seriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get seriesTitle;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent searches'**
  String get historyEmpty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} results)'**
  String resultsCount(int count);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String errorConnectionFailed(String error);

  /// No description provided for @errorConnectionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get errorConnectionGeneric;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get validationInvalidUrl;

  /// No description provided for @snackbarSourceAddedBackground.
  ///
  /// In en, this message translates to:
  /// **'IPTV source added. Sync in background…'**
  String get snackbarSourceAddedBackground;

  /// No description provided for @snackbarSourceAddedSynced.
  ///
  /// In en, this message translates to:
  /// **'IPTV source added and synchronized'**
  String get snackbarSourceAddedSynced;

  /// Sidebar navigation label: Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Sidebar navigation label: Search tab
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Sidebar navigation label: Library tab
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Sidebar navigation label: Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkModeTitle;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable a night-friendly theme.'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be notified of new releases.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountTitle;

  /// No description provided for @settingsProfileInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get settingsProfileInfoTitle;

  /// No description provided for @settingsProfileInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, avatar, preferences'**
  String get settingsProfileInfoSubtitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsLegalMentionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal mentions'**
  String get settingsLegalMentionsTitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @settingsHelpDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Help & diagnostics'**
  String get settingsHelpDiagnosticsSection;

  /// No description provided for @settingsExportErrorLogs.
  ///
  /// In en, this message translates to:
  /// **'Export error logs'**
  String get settingsExportErrorLogs;

  /// No description provided for @diagnosticsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export error logs'**
  String get diagnosticsExportTitle;

  /// No description provided for @diagnosticsExportDescription.
  ///
  /// In en, this message translates to:
  /// **'The diagnostic only includes recent WARN/ERROR logs and hashed account/profile identifiers (if enabled). No key/token should appear.'**
  String get diagnosticsExportDescription;

  /// No description provided for @diagnosticsIncludeHashedIdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Include account/profile identifiers (hashed)'**
  String get diagnosticsIncludeHashedIdsTitle;

  /// No description provided for @diagnosticsIncludeHashedIdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps correlate a bug without exposing the raw ID.'**
  String get diagnosticsIncludeHashedIdsSubtitle;

  /// No description provided for @diagnosticsCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic copied to clipboard.'**
  String get diagnosticsCopiedClipboard;

  /// No description provided for @diagnosticsSavedFile.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic saved: {fileName}'**
  String diagnosticsSavedFile(String fileName);

  /// No description provided for @diagnosticsActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get diagnosticsActionCopy;

  /// No description provided for @diagnosticsActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get diagnosticsActionSave;

  /// No description provided for @actionChangeVersion.
  ///
  /// In en, this message translates to:
  /// **'Change version'**
  String get actionChangeVersion;

  /// No description provided for @semanticsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get semanticsBack;

  /// No description provided for @semanticsMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get semanticsMoreActions;

  /// No description provided for @snackbarLoadingPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists…'**
  String get snackbarLoadingPlaylists;

  /// No description provided for @snackbarNoPlaylistsAvailableCreateOne.
  ///
  /// In en, this message translates to:
  /// **'No playlist available. Create one.'**
  String get snackbarNoPlaylistsAvailableCreateOne;

  /// No description provided for @errorAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error adding to playlist: {error}'**
  String errorAddToPlaylist(String error);

  /// No description provided for @errorAlreadyInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'This media is already in this playlist'**
  String get errorAlreadyInPlaylist;

  /// No description provided for @errorLoadingPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists: {message}'**
  String errorLoadingPlaylists(String message);

  /// No description provided for @errorReportUnavailableForContent.
  ///
  /// In en, this message translates to:
  /// **'Reporting is unavailable for this content.'**
  String get errorReportUnavailableForContent;

  /// No description provided for @snackbarLoadingEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes are loading…'**
  String get snackbarLoadingEpisodes;

  /// No description provided for @snackbarEpisodeUnavailableInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Episode unavailable in playlist'**
  String get snackbarEpisodeUnavailableInPlaylist;

  /// No description provided for @snackbarGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String snackbarGenericError(String error);

  /// No description provided for @snackbarLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get snackbarLoading;

  /// No description provided for @snackbarNoVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No version available'**
  String get snackbarNoVersionAvailable;

  /// No description provided for @snackbarVersionSaved.
  ///
  /// In en, this message translates to:
  /// **'Version saved'**
  String get snackbarVersionSaved;

  /// No description provided for @playbackVariantFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {index}'**
  String playbackVariantFallbackLabel(int index);

  /// No description provided for @actionReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get actionReadMore;

  /// No description provided for @actionShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get actionShowLess;

  /// No description provided for @actionViewPage.
  ///
  /// In en, this message translates to:
  /// **'View page'**
  String get actionViewPage;

  /// No description provided for @semanticsSeeSagaPage.
  ///
  /// In en, this message translates to:
  /// **'See saga page'**
  String get semanticsSeeSagaPage;

  /// No description provided for @libraryTypeSaga.
  ///
  /// In en, this message translates to:
  /// **'Saga'**
  String get libraryTypeSaga;

  /// No description provided for @libraryTypeInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get libraryTypeInProgress;

  /// No description provided for @libraryTypeFavoriteMovies.
  ///
  /// In en, this message translates to:
  /// **'Favorite movies'**
  String get libraryTypeFavoriteMovies;

  /// No description provided for @libraryTypeFavoriteSeries.
  ///
  /// In en, this message translates to:
  /// **'Favorite shows'**
  String get libraryTypeFavoriteSeries;

  /// No description provided for @libraryTypeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryTypeHistory;

  /// No description provided for @libraryTypePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get libraryTypePlaylist;

  /// No description provided for @libraryTypeArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get libraryTypeArtist;

  /// No description provided for @libraryItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item'**
  String libraryItemCount(int count);

  /// No description provided for @snackbarPlaylistRenamed.
  ///
  /// In en, this message translates to:
  /// **'Playlist renamed to \"{name}\"'**
  String snackbarPlaylistRenamed(String name);

  /// No description provided for @snackbarPlaylistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get snackbarPlaylistDeleted;

  /// No description provided for @dialogConfirmDeletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String dialogConfirmDeletePlaylist(String title);

  /// No description provided for @libraryNoResultsForQuery.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String libraryNoResultsForQuery(String query);

  /// No description provided for @errorGenericWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGenericWithMessage(String error);

  /// No description provided for @snackbarMediaAlreadyInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'This media is already in the playlist'**
  String get snackbarMediaAlreadyInPlaylist;

  /// No description provided for @snackbarAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to the playlist'**
  String get snackbarAddedToPlaylist;

  /// No description provided for @addMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMediaTitle;

  /// No description provided for @searchMinCharsHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters to search'**
  String get searchMinCharsHint;

  /// No description provided for @badgeAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get badgeAdded;

  /// No description provided for @snackbarNotAvailableOnSource.
  ///
  /// In en, this message translates to:
  /// **'Not available on this source'**
  String get snackbarNotAvailableOnSource;

  /// No description provided for @errorLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get errorLoadingTitle;

  /// No description provided for @errorLoadingWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading error: {error}'**
  String errorLoadingWithMessage(String error);

  /// No description provided for @errorLoadingPlaylistsWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists: {error}'**
  String errorLoadingPlaylistsWithMessage(String error);

  /// No description provided for @libraryClearFilterSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get libraryClearFilterSemanticLabel;

  /// No description provided for @homeErrorSwipeToRetry.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Swipe down to retry.'**
  String get homeErrorSwipeToRetry;

  /// No description provided for @homeContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get homeContinueWatching;

  /// No description provided for @homeNoIptvSources.
  ///
  /// In en, this message translates to:
  /// **'No IPTV source active. Add a source in Settings to see your categories.'**
  String get homeNoIptvSources;

  /// No description provided for @homeNoTrends.
  ///
  /// In en, this message translates to:
  /// **'No trending content available'**
  String get homeNoTrends;

  /// No description provided for @actionRefreshMetadata.
  ///
  /// In en, this message translates to:
  /// **'Refresh metadata'**
  String get actionRefreshMetadata;

  /// No description provided for @actionChangeMetadata.
  ///
  /// In en, this message translates to:
  /// **'Change metadata'**
  String get actionChangeMetadata;

  /// No description provided for @actionAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to a list'**
  String get actionAddToList;

  /// No description provided for @metadataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Metadata refreshed'**
  String get metadataRefreshed;

  /// No description provided for @errorRefreshingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing metadata'**
  String get errorRefreshingMetadata;

  /// No description provided for @actionMarkSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen'**
  String get actionMarkSeen;

  /// No description provided for @actionMarkUnseen.
  ///
  /// In en, this message translates to:
  /// **'Mark as unseen'**
  String get actionMarkUnseen;

  /// No description provided for @actionReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get actionReportProblem;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @subtitlesMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitlesMenuTitle;

  /// No description provided for @audioMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioMenuTitle;

  /// No description provided for @videoFitModeMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Display mode'**
  String get videoFitModeMenuTitle;

  /// No description provided for @videoFitModeContain.
  ///
  /// In en, this message translates to:
  /// **'Original proportions'**
  String get videoFitModeContain;

  /// No description provided for @videoFitModeCover.
  ///
  /// In en, this message translates to:
  /// **'Fill screen'**
  String get videoFitModeCover;

  /// No description provided for @actionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get actionDisable;

  /// No description provided for @defaultTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track {id}'**
  String defaultTrackLabel(String id);

  /// No description provided for @controlRewind10.
  ///
  /// In en, this message translates to:
  /// **'10 s'**
  String get controlRewind10;

  /// No description provided for @controlRewind30.
  ///
  /// In en, this message translates to:
  /// **'30 s'**
  String get controlRewind30;

  /// No description provided for @controlForward10.
  ///
  /// In en, this message translates to:
  /// **'+ 10 s'**
  String get controlForward10;

  /// No description provided for @controlForward30.
  ///
  /// In en, this message translates to:
  /// **'+ 30 s'**
  String get controlForward30;

  /// No description provided for @actionNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get actionNextEpisode;

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get actionRestart;

  /// No description provided for @errorSeriesDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load series data'**
  String get errorSeriesDataUnavailable;

  /// No description provided for @errorNextEpisodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine next episode'**
  String get errorNextEpisodeFailed;

  /// No description provided for @actionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get actionLoadMore;

  /// No description provided for @iptvServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get iptvServerUrlLabel;

  /// No description provided for @iptvServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Xtream server URL'**
  String get iptvServerUrlHint;

  /// No description provided for @iptvPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get iptvPasswordLabel;

  /// No description provided for @iptvPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Xtream password'**
  String get iptvPasswordHint;

  /// No description provided for @actionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get actionConnect;

  /// No description provided for @settingsRefreshIptvPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh IPTV playlists'**
  String get settingsRefreshIptvPlaylistsTitle;

  /// No description provided for @activeSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Active source'**
  String get activeSourceTitle;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusNoActiveSource.
  ///
  /// In en, this message translates to:
  /// **'No active source'**
  String get statusNoActiveSource;

  /// No description provided for @overlayPreparingHome.
  ///
  /// In en, this message translates to:
  /// **'Preparing home…'**
  String get overlayPreparingHome;

  /// No description provided for @overlayLoadingMoviesAndSeries.
  ///
  /// In en, this message translates to:
  /// **'Loading movies & shows…'**
  String get overlayLoadingMoviesAndSeries;

  /// No description provided for @overlayLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories…'**
  String get overlayLoadingCategories;

  /// No description provided for @bootstrapRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing IPTV lists…'**
  String get bootstrapRefreshing;

  /// No description provided for @bootstrapEnriching.
  ///
  /// In en, this message translates to:
  /// **'Preparing metadata…'**
  String get bootstrapEnriching;

  /// No description provided for @errorPrepareHome.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare the home page'**
  String get errorPrepareHome;

  /// No description provided for @overlayOpeningHome.
  ///
  /// In en, this message translates to:
  /// **'Opening home…'**
  String get overlayOpeningHome;

  /// No description provided for @overlayRefreshingIptvLists.
  ///
  /// In en, this message translates to:
  /// **'Refreshing IPTV lists…'**
  String get overlayRefreshingIptvLists;

  /// No description provided for @overlayPreparingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Preparing metadata…'**
  String get overlayPreparingMetadata;

  /// No description provided for @errorHomeLoadTimeout.
  ///
  /// In en, this message translates to:
  /// **'Home load timeout'**
  String get errorHomeLoadTimeout;

  /// No description provided for @faqLabel.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqLabel;

  /// No description provided for @iptvUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get iptvUsernameLabel;

  /// No description provided for @iptvUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Xtream username'**
  String get iptvUsernameHint;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get actionSeeAll;

  /// No description provided for @actionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get actionExpand;

  /// No description provided for @actionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get actionCollapse;

  /// No description provided for @providerSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search on {provider}...'**
  String providerSearchPlaceholder(String provider);

  /// No description provided for @actionClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get actionClearHistory;

  /// No description provided for @castTitle.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get castTitle;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @libraryHeader.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get libraryHeader;

  /// No description provided for @libraryDataInfo.
  ///
  /// In en, this message translates to:
  /// **'Data will be displayed when data/domain is implemented.'**
  String get libraryDataInfo;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Like movies, series or actors to see them appear here.'**
  String get libraryEmpty;

  /// No description provided for @serie.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get serie;

  /// No description provided for @recherche.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get recherche;

  /// No description provided for @notYetAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not yet available'**
  String get notYetAvailable;

  /// No description provided for @createPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylistTitle;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMedia;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deletePlaylist;

  /// No description provided for @pinPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinPlaylist;

  /// No description provided for @unpinPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinPlaylist;

  /// No description provided for @playlistPinned.
  ///
  /// In en, this message translates to:
  /// **'Playlist pinned'**
  String get playlistPinned;

  /// No description provided for @playlistUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Playlist unpinned'**
  String get playlistUnpinned;

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// No description provided for @playlistCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" created'**
  String playlistCreatedSuccess(String name);

  /// No description provided for @playlistCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating playlist: {error}'**
  String playlistCreateError(String error);

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get addedToPlaylist;

  /// No description provided for @pinRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'Récupérer le code PIN'**
  String get pinRecoveryLink;

  /// No description provided for @pinRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover PIN code'**
  String get pinRecoveryTitle;

  /// No description provided for @pinRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Retrieve the PIN code for your protected profile.'**
  String get pinRecoveryDescription;

  /// No description provided for @pinRecoveryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get pinRecoveryComingSoon;

  /// No description provided for @pinRecoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get pinRecoveryCodeLabel;

  /// No description provided for @pinRecoveryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8 digits'**
  String get pinRecoveryCodeHint;

  /// No description provided for @pinRecoveryVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get pinRecoveryVerifyButton;

  /// No description provided for @pinRecoveryCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit code'**
  String get pinRecoveryCodeInvalid;

  /// No description provided for @pinRecoveryCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Recovery code expired'**
  String get pinRecoveryCodeExpired;

  /// No description provided for @pinRecoveryTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get pinRecoveryTooManyAttempts;

  /// No description provided for @pinRecoveryUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get pinRecoveryUnknownError;

  /// No description provided for @pinRecoveryNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get pinRecoveryNewPinLabel;

  /// No description provided for @pinRecoveryNewPinHint.
  ///
  /// In en, this message translates to:
  /// **'4-6 digits'**
  String get pinRecoveryNewPinHint;

  /// No description provided for @pinRecoveryConfirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinRecoveryConfirmPinLabel;

  /// No description provided for @pinRecoveryConfirmPinHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat the PIN'**
  String get pinRecoveryConfirmPinHint;

  /// No description provided for @pinRecoveryResetButton.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get pinRecoveryResetButton;

  /// No description provided for @pinRecoveryPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4 to 6 digit PIN'**
  String get pinRecoveryPinInvalid;

  /// No description provided for @pinRecoveryPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinRecoveryPinMismatch;

  /// No description provided for @pinRecoveryResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get pinRecoveryResetSuccess;

  /// No description provided for @settingsAccountsSection.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get settingsAccountsSection;

  /// No description provided for @settingsIptvSection.
  ///
  /// In en, this message translates to:
  /// **'IPTV Settings'**
  String get settingsIptvSection;

  /// No description provided for @settingsSourcesManagement.
  ///
  /// In en, this message translates to:
  /// **'Source Management'**
  String get settingsSourcesManagement;

  /// No description provided for @settingsSyncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Update Frequency'**
  String get settingsSyncFrequency;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppSection;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get settingsAccentColor;

  /// No description provided for @settingsPlaybackSection.
  ///
  /// In en, this message translates to:
  /// **'Playback Settings'**
  String get settingsPlaybackSection;

  /// No description provided for @settingsPreferredAudioLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get settingsPreferredAudioLanguage;

  /// No description provided for @settingsPreferredSubtitleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Subtitles'**
  String get settingsPreferredSubtitleLanguage;

  /// No description provided for @libraryPlaylistsFilter.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get libraryPlaylistsFilter;

  /// No description provided for @librarySagasFilter.
  ///
  /// In en, this message translates to:
  /// **'Sagas'**
  String get librarySagasFilter;

  /// No description provided for @libraryArtistsFilter.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryArtistsFilter;

  /// No description provided for @librarySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search in my library...'**
  String get librarySearchPlaceholder;

  /// No description provided for @libraryInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get libraryInProgress;

  /// No description provided for @libraryFavoriteMovies.
  ///
  /// In en, this message translates to:
  /// **'Favorite Movies'**
  String get libraryFavoriteMovies;

  /// No description provided for @libraryFavoriteSeries.
  ///
  /// In en, this message translates to:
  /// **'Favorite Series'**
  String get libraryFavoriteSeries;

  /// No description provided for @libraryWatchHistory.
  ///
  /// In en, this message translates to:
  /// **'Watch History'**
  String get libraryWatchHistory;

  /// No description provided for @libraryItemCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String libraryItemCountPlural(int count);

  /// No description provided for @searchPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchPeopleTitle;

  /// No description provided for @searchSagasTitle.
  ///
  /// In en, this message translates to:
  /// **'Sagas'**
  String get searchSagasTitle;

  /// No description provided for @searchByProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'By Providers'**
  String get searchByProvidersTitle;

  /// No description provided for @searchByGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'By Genres'**
  String get searchByGenresTitle;

  /// No description provided for @personRoleActor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get personRoleActor;

  /// No description provided for @personRoleDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get personRoleDirector;

  /// No description provided for @personRoleCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get personRoleCreator;

  /// No description provided for @tvDistribution.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get tvDistribution;

  /// No description provided for @tvSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String tvSeasonLabel(int number);

  /// No description provided for @tvNoEpisodesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No episodes available'**
  String get tvNoEpisodesAvailable;

  /// No description provided for @tvResumeSeasonEpisode.
  ///
  /// In en, this message translates to:
  /// **'Resume S{season} E{episode}'**
  String tvResumeSeasonEpisode(int season, int episode);

  /// No description provided for @sagaViewPage.
  ///
  /// In en, this message translates to:
  /// **'View Page'**
  String get sagaViewPage;

  /// No description provided for @sagaStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get sagaStartNow;

  /// No description provided for @sagaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sagaContinue;

  /// No description provided for @sagaMovieCount.
  ///
  /// In en, this message translates to:
  /// **'{count} films'**
  String sagaMovieCount(int count);

  /// No description provided for @sagaMoviesList.
  ///
  /// In en, this message translates to:
  /// **'Movies List'**
  String get sagaMoviesList;

  /// No description provided for @personMoviesCount.
  ///
  /// In en, this message translates to:
  /// **'{movies} films - {shows} series'**
  String personMoviesCount(int movies, int shows);

  /// No description provided for @personPlayRandomly.
  ///
  /// In en, this message translates to:
  /// **'Play Randomly'**
  String get personPlayRandomly;

  /// No description provided for @personMoviesList.
  ///
  /// In en, this message translates to:
  /// **'Movies List'**
  String get personMoviesList;

  /// No description provided for @personSeriesList.
  ///
  /// In en, this message translates to:
  /// **'Series List'**
  String get personSeriesList;

  /// No description provided for @playlistPlayRandomly.
  ///
  /// In en, this message translates to:
  /// **'Play Randomly'**
  String get playlistPlayRandomly;

  /// No description provided for @playlistAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get playlistAddButton;

  /// No description provided for @playlistSortButton.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get playlistSortButton;

  /// No description provided for @playlistSortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get playlistSortByTitle;

  /// No description provided for @playlistSortByTitleOption.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get playlistSortByTitleOption;

  /// No description provided for @playlistSortRecentAdditions.
  ///
  /// In en, this message translates to:
  /// **'Recent Additions'**
  String get playlistSortRecentAdditions;

  /// No description provided for @playlistSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get playlistSortOldestFirst;

  /// No description provided for @playlistSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get playlistSortNewestFirst;

  /// No description provided for @playlistEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No items in this playlist'**
  String get playlistEmptyMessage;

  /// No description provided for @playlistItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item'**
  String playlistItemCount(int count);

  /// No description provided for @playlistItemCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String playlistItemCountPlural(int count);

  /// No description provided for @playlistSeasonSingular.
  ///
  /// In en, this message translates to:
  /// **'season'**
  String get playlistSeasonSingular;

  /// No description provided for @playlistSeasonPlural.
  ///
  /// In en, this message translates to:
  /// **'seasons'**
  String get playlistSeasonPlural;

  /// No description provided for @playlistRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get playlistRenameTitle;

  /// No description provided for @playlistNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistNamePlaceholder;

  /// No description provided for @playlistRenamedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist renamed to \"{name}\"'**
  String playlistRenamedSuccess(String name);

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get playlistDeleteTitle;

  /// No description provided for @playlistDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String playlistDeleteConfirm(String title);

  /// No description provided for @playlistDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeletedSuccess;

  /// No description provided for @playlistItemRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item removed'**
  String get playlistItemRemovedSuccess;

  /// No description provided for @playlistRemoveItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from playlist?'**
  String playlistRemoveItemConfirm(String title);

  /// No description provided for @categoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load category.'**
  String get categoryLoadFailed;

  /// No description provided for @categoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in this category.'**
  String get categoryEmpty;

  /// No description provided for @categoryLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get categoryLoadingMore;

  /// No description provided for @movieNoPlaylistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No playlist available'**
  String get movieNoPlaylistsAvailable;

  /// No description provided for @playlistAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{title}\"'**
  String playlistAddedTo(String title);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @movieNotAvailableInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Movie not available in the playlist'**
  String get movieNotAvailableInPlaylist;

  /// No description provided for @errorPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Error playing movie: {message}'**
  String errorPlaybackFailed(String message);

  /// No description provided for @movieNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media to display'**
  String get movieNoMedia;

  /// No description provided for @personNoData.
  ///
  /// In en, this message translates to:
  /// **'No person to display.'**
  String get personNoData;

  /// No description provided for @personGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading this person.'**
  String get personGenericError;

  /// No description provided for @personBiographyTitle.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get personBiographyTitle;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authOtpTitle;

  /// No description provided for @authOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and the 8-digit code we send you.'**
  String get authOtpSubtitle;

  /// No description provided for @authOtpEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authOtpEmailLabel;

  /// No description provided for @authOtpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email'**
  String get authOtpEmailHint;

  /// No description provided for @authOtpEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'We will send you an 8-digit code. Check spam if needed.'**
  String get authOtpEmailHelp;

  /// No description provided for @authOtpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpCodeLabel;

  /// No description provided for @authOtpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8-digit code'**
  String get authOtpCodeHint;

  /// No description provided for @authOtpCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit code received by email.'**
  String get authOtpCodeHelp;

  /// No description provided for @authOtpPrimarySend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authOtpPrimarySend;

  /// No description provided for @authOtpPrimarySubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authOtpPrimarySubmit;

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @authOtpResendDisabled.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authOtpResendDisabled(int seconds);

  /// No description provided for @authOtpChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get authOtpChangeEmail;

  /// No description provided for @resumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get resumePlayback;

  /// No description provided for @settingsCloudSyncSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get settingsCloudSyncSection;

  /// No description provided for @settingsCloudSyncAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto sync'**
  String get settingsCloudSyncAuto;

  /// No description provided for @settingsCloudSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsCloudSyncNow;

  /// No description provided for @settingsCloudSyncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get settingsCloudSyncInProgress;

  /// No description provided for @settingsCloudSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsCloudSyncNever;

  /// No description provided for @settingsCloudSyncError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String settingsCloudSyncError(Object error);

  /// No description provided for @notFoundWithEntity.
  ///
  /// In en, this message translates to:
  /// **'{entity} not found'**
  String notFoundWithEntity(String entity);

  /// No description provided for @notFoundWithEntityAndError.
  ///
  /// In en, this message translates to:
  /// **'{entity} not found: {error}'**
  String notFoundWithEntityAndError(String entity, String error);

  /// No description provided for @entityProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get entityProvider;

  /// No description provided for @entityGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get entityGenre;

  /// No description provided for @entityPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get entityPlaylist;

  /// No description provided for @entitySource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get entitySource;

  /// No description provided for @entityMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get entityMovie;

  /// No description provided for @entitySeries.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get entitySeries;

  /// No description provided for @entityPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get entityPerson;

  /// No description provided for @entitySaga.
  ///
  /// In en, this message translates to:
  /// **'Saga'**
  String get entitySaga;

  /// No description provided for @entityVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get entityVideo;

  /// No description provided for @entityRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get entityRoute;

  /// No description provided for @errorTimeoutLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading timed out'**
  String get errorTimeoutLoading;

  /// No description provided for @parentalContentRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted Content'**
  String get parentalContentRestricted;

  /// No description provided for @parentalContentRestrictedDefault.
  ///
  /// In en, this message translates to:
  /// **'This content is blocked by this profile\'s parental controls.'**
  String get parentalContentRestrictedDefault;

  /// No description provided for @parentalReasonTooYoung.
  ///
  /// In en, this message translates to:
  /// **'This content requires an age higher than this profile\'s limit.'**
  String get parentalReasonTooYoung;

  /// No description provided for @parentalReasonUnknownRating.
  ///
  /// In en, this message translates to:
  /// **'The age rating for this content is not available.'**
  String get parentalReasonUnknownRating;

  /// No description provided for @parentalReasonInvalidTmdbId.
  ///
  /// In en, this message translates to:
  /// **'This content cannot be evaluated for parental control.'**
  String get parentalReasonInvalidTmdbId;

  /// No description provided for @parentalUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get parentalUnlockButton;

  /// No description provided for @hc_arb_dir_4de4827b.
  ///
  /// In en, this message translates to:
  /// **'arb-dir'**
  String get hc_arb_dir_4de4827b;

  /// No description provided for @hc_template_arb_file_eeae5194.
  ///
  /// In en, this message translates to:
  /// **'template-arb-file'**
  String get hc_template_arb_file_eeae5194;

  /// No description provided for @hc_output_localization_file_ed018380.
  ///
  /// In en, this message translates to:
  /// **'output-localization-file'**
  String get hc_output_localization_file_ed018380;

  /// No description provided for @hc_output_class_f1ae6b52.
  ///
  /// In en, this message translates to:
  /// **'output-class'**
  String get hc_output_class_f1ae6b52;

  /// No description provided for @hc_applocalizations_878fdc50.
  ///
  /// In en, this message translates to:
  /// **'AppLocalizations'**
  String get hc_applocalizations_878fdc50;

  /// No description provided for @hc_untranslated_messages_file_fa6a22b7.
  ///
  /// In en, this message translates to:
  /// **'untranslated-messages-file'**
  String get hc_untranslated_messages_file_fa6a22b7;

  /// No description provided for @hc_chargement_episodes_en_cours_33fc4ace.
  ///
  /// In en, this message translates to:
  /// **'Loading episodes…'**
  String get hc_chargement_episodes_en_cours_33fc4ace;

  /// No description provided for @hc_aucune_playlist_disponible_creez_en_une_f6b75c90.
  ///
  /// In en, this message translates to:
  /// **'No playlist available. Create one.'**
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90;

  /// No description provided for @hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3.
  ///
  /// In en, this message translates to:
  /// **'Error while loading playlists: \$e'**
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3;

  /// No description provided for @hc_impossible_douvrir_lien_90d0dcaa.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the link'**
  String get hc_impossible_douvrir_lien_90d0dcaa;

  /// No description provided for @hc_qualite_preferee_776dbeea.
  ///
  /// In en, this message translates to:
  /// **'Preferred quality'**
  String get hc_qualite_preferee_776dbeea;

  /// No description provided for @hc_annuler_49ba3292.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hc_annuler_49ba3292;

  /// No description provided for @hc_deconnexion_903dca17.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get hc_deconnexion_903dca17;

  /// No description provided for @hc_erreur_lors_deconnexion_placeholder_f5a211b4.
  ///
  /// In en, this message translates to:
  /// **'Error while signing out: \$e'**
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4;

  /// No description provided for @hc_choisir_b030d590.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get hc_choisir_b030d590;

  /// No description provided for @hc_avantages_08d7f47c.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get hc_avantages_08d7f47c;

  /// No description provided for @hc_signalement_envoye_merci_d302e576.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you.'**
  String get hc_signalement_envoye_merci_d302e576;

  /// No description provided for @hc_plus_tard_1f42ab3b.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get hc_plus_tard_1f42ab3b;

  /// No description provided for @hc_redemarrer_maintenant_053e8e68.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get hc_redemarrer_maintenant_053e8e68;

  /// No description provided for @hc_utiliser_cette_source_c6c8bbc5.
  ///
  /// In en, this message translates to:
  /// **'Use this source?'**
  String get hc_utiliser_cette_source_c6c8bbc5;

  /// No description provided for @hc_utiliser_fb5e43ce.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get hc_utiliser_fb5e43ce;

  /// No description provided for @hc_source_ajout_e_e41b01d9.
  ///
  /// In en, this message translates to:
  /// **'Source added'**
  String get hc_source_ajout_e_e41b01d9;

  /// No description provided for @hc_title_0a57b7eb.
  ///
  /// In en, this message translates to:
  /// **'title: \'...\''**
  String get hc_title_0a57b7eb;

  /// No description provided for @hc_labeltext_469a28db.
  ///
  /// In en, this message translates to:
  /// **'labelText: \'...\''**
  String get hc_labeltext_469a28db;

  /// No description provided for @hc_hinttext_6fd1d945.
  ///
  /// In en, this message translates to:
  /// **'hintText: \'...\''**
  String get hc_hinttext_6fd1d945;

  /// No description provided for @hc_tooltip_db0de3fe.
  ///
  /// In en, this message translates to:
  /// **'tooltip: \'...\''**
  String get hc_tooltip_db0de3fe;

  /// No description provided for @hc_parametres_verrouilles_3a9b1b51.
  ///
  /// In en, this message translates to:
  /// **'Locked settings'**
  String get hc_parametres_verrouilles_3a9b1b51;

  /// No description provided for @hc_compte_cloud_2812b31e.
  ///
  /// In en, this message translates to:
  /// **'Cloud account'**
  String get hc_compte_cloud_2812b31e;

  /// No description provided for @hc_se_connecter_fedf2439.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get hc_se_connecter_fedf2439;

  /// No description provided for @hc_propos_5345add5.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get hc_propos_5345add5;

  /// No description provided for @hc_politique_confidentialite_42b0e51e.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get hc_politique_confidentialite_42b0e51e;

  /// No description provided for @hc_conditions_dutilisation_9074eac7.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get hc_conditions_dutilisation_9074eac7;

  /// No description provided for @hc_sources_sauvegardees_9f1382e5.
  ///
  /// In en, this message translates to:
  /// **'Saved sources'**
  String get hc_sources_sauvegardees_9f1382e5;

  /// No description provided for @hc_rafraichir_be30b7d1.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get hc_rafraichir_be30b7d1;

  /// No description provided for @hc_activer_une_source_749ced38.
  ///
  /// In en, this message translates to:
  /// **'Activate a source'**
  String get hc_activer_une_source_749ced38;

  /// No description provided for @hc_nom_source_9a3e4156.
  ///
  /// In en, this message translates to:
  /// **'Source name'**
  String get hc_nom_source_9a3e4156;

  /// No description provided for @hc_mon_iptv_b239352c.
  ///
  /// In en, this message translates to:
  /// **'My IPTV'**
  String get hc_mon_iptv_b239352c;

  /// No description provided for @hc_username_84c29015.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get hc_username_84c29015;

  /// No description provided for @hc_password_8be3c943.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hc_password_8be3c943;

  /// No description provided for @hc_server_url_1d5d1eff.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get hc_server_url_1d5d1eff;

  /// No description provided for @hc_verification_pin_e17c8fe0.
  ///
  /// In en, this message translates to:
  /// **'PIN verification'**
  String get hc_verification_pin_e17c8fe0;

  /// No description provided for @hc_definir_un_pin_f9c2178d.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get hc_definir_un_pin_f9c2178d;

  /// No description provided for @hc_pin_3adadd31.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get hc_pin_3adadd31;

  /// No description provided for @hc_message_9ff08507.
  ///
  /// In en, this message translates to:
  /// **'message: \'...\''**
  String get hc_message_9ff08507;

  /// No description provided for @hc_subscription_offer_not_found_placeholder_d07ac9d3.
  ///
  /// In en, this message translates to:
  /// **'Subscription offer not found: \$offerId.'**
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3;

  /// No description provided for @hc_subscription_purchase_was_cancelled_by_user_443e1dab.
  ///
  /// In en, this message translates to:
  /// **'The subscription purchase was cancelled by the user.'**
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab;

  /// No description provided for @hc_store_operation_timed_out_placeholder_6c3f9df2.
  ///
  /// In en, this message translates to:
  /// **'The store operation timed out: \$operation.'**
  String get hc_store_operation_timed_out_placeholder_6c3f9df2;

  /// No description provided for @hc_erreur_http_lors_handshake_02db57b2.
  ///
  /// In en, this message translates to:
  /// **'HTTP error during handshake'**
  String get hc_erreur_http_lors_handshake_02db57b2;

  /// No description provided for @hc_reponse_non_json_serveur_xtream_e896b8df.
  ///
  /// In en, this message translates to:
  /// **'Non-JSON response from Xtream server'**
  String get hc_reponse_non_json_serveur_xtream_e896b8df;

  /// No description provided for @hc_reponse_invalide_serveur_xtream_afc0955f.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from Xtream server'**
  String get hc_reponse_invalide_serveur_xtream_afc0955f;

  /// No description provided for @hc_rg_exe_af0d2be6.
  ///
  /// In en, this message translates to:
  /// **'rg.exe'**
  String get hc_rg_exe_af0d2be6;

  /// No description provided for @hc_alertdialog_5a747a86.
  ///
  /// In en, this message translates to:
  /// **'AlertDialog'**
  String get hc_alertdialog_5a747a86;

  /// No description provided for @hc_cupertinoalertdialog_3ed27f52.
  ///
  /// In en, this message translates to:
  /// **'CupertinoAlertDialog'**
  String get hc_cupertinoalertdialog_3ed27f52;

  /// No description provided for @hc_pas_disponible_sur_cette_source_fa6e19a7.
  ///
  /// In en, this message translates to:
  /// **'Not available on this source'**
  String get hc_pas_disponible_sur_cette_source_fa6e19a7;

  /// No description provided for @hc_source_supprimee_4bfaa0a1.
  ///
  /// In en, this message translates to:
  /// **'Source removed'**
  String get hc_source_supprimee_4bfaa0a1;

  /// No description provided for @hc_source_modifiee_335ef502.
  ///
  /// In en, this message translates to:
  /// **'Source updated'**
  String get hc_source_modifiee_335ef502;

  /// No description provided for @hc_definir_code_pin_53a0bd07.
  ///
  /// In en, this message translates to:
  /// **'Set PIN code'**
  String get hc_definir_code_pin_53a0bd07;

  /// No description provided for @hc_marquer_comme_non_vu_9cf9d3f8.
  ///
  /// In en, this message translates to:
  /// **'Mark as unwatched'**
  String get hc_marquer_comme_non_vu_9cf9d3f8;

  /// No description provided for @hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661;

  /// No description provided for @hc_movi_premium_requis_pour_synchronisation_cloud_15b551df.
  ///
  /// In en, this message translates to:
  /// **'Movi Premium is required for cloud sync.'**
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df;

  /// No description provided for @hc_auto_c614ba7c.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get hc_auto_c614ba7c;

  /// No description provided for @hc_organiser_838a7e57.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get hc_organiser_838a7e57;

  /// No description provided for @hc_modifier_f260e757.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hc_modifier_f260e757;

  /// No description provided for @hc_ajouter_87c57ed1.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hc_ajouter_87c57ed1;

  /// No description provided for @hc_source_active_e571305e.
  ///
  /// In en, this message translates to:
  /// **'Active source'**
  String get hc_source_active_e571305e;

  /// No description provided for @hc_autres_sources_e32592a6.
  ///
  /// In en, this message translates to:
  /// **'Other sources'**
  String get hc_autres_sources_e32592a6;

  /// No description provided for @hc_signalement_indisponible_pour_ce_contenu_d9ad88b7.
  ///
  /// In en, this message translates to:
  /// **'Reporting is unavailable for this content.'**
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7;

  /// No description provided for @hc_securisation_contenu_e5195111.
  ///
  /// In en, this message translates to:
  /// **'Securing content'**
  String get hc_securisation_contenu_e5195111;

  /// No description provided for @hc_verification_classifications_d_age_006eebfe.
  ///
  /// In en, this message translates to:
  /// **'Checking age ratings…'**
  String get hc_verification_classifications_d_age_006eebfe;

  /// No description provided for @hc_voir_tout_7b7d86e8.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get hc_voir_tout_7b7d86e8;

  /// No description provided for @hc_signaler_un_probleme_13183c0f.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get hc_signaler_un_probleme_13183c0f;

  /// No description provided for @hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436.
  ///
  /// In en, this message translates to:
  /// **'If this content is not appropriate and was accessible despite restrictions, briefly describe the issue.'**
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436;

  /// No description provided for @hc_envoyer_e9ce243b.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get hc_envoyer_e9ce243b;

  /// No description provided for @hc_profil_enfant_cree_39f4eb7d.
  ///
  /// In en, this message translates to:
  /// **'Child profile created'**
  String get hc_profil_enfant_cree_39f4eb7d;

  /// No description provided for @hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a.
  ///
  /// In en, this message translates to:
  /// **'A child profile was created. To secure the app and preload age ratings, restarting the app is recommended.'**
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a;

  /// No description provided for @hc_pseudo_4cf966c0.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get hc_pseudo_4cf966c0;

  /// No description provided for @hc_profil_enfant_2c8a01c0.
  ///
  /// In en, this message translates to:
  /// **'Child profile'**
  String get hc_profil_enfant_2c8a01c0;

  /// No description provided for @hc_limite_d_age_5b170fc9.
  ///
  /// In en, this message translates to:
  /// **'Age limit'**
  String get hc_limite_d_age_5b170fc9;

  /// No description provided for @hc_code_pin_e79c48bd.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get hc_code_pin_e79c48bd;

  /// No description provided for @hc_changer_code_pin_3b069731.
  ///
  /// In en, this message translates to:
  /// **'Change PIN code'**
  String get hc_changer_code_pin_3b069731;

  /// No description provided for @hc_supprimer_code_pin_0dcf8a48.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN code'**
  String get hc_supprimer_code_pin_0dcf8a48;

  /// No description provided for @hc_supprimer_pin_51850c7b.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get hc_supprimer_pin_51850c7b;

  /// No description provided for @hc_supprimer_1acfc1c7.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get hc_supprimer_1acfc1c7;

  /// No description provided for @hc_oblige_un_pin_active_filtre_pegi_8447ac9b.
  ///
  /// In en, this message translates to:
  /// **'Requires a PIN and enables the PEGI filter.'**
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b;

  /// No description provided for @hc_voulez_vous_activer_cette_source_maintenant_f2593894.
  ///
  /// In en, this message translates to:
  /// **'Do you want to activate this source now?'**
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894;

  /// No description provided for @hc_application_b291beb8.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get hc_application_b291beb8;

  /// No description provided for @hc_version_1_0_0_347e553c.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get hc_version_1_0_0_347e553c;

  /// No description provided for @hc_credits_293a6081.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get hc_credits_293a6081;

  /// No description provided for @hc_this_product_uses_tmdb_api_but_is_not_0033d77f.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f;

  /// No description provided for @hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a;

  /// No description provided for @hc_verification_targets_d51632f8.
  ///
  /// In en, this message translates to:
  /// **'Verification targets'**
  String get hc_verification_targets_d51632f8;

  /// No description provided for @hc_fade_must_eat_frame_5f1bfc77.
  ///
  /// In en, this message translates to:
  /// **'The fade must eat the frame'**
  String get hc_fade_must_eat_frame_5f1bfc77;

  /// No description provided for @hc_invalid_xtream_streamid_eb04e9f9.
  ///
  /// In en, this message translates to:
  /// **'Invalid Xtream streamId: ...'**
  String get hc_invalid_xtream_streamid_eb04e9f9;

  /// No description provided for @hc_series_xtream_missing_poster_065b5103.
  ///
  /// In en, this message translates to:
  /// **'Series xtream:... missing poster'**
  String get hc_series_xtream_missing_poster_065b5103;

  /// No description provided for @hc_movie_not_found_a7fe72d9.
  ///
  /// In en, this message translates to:
  /// **'Movie ... not found ...'**
  String get hc_movie_not_found_a7fe72d9;

  /// No description provided for @hc_missing_poster_1c9ba558.
  ///
  /// In en, this message translates to:
  /// **'... missing poster'**
  String get hc_missing_poster_1c9ba558;

  /// No description provided for @hc_invalid_watchlist_outbox_payload_327ac6c3.
  ///
  /// In en, this message translates to:
  /// **'Invalid watchlist outbox payload.'**
  String get hc_invalid_watchlist_outbox_payload_327ac6c3;

  /// No description provided for @hc_unknown_watchlist_operation_e9259c07.
  ///
  /// In en, this message translates to:
  /// **'Unknown watchlist operation: ...'**
  String get hc_unknown_watchlist_operation_e9259c07;

  /// No description provided for @hc_invalid_playlist_outbox_payload_2d76e64f.
  ///
  /// In en, this message translates to:
  /// **'Invalid playlist outbox payload.'**
  String get hc_invalid_playlist_outbox_payload_2d76e64f;

  /// No description provided for @hc_unknown_playlist_operation_c98cbd41.
  ///
  /// In en, this message translates to:
  /// **'Unknown playlist operation: ...'**
  String get hc_unknown_playlist_operation_c98cbd41;

  /// No description provided for @hc_url_invalide_aa227a66.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get hc_url_invalide_aa227a66;

  /// No description provided for @hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3.
  ///
  /// In en, this message translates to:
  /// **'Missing legacy IV: cannot decrypt legacy ciphertext.'**
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3;

  /// No description provided for @hc_tooltip_rafraichir_a22b17e3.
  ///
  /// In en, this message translates to:
  /// **'tooltip: \'Refresh\''**
  String get hc_tooltip_rafraichir_a22b17e3;

  /// No description provided for @hc_tooltip_menu_d8fa6679.
  ///
  /// In en, this message translates to:
  /// **'tooltip: \'Menu\''**
  String get hc_tooltip_menu_d8fa6679;

  /// No description provided for @hc_retour_e5befb1f.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get hc_retour_e5befb1f;

  /// No description provided for @hc_semanticlabel_plus_d_actions_1bd19eb6.
  ///
  /// In en, this message translates to:
  /// **'semanticLabel: \'More actions\''**
  String get hc_semanticlabel_plus_d_actions_1bd19eb6;

  /// No description provided for @hc_plus_d_actions_ffe6be2a.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get hc_plus_d_actions_ffe6be2a;

  /// No description provided for @hc_semanticlabel_rechercher_3ae4e02c.
  ///
  /// In en, this message translates to:
  /// **'semanticLabel: \'Search\''**
  String get hc_semanticlabel_rechercher_3ae4e02c;

  /// No description provided for @hc_semanticlabel_ajouter_ac362a68.
  ///
  /// In en, this message translates to:
  /// **'semanticLabel: \'Add\''**
  String get hc_semanticlabel_ajouter_ac362a68;

  /// No description provided for @hc_l10n_86d50bf0.
  ///
  /// In en, this message translates to:
  /// **'l10n.*'**
  String get hc_l10n_86d50bf0;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @dialogSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get dialogSignOutBody;

  /// No description provided for @settingsUnableToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the link'**
  String get settingsUnableToOpenLink;

  /// No description provided for @settingsSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsSyncDisabled;

  /// No description provided for @settingsSyncEveryHour.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get settingsSyncEveryHour;

  /// No description provided for @settingsSyncEvery2Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get settingsSyncEvery2Hours;

  /// No description provided for @settingsSyncEvery4Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 4 hours'**
  String get settingsSyncEvery4Hours;

  /// No description provided for @settingsSyncEvery6Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get settingsSyncEvery6Hours;

  /// No description provided for @settingsSyncEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get settingsSyncEveryDay;

  /// No description provided for @settingsSyncEvery2Days.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get settingsSyncEvery2Days;

  /// No description provided for @settingsColorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsColorCustom;

  /// No description provided for @settingsColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsColorBlue;

  /// No description provided for @settingsColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get settingsColorPink;

  /// No description provided for @settingsColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get settingsColorGreen;

  /// No description provided for @settingsColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get settingsColorPurple;

  /// No description provided for @settingsColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get settingsColorOrange;

  /// No description provided for @settingsColorTurquoise.
  ///
  /// In en, this message translates to:
  /// **'Turquoise'**
  String get settingsColorTurquoise;

  /// No description provided for @settingsColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get settingsColorYellow;

  /// No description provided for @settingsColorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get settingsColorIndigo;

  /// No description provided for @settingsCloudAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud account'**
  String get settingsCloudAccountTitle;

  /// No description provided for @settingsAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsAccountConnected;

  /// No description provided for @settingsAccountLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Local mode'**
  String get settingsAccountLocalMode;

  /// No description provided for @settingsAccountCloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud unavailable'**
  String get settingsAccountCloudUnavailable;

  /// No description provided for @aboutTmdbDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get aboutTmdbDisclaimer;

  /// No description provided for @aboutCreditsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get aboutCreditsSectionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
