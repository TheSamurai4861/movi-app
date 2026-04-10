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
  String get homeWatchNow => 'Watch';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
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
  String get settingsHelpDiagnosticsSection => 'Help & diagnostics';

  @override
  String get settingsExportErrorLogs => 'Export error logs';

  @override
  String get diagnosticsExportTitle => 'Export error logs';

  @override
  String get diagnosticsExportDescription =>
      'The diagnostic only includes recent WARN/ERROR logs and hashed account/profile identifiers (if enabled). No key/token should appear.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Include account/profile identifiers (hashed)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Helps correlate a bug without exposing the raw ID.';

  @override
  String get diagnosticsCopiedClipboard => 'Diagnostic copied to clipboard.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnostic saved: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Copy';

  @override
  String get diagnosticsActionSave => 'Save';

  @override
  String get actionChangeVersion => 'Change version';

  @override
  String get semanticsBack => 'Back';

  @override
  String get semanticsMoreActions => 'More actions';

  @override
  String get snackbarLoadingPlaylists => 'Loading playlists…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'No playlists yet. Create one.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Error adding to playlist: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'This media is already in this playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Error loading playlists: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Reporting is unavailable for this content.';

  @override
  String get snackbarLoadingEpisodes => 'Episodes are loading…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Episode unavailable in playlist';

  @override
  String snackbarGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get snackbarLoading => 'Loading…';

  @override
  String get snackbarNoVersionAvailable => 'No version available';

  @override
  String get snackbarVersionSaved => 'Version saved';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Version $index';
  }

  @override
  String get actionReadMore => 'Read more';

  @override
  String get actionShowLess => 'Show less';

  @override
  String get actionViewPage => 'View page';

  @override
  String get semanticsSeeSagaPage => 'See saga page';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'In progress';

  @override
  String get libraryTypeFavoriteMovies => 'Favorite movies';

  @override
  String get libraryTypeFavoriteSeries => 'Favorite shows';

  @override
  String get libraryTypeHistory => 'History';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Artist';

  @override
  String libraryItemCount(int count) {
    return '$count item';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist renamed to \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist deleted';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'This media is already in the playlist';

  @override
  String get snackbarAddedToPlaylist => 'Added to the playlist';

  @override
  String get addMediaTitle => 'Add media';

  @override
  String get searchMinCharsHint => 'Type at least 3 characters to search';

  @override
  String get badgeAdded => 'Added';

  @override
  String get snackbarNotAvailableOnSource => 'Not available on this source';

  @override
  String get errorLoadingTitle => 'Loading error';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Loading error: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Error loading playlists: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Clear filter';

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
  String get actionRefreshMetadata => 'Refresh metadata';

  @override
  String get actionChangeMetadata => 'Change metadata';

  @override
  String get actionAddToList => 'Add to a list';

  @override
  String get metadataRefreshed => 'Metadata refreshed';

  @override
  String get errorRefreshingMetadata => 'Error refreshing metadata';

  @override
  String get actionMarkSeen => 'Mark as seen';

  @override
  String get actionMarkUnseen => 'Mark as unseen';

  @override
  String get actionReportProblem => 'Report a problem';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get subtitlesMenuTitle => 'Subtitles';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Display mode';

  @override
  String get videoFitModeContain => 'Original proportions';

  @override
  String get videoFitModeCover => 'Fill screen';

  @override
  String get actionDisable => 'Disable';

  @override
  String defaultTrackLabel(String id) {
    return 'Track $id';
  }

  @override
  String get controlRewind10 => '10 s';

  @override
  String get controlRewind30 => '30 s';

  @override
  String get controlForward10 => '+ 10 s';

  @override
  String get controlForward30 => '+ 30 s';

  @override
  String get actionNextEpisode => 'Next episode';

  @override
  String get actionRestart => 'Restart';

  @override
  String get errorSeriesDataUnavailable => 'Unable to load series data';

  @override
  String get errorNextEpisodeFailed => 'Unable to determine next episode';

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
  String get activeSourceTitle => 'Active source';

  @override
  String get statusActive => 'Active';

  @override
  String get statusNoActiveSource => 'No active source';

  @override
  String get overlayPreparingHome => 'Preparing home…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Loading movies & shows…';

  @override
  String get overlayLoadingCategories => 'Loading categories…';

  @override
  String get bootstrapRefreshing => 'Refreshing IPTV lists…';

  @override
  String get bootstrapEnriching => 'Preparing metadata…';

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
  String get actionSeeAll => 'See All';

  @override
  String get actionExpand => 'Expand';

  @override
  String get actionCollapse => 'Collapse';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Search $provider';
  }

  @override
  String get actionClearHistory => 'Clear history';

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
  String get libraryEmpty =>
      'Like movies, series or actors to see them appear here.';

  @override
  String get serie => 'Series';

  @override
  String get recherche => 'Search';

  @override
  String get notYetAvailable => 'Not yet available';

  @override
  String get createPlaylistTitle => 'Create playlist';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get addMedia => 'Add media';

  @override
  String get renamePlaylist => 'Rename';

  @override
  String get deletePlaylist => 'Delete';

  @override
  String get pinPlaylist => 'Pin';

  @override
  String get unpinPlaylist => 'Unpin';

  @override
  String get playlistPinned => 'Playlist pinned';

  @override
  String get playlistUnpinned => 'Playlist unpinned';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" created';
  }

  @override
  String playlistCreateError(String error) {
    return 'Error creating playlist: $error';
  }

  @override
  String get addedToPlaylist => 'Added to playlist';

  @override
  String get pinRecoveryLink => 'Recover PIN';

  @override
  String get pinRecoveryTitle => 'Recover PIN';

  @override
  String get pinRecoveryDescription =>
      'We will send an 8-digit code to your account email address so you can reset this profile PIN.';

  @override
  String get pinRecoveryRequestCodeButton => 'Send code';

  @override
  String get pinRecoveryCodeSentHint =>
      'Code sent to your account email. Check your messages and enter it below.';

  @override
  String get pinRecoveryComingSoon => 'This feature is coming soon.';

  @override
  String get pinRecoveryNotAvailable =>
      'PIN recovery by email is currently unavailable.';

  @override
  String get pinRecoveryCodeLabel => 'Recovery code';

  @override
  String get pinRecoveryCodeHint => '8 digits';

  @override
  String get pinRecoveryVerifyButton => 'Verify';

  @override
  String get pinRecoveryCodeInvalid => 'Enter the 8-digit recovery code';

  @override
  String get pinRecoveryCodeExpired => 'Recovery code expired';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Too many attempts. Try again later.';

  @override
  String get pinRecoveryUnknownError => 'An unexpected error occurred';

  @override
  String get pinRecoveryNewPinLabel => 'New PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 digits';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirm PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Repeat the PIN';

  @override
  String get pinRecoveryResetButton => 'Reset PIN';

  @override
  String get pinRecoveryPinInvalid => 'Enter a 4 to 6 digit PIN';

  @override
  String get pinRecoveryPinMismatch => 'PINs do not match';

  @override
  String get pinRecoveryResetSuccess => 'PIN updated';

  @override
  String get profilePinSaved => 'PIN saved.';

  @override
  String get profilePinEditLabel => 'Edit PIN code';

  @override
  String get settingsAccountsSection => 'Accounts';

  @override
  String get settingsIptvSection => 'IPTV Settings';

  @override
  String get settingsSourcesManagement => 'Source Management';

  @override
  String get settingsSyncFrequency => 'Update Frequency';

  @override
  String get settingsAppSection => 'App Settings';

  @override
  String get settingsAccentColor => 'Accent Color';

  @override
  String get settingsPlaybackSection => 'Playback Settings';

  @override
  String get settingsPreferredAudioLanguage => 'Preferred audio language';

  @override
  String get settingsPreferredSubtitleLanguage => 'Preferred subtitle language';

  @override
  String get libraryPlaylistsFilter => 'Playlists';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artists';

  @override
  String get librarySearchPlaceholder => 'Search in my library...';

  @override
  String get libraryInProgress => 'Continue Watching';

  @override
  String get libraryFavoriteMovies => 'Favorite Movies';

  @override
  String get libraryFavoriteSeries => 'Favorite Series';

  @override
  String get libraryWatchHistory => 'Watch History';

  @override
  String libraryItemCountPlural(int count) {
    return '$count items';
  }

  @override
  String get searchPeopleTitle => 'People';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'By Providers';

  @override
  String get searchByGenresTitle => 'By Genres';

  @override
  String get personRoleActor => 'Actor';

  @override
  String get personRoleDirector => 'Director';

  @override
  String get personRoleCreator => 'Creator';

  @override
  String get tvDistribution => 'Cast';

  @override
  String tvSeasonLabel(int number) {
    return 'Season $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'No episodes available';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Resume S$season · E$episode';
  }

  @override
  String get sagaViewPage => 'View Page';

  @override
  String get sagaStartNow => 'Start Now';

  @override
  String get sagaContinue => 'Continue';

  @override
  String sagaMovieCount(int count) {
    return '$count films';
  }

  @override
  String get sagaMoviesList => 'Movies List';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies films - $shows series';
  }

  @override
  String get personPlayRandomly => 'Play Randomly';

  @override
  String get personMoviesList => 'Movies List';

  @override
  String get personSeriesList => 'Series List';

  @override
  String get playlistPlayRandomly => 'Play randomly';

  @override
  String get playlistAddButton => 'Add to playlist';

  @override
  String get playlistSortButton => 'Sort';

  @override
  String get playlistSortByTitle => 'Sort by';

  @override
  String get playlistSortByTitleOption => 'Title';

  @override
  String get playlistSortRecentAdditions => 'Recent Additions';

  @override
  String get playlistSortOldestFirst => 'Oldest First';

  @override
  String get playlistSortNewestFirst => 'Newest First';

  @override
  String get playlistEmptyMessage => 'No items in this playlist';

  @override
  String playlistItemCount(int count) {
    return '$count item';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count items';
  }

  @override
  String get playlistSeasonSingular => 'season';

  @override
  String get playlistSeasonPlural => 'seasons';

  @override
  String get playlistRenameTitle => 'Rename playlist';

  @override
  String get playlistNamePlaceholder => 'Playlist name';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Playlist renamed to \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Delete playlist';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get playlistDeletedSuccess => 'Playlist deleted';

  @override
  String get playlistItemRemovedSuccess => 'Item removed';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Remove \"$title\" from playlist?';
  }

  @override
  String get categoryLoadFailed => 'Failed to load category.';

  @override
  String get categoryEmpty => 'No items in this category.';

  @override
  String get categoryLoadingMore => 'Loading more…';

  @override
  String get movieNoPlaylistsAvailable => 'No playlists available';

  @override
  String playlistAddedTo(String title) {
    return 'Added to \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Movie not available in the playlist';

  @override
  String errorPlaybackFailed(String message) {
    return 'Error playing movie: $message';
  }

  @override
  String get movieNoMedia => 'No media to display';

  @override
  String get personNoData => 'No person to display.';

  @override
  String get personGenericError =>
      'An error occurred while loading this person.';

  @override
  String get personBiographyTitle => 'Biography';

  @override
  String get authOtpTitle => 'Sign in';

  @override
  String get authOtpSubtitle =>
      'Enter your email and the 8-digit code we send you.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'name@example.com';

  @override
  String get authOtpEmailHelp =>
      'We will send you an 8-digit code. Check your spam folder if needed.';

  @override
  String get authOtpCodeLabel => 'Verification code';

  @override
  String get authOtpCodeHint => '8-digit code';

  @override
  String get authOtpCodeHelp => 'Enter the 8-digit code received by email.';

  @override
  String get authOtpPrimarySend => 'Send code';

  @override
  String get authOtpPrimarySubmit => 'Sign in';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Change email';

  @override
  String get resumePlayback => 'Resume playback';

  @override
  String get settingsCloudSyncSection => 'Cloud sync';

  @override
  String get settingsCloudSyncAuto => 'Auto sync';

  @override
  String get settingsCloudSyncNow => 'Sync now';

  @override
  String get settingsCloudSyncInProgress => 'Syncing…';

  @override
  String get settingsCloudSyncNever => 'Never';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Last error: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity not found';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity not found: $error';
  }

  @override
  String get entityProvider => 'Provider';

  @override
  String get entityGenre => 'Genre';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Source';

  @override
  String get entityMovie => 'Movie';

  @override
  String get entitySeries => 'Show';

  @override
  String get entityPerson => 'Person';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Video';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Loading timed out';

  @override
  String get parentalContentRestricted => 'Restricted Content';

  @override
  String get parentalContentRestrictedDefault =>
      'This content is blocked by this profile\'s parental controls.';

  @override
  String get parentalReasonTooYoung =>
      'This content requires an age higher than this profile\'s limit.';

  @override
  String get parentalReasonUnknownRating =>
      'The age rating for this content is not available.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'This content cannot be evaluated for parental control.';

  @override
  String get parentalUnlockButton => 'Unlock';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get dialogSignOutBody => 'Are you sure you want to sign out?';

  @override
  String get settingsUnableToOpenLink => 'Unable to open the link';

  @override
  String get settingsSyncDisabled => 'Disabled';

  @override
  String get settingsSyncEveryHour => 'Every hour';

  @override
  String get settingsSyncEvery2Hours => 'Every 2 hours';

  @override
  String get settingsSyncEvery4Hours => 'Every 4 hours';

  @override
  String get settingsSyncEvery6Hours => 'Every 6 hours';

  @override
  String get settingsSyncEveryDay => 'Every day';

  @override
  String get settingsSyncEvery2Days => 'Every 2 days';

  @override
  String get settingsColorCustom => 'Custom';

  @override
  String get settingsColorBlue => 'Blue';

  @override
  String get settingsColorPink => 'Pink';

  @override
  String get settingsColorGreen => 'Green';

  @override
  String get settingsColorPurple => 'Purple';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorTurquoise => 'Turquoise';

  @override
  String get settingsColorYellow => 'Yellow';

  @override
  String get settingsColorIndigo => 'Indigo';

  @override
  String get settingsCloudAccountTitle => 'Cloud account';

  @override
  String get settingsAccountConnected => 'Connected';

  @override
  String get settingsAccountLocalMode => 'Local mode';

  @override
  String get settingsAccountCloudUnavailable => 'Cloud unavailable';

  @override
  String get settingsSubtitlesTitle => 'Subtitles';

  @override
  String get settingsSubtitlesSizeTitle => 'Text size';

  @override
  String get settingsSubtitlesColorTitle => 'Text color';

  @override
  String get settingsSubtitlesFontTitle => 'Font';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'System';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Quick settings';

  @override
  String get settingsSubtitlesPreviewTitle => 'Preview';

  @override
  String get settingsSubtitlesPreviewSample =>
      'This is a subtitles preview.\nFine tune readability in real time.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Background';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Background opacity';

  @override
  String get settingsSubtitlesShadowTitle => 'Shadow';

  @override
  String get settingsSubtitlesShadowOff => 'Off';

  @override
  String get settingsSubtitlesShadowSoft => 'Soft';

  @override
  String get settingsSubtitlesShadowStrong => 'Strong';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Fine size';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Scale';

  @override
  String get settingsSubtitlesResetDefaults => 'Reset to defaults';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Advanced subtitle style (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Background, opacity, shadow presets and fine size are available with Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Unlock with Premium';

  @override
  String get settingsSyncSectionTitle => 'Audio/Subtitles sync';

  @override
  String get settingsSubtitleOffsetTitle => 'Subtitle offset';

  @override
  String get settingsAudioOffsetTitle => 'Audio offset';

  @override
  String get settingsOffsetUnsupported =>
      'Not supported on this backend or platform.';

  @override
  String get settingsSyncResetOffsets => 'Reset sync offsets';

  @override
  String get aboutTmdbDisclaimer =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Credits';

  @override
  String get actionSend => 'Send';

  @override
  String get profilePinSetLabel => 'Set PIN code';

  @override
  String get reportingProblemSentConfirmation => 'Report sent. Thank you.';

  @override
  String get reportingProblemBody =>
      'If this content is inappropriate and was accessible despite restrictions, briefly describe the issue.';

  @override
  String get reportingProblemExampleHint =>
      'Example: Horror movie visible despite PEGI 12';

  @override
  String get settingsAutomaticOption => 'Auto';

  @override
  String get settingsPreferredPlaybackQuality => 'Preferred playback quality';

  @override
  String settingsSignOutError(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Terms of use';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium is required for cloud sync.';
}
