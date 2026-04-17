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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '결과 $count개',
      zero: '결과 없음',
    );
    return '$_temp0';
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
  String get libraryTypeInProgress => '진행 중';

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
    return '$provider 검색';
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
  String get pinRecoveryLink => 'PIN 재설정';

  @override
  String get pinRecoveryTitle => 'PIN 재설정';

  @override
  String get pinRecoveryDescription =>
      '계정 이메일 주소로 8자리 코드를 보내드립니다. 이 코드를 사용해 이 프로필의 PIN을 재설정할 수 있습니다.';

  @override
  String get pinRecoveryRequestCodeButton => '코드 보내기';

  @override
  String get pinRecoveryCodeSentHint =>
      '계정 이메일로 코드가 전송되었습니다. 메시지를 확인한 뒤 아래에 입력하세요.';

  @override
  String get pinRecoveryComingSoon => '이 기능은 곧 제공됩니다.';

  @override
  String get pinRecoveryNotAvailable => '이메일을 통한 PIN 복구는 현재 사용할 수 없습니다.';

  @override
  String get pinRecoveryCodeLabel => '복구 코드';

  @override
  String get pinRecoveryCodeHint => '8자리';

  @override
  String get pinRecoveryVerifyButton => '코드 확인';

  @override
  String get pinRecoveryCodeInvalid => '8자리 복구 코드를 입력하세요';

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
  String get pinRecoveryConfirmPinHint => 'PIN을 다시 입력하세요';

  @override
  String get pinRecoveryResetButton => 'PIN 재설정';

  @override
  String get pinRecoveryPinInvalid => '4~6자리 PIN을 입력하세요';

  @override
  String get pinRecoveryPinMismatch => 'PIN이 일치하지 않습니다';

  @override
  String get pinRecoveryResetSuccess => 'PIN을 업데이트했습니다';

  @override
  String get profilePinSaved => 'PIN이 저장되었습니다.';

  @override
  String get profilePinEditLabel => 'PIN 코드 수정';

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
  String get settingsPreferredAudioLanguage => '선호 오디오 언어';

  @override
  String get settingsPreferredSubtitleLanguage => '선호 자막 언어';

  @override
  String get libraryPlaylistsFilter => '재생목록';

  @override
  String get librarySagasFilter => '사가';

  @override
  String get libraryArtistsFilter => '아티스트';

  @override
  String get librarySearchPlaceholder => '내 라이브러리에서 검색…';

  @override
  String get libraryInProgress => '이어 보기';

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
    return '이어 보기 S$season · E$episode';
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
  String get playlistAddButton => '재생목록에 추가';

  @override
  String get playlistSortButton => '정렬';

  @override
  String get playlistSortByTitle => '정렬 기준';

  @override
  String get playlistSortByTitleOption => '제목';

  @override
  String get playlistSortRecentAdditions => '최근 추가순';

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
  String get playlistDeleteTitle => '재생목록 삭제';

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
  String get authOtpSubtitle => '이메일 주소와 전송된 8자리 코드를 입력하세요.';

  @override
  String get authOtpEmailLabel => '이메일';

  @override
  String get authOtpEmailHint => 'name@example.com';

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
    return '코드 재전송까지 $seconds초';
  }

  @override
  String get authOtpChangeEmail => '이메일 변경';

  @override
  String get authOtpUsePassword => 'Use password instead';

  @override
  String get authPasswordTitle => 'Sign in';

  @override
  String get authPasswordSubtitle =>
      'Enter your email and password to continue.';

  @override
  String get authPasswordEmailLabel => 'Email';

  @override
  String get authPasswordEmailHint => 'name@example.com';

  @override
  String get authPasswordEmailHelp => 'Use the email linked to your account.';

  @override
  String get authPasswordPasswordLabel => 'Password';

  @override
  String get authPasswordPasswordHint => 'Your password';

  @override
  String get authPasswordPasswordHelp => 'Your password is case-sensitive.';

  @override
  String get authPasswordPrimarySubmit => 'Sign in';

  @override
  String get authPasswordForgotPassword => 'Forgot password?';

  @override
  String get authPasswordResetSent => 'Password reset email sent.';

  @override
  String get authPasswordUseOtp => 'Use email code instead';
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
  String get settingsSubtitlesTitle => '자막';

  @override
  String get settingsSubtitlesSizeTitle => '텍스트 크기';

  @override
  String get settingsSubtitlesColorTitle => '텍스트 색상';

  @override
  String get settingsSubtitlesFontTitle => '글꼴';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => '시스템';

  @override
  String get settingsSubtitlesQuickSettingsTitle => '빠른 설정';

  @override
  String get settingsSubtitlesPreviewTitle => '미리보기';

  @override
  String get settingsSubtitlesPreviewSample => '자막 미리보기입니다.\n가독성을 실시간으로 조정하세요.';

  @override
  String get settingsSubtitlesBackgroundTitle => '배경';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => '배경 불투명도';

  @override
  String get settingsSubtitlesShadowTitle => '그림자';

  @override
  String get settingsSubtitlesShadowOff => '끔';

  @override
  String get settingsSubtitlesShadowSoft => '약하게';

  @override
  String get settingsSubtitlesShadowStrong => '강하게';

  @override
  String get settingsSubtitlesFineSizeTitle => '세밀한 크기';

  @override
  String get settingsSubtitlesFineSizeValueLabel => '배율';

  @override
  String get settingsSubtitlesResetDefaults => '기본값으로 재설정';

  @override
  String get settingsSubtitlesPremiumLockedTitle => '고급 자막 스타일 (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      '배경, 불투명도, 그림자 프리셋 및 세밀한 크기는 Movi Premium에서 사용할 수 있습니다.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Premium으로 잠금 해제';

  @override
  String get settingsSyncSectionTitle => '오디오/자막 동기화';

  @override
  String get settingsSubtitleOffsetTitle => '자막 오프셋';

  @override
  String get settingsAudioOffsetTitle => '오디오 오프셋';

  @override
  String get settingsOffsetUnsupported => '현재 백엔드 또는 플랫폼에서는 지원되지 않습니다.';

  @override
  String get settingsSyncResetOffsets => '동기화 오프셋 초기화';

  @override
  String get aboutTmdbDisclaimer =>
      '이 제품은 TMDB API를 사용하지만 TMDB의 승인 또는 인증을 받지 않았습니다.';

  @override
  String get aboutCreditsSectionTitle => '크레딧';

  @override
  String get actionSend => '보내기';

  @override
  String get profilePinSetLabel => 'PIN 코드 설정';

  @override
  String get reportingProblemSentConfirmation => '신고가 전송되었습니다. 감사합니다.';

  @override
  String get reportingProblemBody =>
      '이 콘텐츠가 부적절한데도 제한에도 불구하고 접근할 수 있었다면 문제를 간단히 설명해 주세요.';

  @override
  String get reportingProblemExampleHint => '예: PEGI 12인데 공포 영화가 표시됨';

  @override
  String get settingsAutomaticOption => '자동';

  @override
  String get settingsPreferredPlaybackQuality => '선호 재생 화질';

  @override
  String settingsSignOutError(String error) {
    return '로그아웃 중 오류: $error';
  }

  @override
  String get settingsTermsOfUseTitle => '이용 약관';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      '클라우드 동기화에는 Movi Premium이 필요합니다.';
}
