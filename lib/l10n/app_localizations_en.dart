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
  String get actionSeeAll => 'See All';

  @override
  String get actionExpand => 'Expand';

  @override
  String get actionCollapse => 'Collapse';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Search on $provider...';
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
  String get addedToPlaylist => 'Added';

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
  String get settingsPreferredAudioLanguage => 'Preferred Language';

  @override
  String get settingsPreferredSubtitleLanguage => 'Preferred Subtitles';

  @override
  String get libraryPlaylistsFilter => 'Playlists';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artists';

  @override
  String get librarySearchPlaceholder => 'Search in my library...';

  @override
  String get libraryInProgress => 'In Progress';

  @override
  String get libraryFavoriteMovies => 'Favorite Movies';

  @override
  String get libraryFavoriteSeries => 'Favorite Series';

  @override
  String get libraryWatchHistory => 'Watch History';

  @override
  String libraryItemCount(int count) {
    return '$count item';
  }

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
    return 'Resume S$season E$episode';
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
  String get playlistPlayRandomly => 'Play Randomly';

  @override
  String get playlistAddButton => 'Add';

  @override
  String get playlistSortButton => 'Sort';

  @override
  String get playlistSortByTitle => 'Sort By';

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
  String get playlistRenameTitle => 'Rename Playlist';

  @override
  String get playlistNamePlaceholder => 'Playlist Name';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Playlist renamed to \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Delete';

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
}
