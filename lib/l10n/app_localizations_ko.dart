// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get welcomeTitle => '환영합니다!';

  @override
  String get welcomeSubtitle => '선호 설정을 입력해 Movi를 개인화하세요.';

  @override
  String get labelUsername => '닉네임';

  @override
  String get labelPreferredLanguage => '선호 언어';

  @override
  String get actionContinue => '계속';

  @override
  String get hintUsername => '닉네임';

  @override
  String get errorFillFields => '필드를 올바르게 입력해 주세요.';

  @override
  String get homeWatchNow => '시청';

  @override
  String get welcomeSourceTitle => '환영합니다!';

  @override
  String get welcomeSourceSubtitle => '소스를 추가해 Movi에서의 경험을 개인화하세요.';

  @override
  String get welcomeSourceAdd => '소스 추가';

  @override
  String get searchTitle => '검색';

  @override
  String get searchHint => '검색어를 입력하세요';

  @override
  String get clear => '지우기';

  @override
  String get moviesTitle => '영화';

  @override
  String get seriesTitle => '쇼';

  @override
  String get noResults => '결과 없음';

  @override
  String get historyTitle => '기록';

  @override
  String get historyEmpty => '최근 검색이 없습니다';

  @override
  String get delete => '삭제';

  @override
  String resultsCount(int count) {
    return '($count개 결과)';
  }

  @override
  String get errorUnknown => '알 수 없는 오류';

  @override
  String errorConnectionFailed(String error) {
    return '연결 실패: $error';
  }

  @override
  String get errorConnectionGeneric => '연결 실패';

  @override
  String get validationRequired => '필수';

  @override
  String get validationInvalidUrl => '잘못된 URL';

  @override
  String get snackbarSourceAddedBackground => 'IPTV 소스를 추가했습니다. 백그라운드에서 동기화 중…';

  @override
  String get snackbarSourceAddedSynced => 'IPTV 소스를 추가하고 동기화했습니다';

  @override
  String get navHome => '홈';

  @override
  String get navSearch => '검색';

  @override
  String get navLibrary => '라이브러리';

  @override
  String get navSettings => '설정';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguageLabel => '앱 언어';

  @override
  String get settingsGeneralTitle => '일반 설정';

  @override
  String get settingsDarkModeTitle => '다크 모드';

  @override
  String get settingsDarkModeSubtitle => '눈에 편한 야간 테마를 사용합니다.';

  @override
  String get settingsNotificationsTitle => '알림';

  @override
  String get settingsNotificationsSubtitle => '새로운 출시 소식을 받아보세요.';

  @override
  String get settingsAccountTitle => '계정';

  @override
  String get settingsProfileInfoTitle => '프로필 정보';

  @override
  String get settingsProfileInfoSubtitle => '이름, 아바타, 설정';

  @override
  String get settingsAboutTitle => '정보';

  @override
  String get settingsLegalMentionsTitle => '법적 고지';

  @override
  String get settingsPrivacyPolicyTitle => '개인정보처리방침';

  @override
  String get actionCancel => '취소';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get settingsHelpDiagnosticsSection => '도움말 및 진단';

  @override
  String get settingsExportErrorLogs => '오류 로그 내보내기';

  @override
  String get diagnosticsExportTitle => '오류 로그 내보내기';

  @override
  String get diagnosticsExportDescription =>
      '진단에는 최근 WARN/ERROR 로그와(활성화 시) 해시 처리된 계정/프로필 식별자만 포함됩니다. 키/토큰은 포함되지 않아야 합니다.';

  @override
  String get diagnosticsIncludeHashedIdsTitle => '계정/프로필 식별자(해시) 포함';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      '원본 ID를 노출하지 않고 버그를 연관시키는 데 도움이 됩니다.';

  @override
  String get diagnosticsCopiedClipboard => '진단 정보를 클립보드에 복사했습니다.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return '진단 저장됨: $fileName';
  }

  @override
  String get diagnosticsActionCopy => '복사';

  @override
  String get diagnosticsActionSave => '저장';

  @override
  String get actionChangeVersion => '버전 변경';

  @override
  String get semanticsBack => '뒤로';

  @override
  String get semanticsMoreActions => '추가 작업';

  @override
  String get snackbarLoadingPlaylists => '재생목록 불러오는 중…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      '사용 가능한 재생목록이 없습니다. 새로 만들어 주세요.';

  @override
  String errorAddToPlaylist(String error) {
    return '재생목록에 추가하는 중 오류: $error';
  }

  @override
  String get errorAlreadyInPlaylist => '이 미디어는 이미 해당 재생목록에 있습니다';

  @override
  String errorLoadingPlaylists(String message) {
    return '재생목록 불러오기 오류: $message';
  }

  @override
  String get errorReportUnavailableForContent => '이 콘텐츠에서는 신고 기능을 사용할 수 없습니다.';

  @override
  String get snackbarLoadingEpisodes => '에피소드 불러오는 중…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      '재생목록에서 이 에피소드를 사용할 수 없습니다';

  @override
  String snackbarGenericError(String error) {
    return '오류: $error';
  }

  @override
  String get snackbarLoading => '불러오는 중…';

  @override
  String get snackbarNoVersionAvailable => '사용 가능한 버전이 없습니다';

  @override
  String get snackbarVersionSaved => '버전을 저장했습니다';

  @override
  String playbackVariantFallbackLabel(int index) {
    return '버전 $index';
  }

  @override
  String get actionReadMore => '더 보기';

  @override
  String get actionShowLess => '접기';

  @override
  String get actionViewPage => '페이지 보기';

  @override
  String get semanticsSeeSagaPage => '사가 페이지 보기';

  @override
  String get libraryTypeSaga => '사가';

  @override
  String get libraryTypeInProgress => '시청 중';

  @override
  String get libraryTypeFavoriteMovies => '즐겨찾는 영화';

  @override
  String get libraryTypeFavoriteSeries => '즐겨찾는 쇼';

  @override
  String get libraryTypeHistory => '기록';

  @override
  String get libraryTypePlaylist => '재생목록';

  @override
  String get libraryTypeArtist => '아티스트';

  @override
  String libraryItemCount(int count) {
    return '$count개 항목';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return '재생목록 이름을 \"$name\"(으)로 변경했습니다';
  }

  @override
  String get snackbarPlaylistDeleted => '재생목록을 삭제했습니다';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '\"$title\"을(를) 삭제하시겠어요?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return '\"$query\"에 대한 결과가 없습니다';
  }

  @override
  String errorGenericWithMessage(String error) {
    return '오류: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist => '이 미디어는 이미 재생목록에 있습니다';

  @override
  String get snackbarAddedToPlaylist => '재생목록에 추가했습니다';

  @override
  String get addMediaTitle => '미디어 추가';

  @override
  String get searchMinCharsHint => '검색하려면 최소 3자 이상 입력하세요';

  @override
  String get badgeAdded => '추가됨';

  @override
  String get snackbarNotAvailableOnSource => '이 소스에서는 사용할 수 없습니다';

  @override
  String get errorLoadingTitle => '불러오기 오류';

  @override
  String errorLoadingWithMessage(String error) {
    return '불러오기 오류: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return '재생목록 불러오기 오류: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => '필터 지우기';

  @override
  String get homeErrorSwipeToRetry => '오류가 발생했습니다. 아래로 스와이프하여 다시 시도하세요.';

  @override
  String get homeContinueWatching => '계속 시청';

  @override
  String get homeNoIptvSources =>
      '활성 IPTV 소스가 없습니다. 설정에서 소스를 추가하면 카테고리를 볼 수 있습니다.';

  @override
  String get homeNoTrends => '사용 가능한 트렌드 콘텐츠가 없습니다';

  @override
  String get actionRefreshMetadata => '메타데이터 새로고침';

  @override
  String get actionChangeMetadata => '메타데이터 변경';

  @override
  String get actionAddToList => '목록에 추가';

  @override
  String get metadataRefreshed => '메타데이터를 새로고침했습니다';

  @override
  String get errorRefreshingMetadata => '메타데이터 새로고침 오류';

  @override
  String get actionMarkSeen => '시청함으로 표시';

  @override
  String get actionMarkUnseen => '미시청으로 표시';

  @override
  String get actionReportProblem => '문제 신고';

  @override
  String get featureComingSoon => '곧 제공 예정';

  @override
  String get subtitlesMenuTitle => '자막';

  @override
  String get audioMenuTitle => '오디오';

  @override
  String get videoFitModeMenuTitle => '표시 모드';

  @override
  String get videoFitModeContain => '원본 비율';

  @override
  String get videoFitModeCover => '화면 채우기';

  @override
  String get actionDisable => '사용 안 함';

  @override
  String defaultTrackLabel(String id) {
    return '트랙 $id';
  }

  @override
  String get controlRewind10 => '10초';

  @override
  String get controlRewind30 => '30초';

  @override
  String get controlForward10 => '+10초';

  @override
  String get controlForward30 => '+30초';

  @override
  String get actionNextEpisode => '다음 에피소드';

  @override
  String get actionRestart => '처음부터';

  @override
  String get errorSeriesDataUnavailable => '쇼 데이터를 불러올 수 없습니다';

  @override
  String get errorNextEpisodeFailed => '다음 에피소드를 확인할 수 없습니다';

  @override
  String get actionLoadMore => '더 불러오기';

  @override
  String get iptvServerUrlLabel => '서버 URL';

  @override
  String get iptvServerUrlHint => 'Xtream 서버 URL';

  @override
  String get iptvPasswordLabel => '비밀번호';

  @override
  String get iptvPasswordHint => 'Xtream 비밀번호';

  @override
  String get actionConnect => '연결';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'IPTV 재생목록 새로고침';

  @override
  String get activeSourceTitle => '활성 소스';

  @override
  String get statusActive => '활성';

  @override
  String get statusNoActiveSource => '활성 소스 없음';

  @override
  String get overlayPreparingHome => '홈 준비 중…';

  @override
  String get overlayLoadingMoviesAndSeries => '영화 및 시리즈 로딩 중…';

  @override
  String get overlayLoadingCategories => '카테고리 로딩 중…';

  @override
  String get bootstrapRefreshing => 'IPTV 목록 새로고침 중…';

  @override
  String get bootstrapEnriching => '메타데이터 준비 중…';

  @override
  String get errorPrepareHome => '홈을 준비할 수 없습니다';

  @override
  String get overlayOpeningHome => '홈 여는 중…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV 목록 새로고침 중…';

  @override
  String get overlayPreparingMetadata => '메타데이터 준비 중…';

  @override
  String get errorHomeLoadTimeout => '홈 로드 시간 초과';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => '사용자 이름';

  @override
  String get iptvUsernameHint => 'Xtream 사용자 이름';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionSeeAll => '모두 보기';

  @override
  String get actionExpand => '펼치기';

  @override
  String get actionCollapse => '접기';

  @override
  String providerSearchPlaceholder(String provider) {
    return '$provider에서 검색…';
  }

  @override
  String get actionClearHistory => '기록 지우기';

  @override
  String get castTitle => '출연진';

  @override
  String get recommendationsTitle => '추천';

  @override
  String get libraryHeader => '내 라이브러리';

  @override
  String get libraryDataInfo => 'data/domain이 구현되면 데이터가 표시됩니다.';

  @override
  String get libraryEmpty => '영화, 쇼 또는 배우를 좋아요 하면 여기에 표시됩니다.';

  @override
  String get serie => '쇼';

  @override
  String get recherche => '검색';

  @override
  String get notYetAvailable => '아직 사용할 수 없습니다';

  @override
  String get createPlaylistTitle => '재생목록 만들기';

  @override
  String get playlistName => '재생목록 이름';

  @override
  String get addMedia => '미디어 추가';

  @override
  String get renamePlaylist => '이름 변경';

  @override
  String get deletePlaylist => '삭제';

  @override
  String get pinPlaylist => '고정';

  @override
  String get unpinPlaylist => '고정 해제';

  @override
  String get playlistPinned => '재생목록을 고정했습니다';

  @override
  String get playlistUnpinned => '재생목록 고정을 해제했습니다';

  @override
  String get playlistDeleted => '재생목록을 삭제했습니다';

  @override
  String playlistCreatedSuccess(String name) {
    return '재생목록 \"$name\"을(를) 만들었습니다';
  }

  @override
  String playlistCreateError(String error) {
    return '재생목록 생성 오류: $error';
  }

  @override
  String get addedToPlaylist => '추가됨';

  @override
  String get pinRecoveryLink => 'PIN 코드 복구';

  @override
  String get pinRecoveryTitle => 'PIN 코드 복구';

  @override
  String get pinRecoveryDescription => '보호된 프로필의 PIN 코드를 복구합니다.';

  @override
  String get pinRecoveryComingSoon => '이 기능은 곧 제공됩니다.';

  @override
  String get pinRecoveryCodeLabel => '복구 코드';

  @override
  String get pinRecoveryCodeHint => '8자리';

  @override
  String get pinRecoveryVerifyButton => '확인';

  @override
  String get pinRecoveryCodeInvalid => '8자리 코드를 입력하세요';

  @override
  String get pinRecoveryCodeExpired => '복구 코드가 만료되었습니다';

  @override
  String get pinRecoveryTooManyAttempts => '시도 횟수가 너무 많습니다. 나중에 다시 시도하세요.';

  @override
  String get pinRecoveryUnknownError => '예기치 않은 오류가 발생했습니다';

  @override
  String get pinRecoveryNewPinLabel => '새 PIN';

  @override
  String get pinRecoveryNewPinHint => '4~6자리';

  @override
  String get pinRecoveryConfirmPinLabel => 'PIN 확인';

  @override
  String get pinRecoveryConfirmPinHint => 'PIN을 다시 입력';

  @override
  String get pinRecoveryResetButton => 'PIN 업데이트';

  @override
  String get pinRecoveryPinInvalid => '4~6자리 PIN을 입력하세요';

  @override
  String get pinRecoveryPinMismatch => 'PIN이 일치하지 않습니다';

  @override
  String get pinRecoveryResetSuccess => 'PIN을 업데이트했습니다';

  @override
  String get settingsAccountsSection => '계정';

  @override
  String get settingsIptvSection => 'IPTV 설정';

  @override
  String get settingsSourcesManagement => '소스 관리';

  @override
  String get settingsSyncFrequency => '업데이트 빈도';

  @override
  String get settingsAppSection => '앱 설정';

  @override
  String get settingsAccentColor => '강조 색상';

  @override
  String get settingsPlaybackSection => '재생 설정';

  @override
  String get settingsPreferredAudioLanguage => '선호 언어';

  @override
  String get settingsPreferredSubtitleLanguage => '선호 자막';

  @override
  String get libraryPlaylistsFilter => '재생목록';

  @override
  String get librarySagasFilter => '사가';

  @override
  String get libraryArtistsFilter => '아티스트';

  @override
  String get librarySearchPlaceholder => '내 라이브러리에서 검색…';

  @override
  String get libraryInProgress => '시청 중';

  @override
  String get libraryFavoriteMovies => '즐겨찾는 영화';

  @override
  String get libraryFavoriteSeries => '즐겨찾는 쇼';

  @override
  String get libraryWatchHistory => '시청 기록';

  @override
  String libraryItemCountPlural(int count) {
    return '$count개 항목';
  }

  @override
  String get searchPeopleTitle => '인물';

  @override
  String get searchSagasTitle => '사가';

  @override
  String get searchByProvidersTitle => '제공처별';

  @override
  String get searchByGenresTitle => '장르별';

  @override
  String get personRoleActor => '배우';

  @override
  String get personRoleDirector => '감독';

  @override
  String get personRoleCreator => '크리에이터';

  @override
  String get tvDistribution => '출연진';

  @override
  String tvSeasonLabel(int number) {
    return '시즌 $number';
  }

  @override
  String get tvNoEpisodesAvailable => '사용 가능한 에피소드가 없습니다';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return '계속 보기 S$season E$episode';
  }

  @override
  String get sagaViewPage => '페이지 보기';

  @override
  String get sagaStartNow => '지금 시작';

  @override
  String get sagaContinue => '계속';

  @override
  String sagaMovieCount(int count) {
    return '$count편';
  }

  @override
  String get sagaMoviesList => '영화 목록';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies편 - $shows편';
  }

  @override
  String get personPlayRandomly => '무작위 재생';

  @override
  String get personMoviesList => '영화 목록';

  @override
  String get personSeriesList => '쇼 목록';

  @override
  String get playlistPlayRandomly => '무작위 재생';

  @override
  String get playlistAddButton => '추가';

  @override
  String get playlistSortButton => '정렬';

  @override
  String get playlistSortByTitle => '정렬 기준';

  @override
  String get playlistSortByTitleOption => '제목';

  @override
  String get playlistSortRecentAdditions => '최근 추가';

  @override
  String get playlistSortOldestFirst => '오래된 순';

  @override
  String get playlistSortNewestFirst => '최신 순';

  @override
  String get playlistEmptyMessage => '이 재생목록에 항목이 없습니다';

  @override
  String playlistItemCount(int count) {
    return '$count개';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count개';
  }

  @override
  String get playlistSeasonSingular => '시즌';

  @override
  String get playlistSeasonPlural => '시즌';

  @override
  String get playlistRenameTitle => '재생목록 이름 변경';

  @override
  String get playlistNamePlaceholder => '재생목록 이름';

  @override
  String playlistRenamedSuccess(String name) {
    return '재생목록 이름을 \"$name\"(으)로 변경했습니다';
  }

  @override
  String get playlistDeleteTitle => '삭제';

  @override
  String playlistDeleteConfirm(String title) {
    return '\"$title\"을(를) 삭제하시겠어요?';
  }

  @override
  String get playlistDeletedSuccess => '재생목록을 삭제했습니다';

  @override
  String get playlistItemRemovedSuccess => '항목을 제거했습니다';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '재생목록에서 \"$title\"을(를) 제거할까요?';
  }

  @override
  String get categoryLoadFailed => '카테고리를 불러오지 못했습니다.';

  @override
  String get categoryEmpty => '이 카테고리에 항목이 없습니다.';

  @override
  String get categoryLoadingMore => '더 불러오는 중…';

  @override
  String get movieNoPlaylistsAvailable => '사용 가능한 재생목록이 없습니다';

  @override
  String playlistAddedTo(String title) {
    return '\"$title\"에 추가했습니다';
  }

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => '재생목록에서 영화를 사용할 수 없습니다';

  @override
  String errorPlaybackFailed(String message) {
    return '재생 오류: $message';
  }

  @override
  String get movieNoMedia => '표시할 미디어가 없습니다';

  @override
  String get personNoData => '표시할 인물이 없습니다.';

  @override
  String get personGenericError => '이 인물을 불러오는 중 오류가 발생했습니다.';

  @override
  String get personBiographyTitle => '약력';

  @override
  String get authOtpTitle => '로그인';

  @override
  String get authOtpSubtitle => '이메일과 전송된 8자리 코드를 입력하세요.';

  @override
  String get authOtpEmailLabel => '이메일';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp => '8자리 코드를 전송합니다. 필요하면 스팸함을 확인하세요.';

  @override
  String get authOtpCodeLabel => '인증 코드';

  @override
  String get authOtpCodeHint => '8자리 코드';

  @override
  String get authOtpCodeHelp => '이메일로 받은 8자리 코드를 입력하세요.';

  @override
  String get authOtpPrimarySend => '코드 보내기';

  @override
  String get authOtpPrimarySubmit => '로그인';

  @override
  String get authOtpResend => '코드 재전송';

  @override
  String authOtpResendDisabled(int seconds) {
    return '$seconds초 후 재전송';
  }

  @override
  String get authOtpChangeEmail => '이메일 변경';

  @override
  String get resumePlayback => '재생 이어보기';

  @override
  String get settingsCloudSyncSection => '클라우드 동기화';

  @override
  String get settingsCloudSyncAuto => '자동 동기화';

  @override
  String get settingsCloudSyncNow => '지금 동기화';

  @override
  String get settingsCloudSyncInProgress => '동기화 중…';

  @override
  String get settingsCloudSyncNever => '안 함';

  @override
  String settingsCloudSyncError(Object error) {
    return '최근 오류: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity을(를) 찾을 수 없습니다';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity을(를) 찾을 수 없습니다: $error';
  }

  @override
  String get entityProvider => '제공처';

  @override
  String get entityGenre => '장르';

  @override
  String get entityPlaylist => '재생목록';

  @override
  String get entitySource => '소스';

  @override
  String get entityMovie => '영화';

  @override
  String get entitySeries => '쇼';

  @override
  String get entityPerson => '인물';

  @override
  String get entitySaga => '사가';

  @override
  String get entityVideo => '비디오';

  @override
  String get entityRoute => '경로';

  @override
  String get errorTimeoutLoading => '불러오기 시간 초과';

  @override
  String get parentalContentRestricted => '제한된 콘텐츠';

  @override
  String get parentalContentRestrictedDefault =>
      '이 콘텐츠는 이 프로필의 자녀 보호 설정으로 차단되었습니다.';

  @override
  String get parentalReasonTooYoung => '이 콘텐츠는 프로필 제한보다 더 높은 연령이 필요합니다.';

  @override
  String get parentalReasonUnknownRating => '이 콘텐츠의 연령 등급을 사용할 수 없습니다.';

  @override
  String get parentalReasonInvalidTmdbId => '이 콘텐츠는 자녀 보호 평가를 할 수 없습니다.';

  @override
  String get parentalUnlockButton => '잠금 해제';

  @override
  String get hc_arb_dir_4de4827b => 'arb-dir';

  @override
  String get hc_template_arb_file_eeae5194 => 'template-arb-file';

  @override
  String get hc_output_localization_file_ed018380 => 'output-localization-file';

  @override
  String get hc_output_class_f1ae6b52 => 'output-class';

  @override
  String get hc_applocalizations_878fdc50 => 'AppLocalizations';

  @override
  String get hc_untranslated_messages_file_fa6a22b7 =>
      'untranslated-messages-file';

  @override
  String get hc_chargement_episodes_en_cours_33fc4ace => '에피소드 불러오는 중…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      '사용 가능한 재생목록이 없습니다. 새로 만들어 주세요.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      '재생목록 불러오기 오류: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => '링크를 열 수 없습니다';

  @override
  String get hc_qualite_preferee_776dbeea => '선호 품질';

  @override
  String get hc_annuler_49ba3292 => '취소';

  @override
  String get hc_deconnexion_903dca17 => '로그아웃';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      '로그아웃 중 오류: \$e';

  @override
  String get hc_choisir_b030d590 => '선택';

  @override
  String get hc_avantages_08d7f47c => '혜택';

  @override
  String get hc_signalement_envoye_merci_d302e576 => '신고가 전송되었습니다. 감사합니다.';

  @override
  String get hc_plus_tard_1f42ab3b => '나중에';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => '지금 다시 시작';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => '이 소스를 사용할까요?';

  @override
  String get hc_utiliser_fb5e43ce => '사용';

  @override
  String get hc_source_ajout_e_e41b01d9 => '소스를 추가했습니다';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => '잠긴 설정';

  @override
  String get hc_compte_cloud_2812b31e => '클라우드 계정';

  @override
  String get hc_se_connecter_fedf2439 => '로그인';

  @override
  String get hc_propos_5345add5 => '정보';

  @override
  String get hc_politique_confidentialite_42b0e51e => '개인정보처리방침';

  @override
  String get hc_conditions_dutilisation_9074eac7 => '이용 약관';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => '저장된 소스';

  @override
  String get hc_rafraichir_be30b7d1 => '새로고침';

  @override
  String get hc_activer_une_source_749ced38 => '소스 활성화';

  @override
  String get hc_nom_source_9a3e4156 => '소스 이름';

  @override
  String get hc_mon_iptv_b239352c => '내 IPTV';

  @override
  String get hc_username_84c29015 => '사용자 이름';

  @override
  String get hc_password_8be3c943 => '비밀번호';

  @override
  String get hc_server_url_1d5d1eff => '서버 URL';

  @override
  String get hc_verification_pin_e17c8fe0 => 'PIN 확인';

  @override
  String get hc_definir_un_pin_f9c2178d => 'PIN 설정';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      '구독 상품을 찾을 수 없습니다: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      '사용자가 구독 구매를 취소했습니다.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      '스토어 작업 시간이 초과되었습니다: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 => '핸드셰이크 중 HTTP 오류';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Xtream 서버의 JSON이 아닌 응답';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f => 'Xtream 서버의 잘못된 응답';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      '이 소스에서는 사용할 수 없습니다';

  @override
  String get hc_source_supprimee_4bfaa0a1 => '소스를 제거했습니다';

  @override
  String get hc_source_modifiee_335ef502 => '소스를 업데이트했습니다';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'PIN 코드 설정';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => '미시청으로 표시';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 => '로그아웃하시겠어요?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      '클라우드 동기화에는 Movi Premium이 필요합니다.';

  @override
  String get hc_auto_c614ba7c => '자동';

  @override
  String get hc_organiser_838a7e57 => '정리';

  @override
  String get hc_modifier_f260e757 => '편집';

  @override
  String get hc_ajouter_87c57ed1 => '추가';

  @override
  String get hc_source_active_e571305e => '활성 소스';

  @override
  String get hc_autres_sources_e32592a6 => '다른 소스';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      '이 콘텐츠에서는 신고 기능을 사용할 수 없습니다.';

  @override
  String get hc_securisation_contenu_e5195111 => '콘텐츠 보호';

  @override
  String get hc_verification_classifications_d_age_006eebfe => '연령 등급 확인 중…';

  @override
  String get hc_voir_tout_7b7d86e8 => '모두 보기';

  @override
  String get hc_signaler_un_probleme_13183c0f => '문제 신고';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      '이 콘텐츠가 부적절하며 제한에도 불구하고 접근 가능했다면, 문제를 간단히 설명해 주세요.';

  @override
  String get hc_envoyer_e9ce243b => '보내기';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => '어린이 프로필을 만들었습니다';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      '어린이 프로필이 생성되었습니다. 앱을 보호하고 연령 등급을 미리 불러오기 위해 앱을 다시 시작하는 것을 권장합니다.';

  @override
  String get hc_pseudo_4cf966c0 => '닉네임';

  @override
  String get hc_profil_enfant_2c8a01c0 => '어린이 프로필';

  @override
  String get hc_limite_d_age_5b170fc9 => '연령 제한';

  @override
  String get hc_code_pin_e79c48bd => 'PIN 코드';

  @override
  String get hc_changer_code_pin_3b069731 => 'PIN 코드 변경';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'PIN 코드 제거';

  @override
  String get hc_supprimer_pin_51850c7b => 'PIN 제거';

  @override
  String get hc_supprimer_1acfc1c7 => '삭제';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'PIN이 필요하며 PEGI 필터를 활성화합니다.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      '지금 이 소스를 활성화할까요?';

  @override
  String get hc_application_b291beb8 => '앱';

  @override
  String get hc_version_1_0_0_347e553c => '버전 1.0.0';

  @override
  String get hc_credits_293a6081 => '크레딧';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      '이 제품은 TMDB API를 사용하지만 TMDB에서 보증하거나 인증하지 않았습니다.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      '이 제품은 TMDB API를 사용하지만 TMDB에서 보증하거나 인증하지 않았습니다.';

  @override
  String get hc_verification_targets_d51632f8 => '검증 대상';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 => '페이드는 프레임과 자연스럽게 이어져야 합니다';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 => '잘못된 Xtream streamId: ...';

  @override
  String get hc_series_xtream_missing_poster_065b5103 =>
      'Series xtream:... missing poster';

  @override
  String get hc_movie_not_found_a7fe72d9 => 'Movie ... not found ...';

  @override
  String get hc_missing_poster_1c9ba558 => '... missing poster';

  @override
  String get hc_invalid_watchlist_outbox_payload_327ac6c3 =>
      'Invalid watchlist outbox payload.';

  @override
  String get hc_unknown_watchlist_operation_e9259c07 =>
      'Unknown watchlist operation: ...';

  @override
  String get hc_invalid_playlist_outbox_payload_2d76e64f =>
      'Invalid playlist outbox payload.';

  @override
  String get hc_unknown_playlist_operation_c98cbd41 =>
      'Unknown playlist operation: ...';

  @override
  String get hc_url_invalide_aa227a66 => '잘못된 URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'새로고침\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'메뉴\'';

  @override
  String get hc_retour_e5befb1f => '뒤로';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'추가 작업\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => '추가 작업';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c => 'semanticLabel: \'검색\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'추가\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => '확인';

  @override
  String get actionSignOut => '로그아웃';

  @override
  String get dialogSignOutBody => '로그아웃하시겠습니까?';

  @override
  String get settingsUnableToOpenLink => '링크를 열 수 없습니다';

  @override
  String get settingsSyncDisabled => '사용 안 함';

  @override
  String get settingsSyncEveryHour => '매시간';

  @override
  String get settingsSyncEvery2Hours => '2시간마다';

  @override
  String get settingsSyncEvery4Hours => '4시간마다';

  @override
  String get settingsSyncEvery6Hours => '6시간마다';

  @override
  String get settingsSyncEveryDay => '매일';

  @override
  String get settingsSyncEvery2Days => '2일마다';

  @override
  String get settingsColorCustom => '사용자 지정';

  @override
  String get settingsColorBlue => '파랑';

  @override
  String get settingsColorPink => '분홍';

  @override
  String get settingsColorGreen => '초록';

  @override
  String get settingsColorPurple => '보라';

  @override
  String get settingsColorOrange => '주황';

  @override
  String get settingsColorTurquoise => '청록';

  @override
  String get settingsColorYellow => '노랑';

  @override
  String get settingsColorIndigo => '인디고';

  @override
  String get settingsCloudAccountTitle => '클라우드 계정';

  @override
  String get settingsAccountConnected => '연결됨';

  @override
  String get settingsAccountLocalMode => '로컬 모드';

  @override
  String get settingsAccountCloudUnavailable => '클라우드를 사용할 수 없음';

  @override
  String get aboutTmdbDisclaimer =>
      '이 제품은 TMDB API를 사용하지만 TMDB의 승인 또는 인증을 받지 않았습니다.';

  @override
  String get aboutCreditsSectionTitle => '크레딧';
}
