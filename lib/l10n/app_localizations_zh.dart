// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get welcomeTitle => '欢迎！';

  @override
  String get welcomeSubtitle => '填写偏好设置以个性化 Movi。';

  @override
  String get labelUsername => '昵称';

  @override
  String get labelPreferredLanguage => '首选语言';

  @override
  String get actionContinue => '继续';

  @override
  String get hintUsername => '你的昵称';

  @override
  String get errorFillFields => '请正确填写字段。';

  @override
  String get homeWatchNow => '观看';

  @override
  String get welcomeSourceTitle => '欢迎！';

  @override
  String get welcomeSourceSubtitle => '添加一个源来个性化你在 Movi 的体验。';

  @override
  String get welcomeSourceAdd => '添加源';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '输入搜索内容';

  @override
  String get clear => '清除';

  @override
  String get moviesTitle => '电影';

  @override
  String get seriesTitle => '剧集';

  @override
  String get noResults => '无结果';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyEmpty => '没有最近搜索';

  @override
  String get delete => '删除';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条结果',
      zero: '无结果',
    );
    return '$_temp0';
  }

  @override
  String get errorUnknown => '未知错误';

  @override
  String errorConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get errorConnectionGeneric => '连接失败';

  @override
  String get validationRequired => '必填';

  @override
  String get validationInvalidUrl => '无效的 URL';

  @override
  String get snackbarSourceAddedBackground => '已添加 IPTV 源。正在后台同步…';

  @override
  String get snackbarSourceAddedSynced => '已添加并同步 IPTV 源';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navLibrary => '资料库';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguageLabel => '应用语言';

  @override
  String get settingsGeneralTitle => '通用偏好';

  @override
  String get settingsDarkModeTitle => '深色模式';

  @override
  String get settingsDarkModeSubtitle => '启用适合夜间使用的主题。';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsNotificationsSubtitle => '获取新内容发布通知。';

  @override
  String get settingsAccountTitle => '账户';

  @override
  String get settingsProfileInfoTitle => '个人资料信息';

  @override
  String get settingsProfileInfoSubtitle => '姓名、头像、偏好';

  @override
  String get settingsAboutTitle => '关于';

  @override
  String get settingsLegalMentionsTitle => '法律声明';

  @override
  String get settingsPrivacyPolicyTitle => '隐私政策';

  @override
  String get actionCancel => '取消';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionRetry => '重试';

  @override
  String get settingsHelpDiagnosticsSection => '帮助与诊断';

  @override
  String get settingsExportErrorLogs => '导出错误日志';

  @override
  String get diagnosticsExportTitle => '导出错误日志';

  @override
  String get diagnosticsExportDescription =>
      '诊断仅包含最近的 WARN/ERROR 日志以及（如启用）已哈希的账户/资料标识符。不应出现任何 key/token。';

  @override
  String get diagnosticsIncludeHashedIdsTitle => '包含账户/资料标识符（已哈希）';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle => '有助于关联问题而不暴露原始 ID。';

  @override
  String get diagnosticsCopiedClipboard => '诊断信息已复制到剪贴板。';

  @override
  String diagnosticsSavedFile(String fileName) {
    return '诊断已保存：$fileName';
  }

  @override
  String get diagnosticsActionCopy => '复制';

  @override
  String get diagnosticsActionSave => '保存';

  @override
  String get actionChangeVersion => '更改版本';

  @override
  String get semanticsBack => '返回';

  @override
  String get semanticsMoreActions => '更多操作';

  @override
  String get snackbarLoadingPlaylists => '正在加载播放列表…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne => '没有可用的播放列表。创建一个吧。';

  @override
  String errorAddToPlaylist(String error) {
    return '添加到播放列表失败：$error';
  }

  @override
  String get errorAlreadyInPlaylist => '该媒体已在此播放列表中';

  @override
  String errorLoadingPlaylists(String message) {
    return '加载播放列表失败：$message';
  }

  @override
  String get errorReportUnavailableForContent => '此内容无法使用举报功能。';

  @override
  String get snackbarLoadingEpisodes => '正在加载剧集…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist => '该集在播放列表中不可用';

  @override
  String snackbarGenericError(String error) {
    return '错误：$error';
  }

  @override
  String get snackbarLoading => '正在加载…';

  @override
  String get snackbarNoVersionAvailable => '没有可用版本';

  @override
  String get snackbarVersionSaved => '版本已保存';

  @override
  String playbackVariantFallbackLabel(int index) {
    return '版本 $index';
  }

  @override
  String get actionReadMore => '展开';

  @override
  String get actionShowLess => '收起';

  @override
  String get actionViewPage => '查看页面';

  @override
  String get semanticsSeeSagaPage => '查看系列页面';

  @override
  String get libraryTypeSaga => '系列';

  @override
  String get libraryTypeInProgress => '继续观看';

  @override
  String get libraryTypeFavoriteMovies => '喜欢的电影';

  @override
  String get libraryTypeFavoriteSeries => '喜欢的剧集';

  @override
  String get libraryTypeHistory => '历史记录';

  @override
  String get libraryTypePlaylist => '播放列表';

  @override
  String get libraryTypeArtist => '艺人';

  @override
  String libraryItemCount(int count) {
    return '$count 个项目';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return '播放列表已重命名为“$name”';
  }

  @override
  String get snackbarPlaylistDeleted => '播放列表已删除';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '确定要删除“$title”吗？';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return '“$query”无结果';
  }

  @override
  String errorGenericWithMessage(String error) {
    return '错误：$error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist => '该媒体已在播放列表中';

  @override
  String get snackbarAddedToPlaylist => '已添加到播放列表';

  @override
  String get addMediaTitle => '添加媒体';

  @override
  String get searchMinCharsHint => '请输入至少 3 个字符进行搜索';

  @override
  String get badgeAdded => '已添加';

  @override
  String get snackbarNotAvailableOnSource => '此源不可用';

  @override
  String get errorLoadingTitle => '加载错误';

  @override
  String errorLoadingWithMessage(String error) {
    return '加载错误：$error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return '加载播放列表失败：$error';
  }

  @override
  String get libraryClearFilterSemanticLabel => '清除筛选';

  @override
  String get homeErrorSwipeToRetry => '发生错误。下拉以重试。';

  @override
  String get homeContinueWatching => '继续观看';

  @override
  String get homeNoIptvSources => '没有激活的 IPTV 源。请在设置中添加源以查看分类。';

  @override
  String get homeNoTrends => '没有可用的热门内容';

  @override
  String get actionRefreshMetadata => '刷新元数据';

  @override
  String get actionChangeMetadata => '更改元数据';

  @override
  String get actionAddToList => '添加到列表';

  @override
  String get metadataRefreshed => '元数据已刷新';

  @override
  String get errorRefreshingMetadata => '刷新元数据失败';

  @override
  String get actionMarkSeen => '标记为已看';

  @override
  String get actionMarkUnseen => '标记为未看';

  @override
  String get actionReportProblem => '举报问题';

  @override
  String get featureComingSoon => '功能即将推出';

  @override
  String get subtitlesMenuTitle => '字幕';

  @override
  String get audioMenuTitle => '音频';

  @override
  String get videoFitModeMenuTitle => '显示模式';

  @override
  String get videoFitModeContain => '原始比例';

  @override
  String get videoFitModeCover => '填充屏幕';

  @override
  String get actionDisable => '禁用';

  @override
  String defaultTrackLabel(String id) {
    return '音轨 $id';
  }

  @override
  String get controlRewind10 => '10 秒';

  @override
  String get controlRewind30 => '30 秒';

  @override
  String get controlForward10 => '+10 秒';

  @override
  String get controlForward30 => '+30 秒';

  @override
  String get actionNextEpisode => '下一集';

  @override
  String get actionRestart => '重新开始';

  @override
  String get errorSeriesDataUnavailable => '无法加载剧集数据';

  @override
  String get errorNextEpisodeFailed => '无法确定下一集';

  @override
  String get actionLoadMore => '加载更多';

  @override
  String get iptvServerUrlLabel => '服务器 URL';

  @override
  String get iptvServerUrlHint => 'Xtream 服务器 URL';

  @override
  String get iptvPasswordLabel => '密码';

  @override
  String get iptvPasswordHint => 'Xtream 密码';

  @override
  String get actionConnect => '连接';

  @override
  String get settingsRefreshIptvPlaylistsTitle => '刷新 IPTV 播放列表';

  @override
  String get activeSourceTitle => '活动源';

  @override
  String get statusActive => '已激活';

  @override
  String get statusNoActiveSource => '无活动源';

  @override
  String get overlayPreparingHome => '正在准备首页…';

  @override
  String get overlayLoadingMoviesAndSeries => '正在加载电影和剧集…';

  @override
  String get overlayLoadingCategories => '正在加载分类…';

  @override
  String get bootstrapRefreshing => '正在刷新 IPTV 列表…';

  @override
  String get bootstrapEnriching => '正在准备元数据…';

  @override
  String get errorPrepareHome => '无法准备首页';

  @override
  String get overlayOpeningHome => '正在打开首页…';

  @override
  String get overlayRefreshingIptvLists => '正在刷新 IPTV 列表…';

  @override
  String get overlayPreparingMetadata => '正在准备元数据…';

  @override
  String get errorHomeLoadTimeout => '首页加载超时';

  @override
  String get faqLabel => '常见问题';

  @override
  String get iptvUsernameLabel => '用户名';

  @override
  String get iptvUsernameHint => 'Xtream 用户名';

  @override
  String get actionBack => '返回';

  @override
  String get actionSeeAll => '查看全部';

  @override
  String get actionExpand => '展开';

  @override
  String get actionCollapse => '收起';

  @override
  String providerSearchPlaceholder(String provider) {
    return '搜索 $provider';
  }

  @override
  String get actionClearHistory => '清除历史记录';

  @override
  String get castTitle => '演员表';

  @override
  String get recommendationsTitle => '推荐';

  @override
  String get libraryHeader => '你的资料库';

  @override
  String get libraryDataInfo => '当实现 data/domain 后将显示数据。';

  @override
  String get libraryEmpty => '点赞电影、剧集或演员后，它们会出现在这里。';

  @override
  String get serie => '剧集';

  @override
  String get recherche => '搜索';

  @override
  String get notYetAvailable => '尚不可用';

  @override
  String get createPlaylistTitle => '创建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get addMedia => '添加媒体';

  @override
  String get renamePlaylist => '重命名';

  @override
  String get deletePlaylist => '删除';

  @override
  String get pinPlaylist => '置顶';

  @override
  String get unpinPlaylist => '取消置顶';

  @override
  String get playlistPinned => '播放列表已置顶';

  @override
  String get playlistUnpinned => '播放列表已取消置顶';

  @override
  String get playlistDeleted => '播放列表已删除';

  @override
  String playlistCreatedSuccess(String name) {
    return '已创建播放列表“$name”';
  }

  @override
  String playlistCreateError(String error) {
    return '创建播放列表失败：$error';
  }

  @override
  String get addedToPlaylist => '已添加';

  @override
  String get pinRecoveryLink => '找回 PIN 码';

  @override
  String get pinRecoveryTitle => '找回 PIN 码';

  @override
  String get pinRecoveryDescription => '通过你的账户邮箱接收验证码，以重设受保护个人资料的 PIN 码。';

  @override
  String get pinRecoveryRequestCodeButton => '傳送代碼';

  @override
  String get pinRecoveryCodeSentHint => '代碼已傳送到你帳戶的電子郵件地址。請檢查訊息並在下方輸入。';

  @override
  String get pinRecoveryComingSoon => '该功能即将推出。';

  @override
  String get pinRecoveryNotAvailable => '目前無法透過電子郵件找回 PIN 碼。';

  @override
  String get pinRecoveryCodeLabel => '找回码';

  @override
  String get pinRecoveryCodeHint => '8 位数字';

  @override
  String get pinRecoveryVerifyButton => '验证代码';

  @override
  String get pinRecoveryCodeInvalid => '请输入 8 位数字验证码';

  @override
  String get pinRecoveryCodeExpired => '找回码已过期';

  @override
  String get pinRecoveryTooManyAttempts => '尝试次数过多。请稍后再试。';

  @override
  String get pinRecoveryUnknownError => '发生了意外错误';

  @override
  String get pinRecoveryNewPinLabel => '新 PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 位数字';

  @override
  String get pinRecoveryConfirmPinLabel => '确认 PIN';

  @override
  String get pinRecoveryConfirmPinHint => '再次输入 PIN';

  @override
  String get pinRecoveryResetButton => '重设 PIN 码';

  @override
  String get pinRecoveryPinInvalid => '请输入 4 到 6 位数字 PIN 码';

  @override
  String get pinRecoveryPinMismatch => '两次输入的 PIN 不一致';

  @override
  String get pinRecoveryResetSuccess => 'PIN 已更新';

  @override
  String get profilePinSaved => 'PIN 碼已儲存。';

  @override
  String get profilePinEditLabel => '編輯 PIN 碼';

  @override
  String get settingsAccountsSection => '账户';

  @override
  String get settingsIptvSection => 'IPTV 设置';

  @override
  String get settingsSourcesManagement => '源管理';

  @override
  String get settingsSyncFrequency => '更新频率';

  @override
  String get settingsAppSection => '应用设置';

  @override
  String get settingsAccentColor => '强调色';

  @override
  String get settingsPlaybackSection => '播放设置';

  @override
  String get settingsPreferredAudioLanguage => '首选音频语言';

  @override
  String get settingsPreferredSubtitleLanguage => '首选字幕语言';

  @override
  String get libraryPlaylistsFilter => '播放列表';

  @override
  String get librarySagasFilter => '系列';

  @override
  String get libraryArtistsFilter => '艺人';

  @override
  String get librarySearchPlaceholder => '在我的资料库中搜索…';

  @override
  String get libraryInProgress => '继续观看';

  @override
  String get libraryFavoriteMovies => '喜欢的电影';

  @override
  String get libraryFavoriteSeries => '喜欢的剧集';

  @override
  String get libraryWatchHistory => '观看历史';

  @override
  String libraryItemCountPlural(int count) {
    return '$count 个项目';
  }

  @override
  String get searchPeopleTitle => '人物';

  @override
  String get searchSagasTitle => '系列';

  @override
  String get searchByProvidersTitle => '按平台';

  @override
  String get searchByGenresTitle => '按类型';

  @override
  String get personRoleActor => '演员';

  @override
  String get personRoleDirector => '导演';

  @override
  String get personRoleCreator => '创作者';

  @override
  String get tvDistribution => '演员表';

  @override
  String tvSeasonLabel(int number) {
    return '第 $number 季';
  }

  @override
  String get tvNoEpisodesAvailable => '没有可用的剧集';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return '继续观看 S$season · E$episode';
  }

  @override
  String get sagaViewPage => '查看页面';

  @override
  String get sagaStartNow => '立即开始';

  @override
  String get sagaContinue => '继续';

  @override
  String sagaMovieCount(int count) {
    return '$count 部电影';
  }

  @override
  String get sagaMoviesList => '电影列表';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies 部电影 - $shows 部剧集';
  }

  @override
  String get personPlayRandomly => '随机播放';

  @override
  String get personMoviesList => '电影列表';

  @override
  String get personSeriesList => '剧集列表';

  @override
  String get playlistPlayRandomly => '随机播放';

  @override
  String get playlistAddButton => '添加到播放列表';

  @override
  String get playlistSortButton => '排序';

  @override
  String get playlistSortByTitle => '排序方式';

  @override
  String get playlistSortByTitleOption => '标题';

  @override
  String get playlistSortRecentAdditions => '最近添加';

  @override
  String get playlistSortOldestFirst => '最早添加';

  @override
  String get playlistSortNewestFirst => '最新添加';

  @override
  String get playlistEmptyMessage => '该播放列表为空';

  @override
  String playlistItemCount(int count) {
    return '$count 个项目';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count 个项目';
  }

  @override
  String get playlistSeasonSingular => '季';

  @override
  String get playlistSeasonPlural => '季';

  @override
  String get playlistRenameTitle => '重命名播放列表';

  @override
  String get playlistNamePlaceholder => '播放列表名称';

  @override
  String playlistRenamedSuccess(String name) {
    return '播放列表已重命名为“$name”';
  }

  @override
  String get playlistDeleteTitle => '删除播放列表';

  @override
  String playlistDeleteConfirm(String title) {
    return '确定要删除“$title”吗？';
  }

  @override
  String get playlistDeletedSuccess => '播放列表已删除';

  @override
  String get playlistItemRemovedSuccess => '项目已移除';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '从播放列表中移除“$title”？';
  }

  @override
  String get categoryLoadFailed => '无法加载分类。';

  @override
  String get categoryEmpty => '该分类为空。';

  @override
  String get categoryLoadingMore => '正在加载更多…';

  @override
  String get movieNoPlaylistsAvailable => '没有可用的播放列表';

  @override
  String playlistAddedTo(String title) {
    return '已添加到“$title”';
  }

  @override
  String errorWithMessage(String message) {
    return '错误：$message';
  }

  @override
  String get movieNotAvailableInPlaylist => '该电影在播放列表中不可用';

  @override
  String errorPlaybackFailed(String message) {
    return '播放失败：$message';
  }

  @override
  String get movieNoMedia => '没有可显示的媒体';

  @override
  String get personNoData => '没有可显示的人物。';

  @override
  String get personGenericError => '加载该人物时发生错误。';

  @override
  String get personBiographyTitle => '简介';

  @override
  String get authOtpTitle => '登录';

  @override
  String get authOtpSubtitle => '请输入邮箱地址以及我们发送给你的 8 位验证码。';

  @override
  String get authOtpEmailLabel => '邮箱';

  @override
  String get authOtpEmailHint => 'name@example.com';

  @override
  String get authOtpEmailHelp => '我们将发送 8 位验证码。如有需要请检查垃圾邮件。';

  @override
  String get authOtpCodeLabel => '验证码';

  @override
  String get authOtpCodeHint => '8 位验证码';

  @override
  String get authOtpCodeHelp => '请输入通过电子邮件收到的 8 位验证码。';

  @override
  String get authOtpPrimarySend => '发送验证码';

  @override
  String get authOtpPrimarySubmit => '登录';

  @override
  String get authOtpResend => '重新发送验证码';

  @override
  String authOtpResendDisabled(int seconds) {
    return '请在 $seconds 秒后重试';
  }

  @override
  String get authOtpChangeEmail => '更换邮箱';

  @override
  String get resumePlayback => '继续播放';

  @override
  String get settingsCloudSyncSection => '云同步';

  @override
  String get settingsCloudSyncAuto => '自动同步';

  @override
  String get settingsCloudSyncNow => '立即同步';

  @override
  String get settingsCloudSyncInProgress => '正在同步…';

  @override
  String get settingsCloudSyncNever => '从不';

  @override
  String settingsCloudSyncError(Object error) {
    return '上次错误：$error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '未找到$entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '未找到$entity：$error';
  }

  @override
  String get entityProvider => '平台';

  @override
  String get entityGenre => '类型';

  @override
  String get entityPlaylist => '播放列表';

  @override
  String get entitySource => '源';

  @override
  String get entityMovie => '电影';

  @override
  String get entitySeries => '剧集';

  @override
  String get entityPerson => '人物';

  @override
  String get entitySaga => '系列';

  @override
  String get entityVideo => '视频';

  @override
  String get entityRoute => '路由';

  @override
  String get errorTimeoutLoading => '加载超时';

  @override
  String get parentalContentRestricted => '受限内容';

  @override
  String get parentalContentRestrictedDefault => '此内容已被该资料的家长控制阻止。';

  @override
  String get parentalReasonTooYoung => '此内容所需年龄高于该资料限制。';

  @override
  String get parentalReasonUnknownRating => '该内容的年龄分级不可用。';

  @override
  String get parentalReasonInvalidTmdbId => '该内容无法进行家长控制评估。';

  @override
  String get parentalUnlockButton => '解锁';

  @override
  String get actionOk => '确定';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get dialogSignOutBody => '确定要退出登录吗？';

  @override
  String get settingsUnableToOpenLink => '无法打开链接';

  @override
  String get settingsSyncDisabled => '已停用';

  @override
  String get settingsSyncEveryHour => '每小时';

  @override
  String get settingsSyncEvery2Hours => '每 2 小时';

  @override
  String get settingsSyncEvery4Hours => '每 4 小时';

  @override
  String get settingsSyncEvery6Hours => '每 6 小时';

  @override
  String get settingsSyncEveryDay => '每天';

  @override
  String get settingsSyncEvery2Days => '每 2 天';

  @override
  String get settingsColorCustom => '自定义';

  @override
  String get settingsColorBlue => '蓝色';

  @override
  String get settingsColorPink => '粉色';

  @override
  String get settingsColorGreen => '绿色';

  @override
  String get settingsColorPurple => '紫色';

  @override
  String get settingsColorOrange => '橙色';

  @override
  String get settingsColorTurquoise => '青绿色';

  @override
  String get settingsColorYellow => '黄色';

  @override
  String get settingsColorIndigo => '靛蓝';

  @override
  String get settingsCloudAccountTitle => '云账户';

  @override
  String get settingsAccountConnected => '已连接';

  @override
  String get settingsAccountLocalMode => '本地模式';

  @override
  String get settingsAccountCloudUnavailable => '云不可用';

  @override
  String get settingsSubtitlesTitle => '字幕';

  @override
  String get settingsSubtitlesSizeTitle => '文本大小';

  @override
  String get settingsSubtitlesColorTitle => '文本颜色';

  @override
  String get settingsSubtitlesFontTitle => '字体';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => '系统';

  @override
  String get settingsSubtitlesQuickSettingsTitle => '快速设置';

  @override
  String get settingsSubtitlesPreviewTitle => '预览';

  @override
  String get settingsSubtitlesPreviewSample => '这是字幕预览。\n可实时调整可读性。';

  @override
  String get settingsSubtitlesBackgroundTitle => '背景';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => '背景不透明度';

  @override
  String get settingsSubtitlesShadowTitle => '阴影';

  @override
  String get settingsSubtitlesShadowOff => '关闭';

  @override
  String get settingsSubtitlesShadowSoft => '柔和';

  @override
  String get settingsSubtitlesShadowStrong => '强';

  @override
  String get settingsSubtitlesFineSizeTitle => '精细大小';

  @override
  String get settingsSubtitlesFineSizeValueLabel => '缩放';

  @override
  String get settingsSubtitlesResetDefaults => '恢复默认';

  @override
  String get settingsSubtitlesPremiumLockedTitle => '高级字幕样式（Premium）';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      '背景、透明度、阴影预设和精细大小仅在 Movi Premium 中可用。';

  @override
  String get settingsSubtitlesPremiumLockedAction => '使用 Premium 解锁';

  @override
  String get settingsSyncSectionTitle => '音频/字幕同步';

  @override
  String get settingsSubtitleOffsetTitle => '字幕偏移';

  @override
  String get settingsAudioOffsetTitle => '音频偏移';

  @override
  String get settingsOffsetUnsupported => '此后端或平台暂不支持此功能。';

  @override
  String get settingsSyncResetOffsets => '重置同步偏移';

  @override
  String get aboutTmdbDisclaimer => '本产品使用 TMDB API，但未获得 TMDB 的认可或认证。';

  @override
  String get aboutCreditsSectionTitle => '致谢';

  @override
  String get actionSend => '发送';

  @override
  String get profilePinSetLabel => '设置 PIN 码';

  @override
  String get reportingProblemSentConfirmation => '举报已发送。谢谢。';

  @override
  String get reportingProblemBody => '如果此内容不适宜且在限制下仍可访问，请简要描述问题。';

  @override
  String get reportingProblemExampleHint => '示例：PEGI 12 下仍能看到恐怖片';

  @override
  String get settingsAutomaticOption => '自动';

  @override
  String get settingsPreferredPlaybackQuality => '首选播放画质';

  @override
  String settingsSignOutError(String error) {
    return '退出登录失败：$error';
  }

  @override
  String get settingsTermsOfUseTitle => '使用条款';

  @override
  String get settingsCloudSyncPremiumRequiredMessage => '云同步需要 Movi Premium。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get welcomeTitle => '欢迎！';

  @override
  String get welcomeSubtitle => '填写偏好设置以个性化 Movi。';

  @override
  String get labelUsername => '昵称';

  @override
  String get labelPreferredLanguage => '首选语言';

  @override
  String get actionContinue => '继续';

  @override
  String get hintUsername => '你的昵称';

  @override
  String get errorFillFields => '请正确填写字段。';

  @override
  String get homeWatchNow => '观看';

  @override
  String get welcomeSourceTitle => '欢迎！';

  @override
  String get welcomeSourceSubtitle => '添加一个源来个性化你在 Movi 的体验。';

  @override
  String get welcomeSourceAdd => '添加源';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '输入搜索内容';

  @override
  String get clear => '清除';

  @override
  String get moviesTitle => '电影';

  @override
  String get seriesTitle => '剧集';

  @override
  String get noResults => '无结果';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyEmpty => '没有最近搜索';

  @override
  String get delete => '删除';

  @override
  String resultsCount(int count) {
    return '（$count 个结果）';
  }

  @override
  String get errorUnknown => '未知错误';

  @override
  String errorConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get errorConnectionGeneric => '连接失败';

  @override
  String get validationRequired => '必填';

  @override
  String get validationInvalidUrl => '无效的 URL';

  @override
  String get snackbarSourceAddedBackground => '已添加 IPTV 源。正在后台同步…';

  @override
  String get snackbarSourceAddedSynced => '已添加并同步 IPTV 源';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navLibrary => '资料库';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguageLabel => '应用语言';

  @override
  String get settingsGeneralTitle => '通用偏好';

  @override
  String get settingsDarkModeTitle => '深色模式';

  @override
  String get settingsDarkModeSubtitle => '启用适合夜间使用的主题。';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsNotificationsSubtitle => '获取新内容发布通知。';

  @override
  String get settingsAccountTitle => '账户';

  @override
  String get settingsProfileInfoTitle => '个人资料信息';

  @override
  String get settingsProfileInfoSubtitle => '姓名、头像、偏好';

  @override
  String get settingsAboutTitle => '关于';

  @override
  String get settingsLegalMentionsTitle => '法律声明';

  @override
  String get settingsPrivacyPolicyTitle => '隐私政策';

  @override
  String get actionCancel => '取消';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionRetry => '重试';

  @override
  String get settingsHelpDiagnosticsSection => '帮助与诊断';

  @override
  String get settingsExportErrorLogs => '导出错误日志';

  @override
  String get diagnosticsExportTitle => '导出错误日志';

  @override
  String get diagnosticsExportDescription =>
      '诊断仅包含最近的 WARN/ERROR 日志以及（如启用）已哈希的账户/资料标识符。不应出现任何 key/token。';

  @override
  String get diagnosticsIncludeHashedIdsTitle => '包含账户/资料标识符（已哈希）';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle => '有助于关联问题而不暴露原始 ID。';

  @override
  String get diagnosticsCopiedClipboard => '诊断信息已复制到剪贴板。';

  @override
  String diagnosticsSavedFile(String fileName) {
    return '诊断已保存：$fileName';
  }

  @override
  String get diagnosticsActionCopy => '复制';

  @override
  String get diagnosticsActionSave => '保存';

  @override
  String get actionChangeVersion => '更改版本';

  @override
  String get semanticsBack => '返回';

  @override
  String get semanticsMoreActions => '更多操作';

  @override
  String get snackbarLoadingPlaylists => '正在加载播放列表…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne => '没有可用的播放列表。创建一个吧。';

  @override
  String errorAddToPlaylist(String error) {
    return '添加到播放列表失败：$error';
  }

  @override
  String get errorAlreadyInPlaylist => '该媒体已在此播放列表中';

  @override
  String errorLoadingPlaylists(String message) {
    return '加载播放列表失败：$message';
  }

  @override
  String get errorReportUnavailableForContent => '此内容无法使用举报功能。';

  @override
  String get snackbarLoadingEpisodes => '正在加载剧集…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist => '该集在播放列表中不可用';

  @override
  String snackbarGenericError(String error) {
    return '错误：$error';
  }

  @override
  String get snackbarLoading => '正在加载…';

  @override
  String get snackbarNoVersionAvailable => '没有可用版本';

  @override
  String get snackbarVersionSaved => '版本已保存';

  @override
  String playbackVariantFallbackLabel(int index) {
    return '版本 $index';
  }

  @override
  String get actionReadMore => '展开';

  @override
  String get actionShowLess => '收起';

  @override
  String get actionViewPage => '查看页面';

  @override
  String get semanticsSeeSagaPage => '查看系列页面';

  @override
  String get libraryTypeSaga => '系列';

  @override
  String get libraryTypeInProgress => '继续观看';

  @override
  String get libraryTypeFavoriteMovies => '喜欢的电影';

  @override
  String get libraryTypeFavoriteSeries => '喜欢的剧集';

  @override
  String get libraryTypeHistory => '历史记录';

  @override
  String get libraryTypePlaylist => '播放列表';

  @override
  String get libraryTypeArtist => '艺人';

  @override
  String libraryItemCount(int count) {
    return '$count 个项目';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return '播放列表已重命名为“$name”';
  }

  @override
  String get snackbarPlaylistDeleted => '播放列表已删除';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '确定要删除“$title”吗？';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return '“$query”无结果';
  }

  @override
  String errorGenericWithMessage(String error) {
    return '错误：$error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist => '该媒体已在播放列表中';

  @override
  String get snackbarAddedToPlaylist => '已添加到播放列表';

  @override
  String get addMediaTitle => '添加媒体';

  @override
  String get searchMinCharsHint => '请输入至少 3 个字符进行搜索';

  @override
  String get badgeAdded => '已添加';

  @override
  String get snackbarNotAvailableOnSource => '此源不可用';

  @override
  String get errorLoadingTitle => '加载错误';

  @override
  String errorLoadingWithMessage(String error) {
    return '加载错误：$error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return '加载播放列表失败：$error';
  }

  @override
  String get libraryClearFilterSemanticLabel => '清除筛选';

  @override
  String get homeErrorSwipeToRetry => '发生错误。下拉以重试。';

  @override
  String get homeContinueWatching => '继续观看';

  @override
  String get homeNoIptvSources => '没有激活的 IPTV 源。请在设置中添加源以查看分类。';

  @override
  String get homeNoTrends => '没有可用的热门内容';

  @override
  String get actionRefreshMetadata => '刷新元数据';

  @override
  String get actionChangeMetadata => '更改元数据';

  @override
  String get actionAddToList => '添加到列表';

  @override
  String get metadataRefreshed => '元数据已刷新';

  @override
  String get errorRefreshingMetadata => '刷新元数据失败';

  @override
  String get actionMarkSeen => '标记为已看';

  @override
  String get actionMarkUnseen => '标记为未看';

  @override
  String get actionReportProblem => '举报问题';

  @override
  String get featureComingSoon => '功能即将推出';

  @override
  String get subtitlesMenuTitle => '字幕';

  @override
  String get audioMenuTitle => '音频';

  @override
  String get videoFitModeMenuTitle => '显示模式';

  @override
  String get videoFitModeContain => '原始比例';

  @override
  String get videoFitModeCover => '填充屏幕';

  @override
  String get actionDisable => '禁用';

  @override
  String defaultTrackLabel(String id) {
    return '音轨 $id';
  }

  @override
  String get controlRewind10 => '10 秒';

  @override
  String get controlRewind30 => '30 秒';

  @override
  String get controlForward10 => '+10 秒';

  @override
  String get controlForward30 => '+30 秒';

  @override
  String get actionNextEpisode => '下一集';

  @override
  String get actionRestart => '重新开始';

  @override
  String get errorSeriesDataUnavailable => '无法加载剧集数据';

  @override
  String get errorNextEpisodeFailed => '无法确定下一集';

  @override
  String get actionLoadMore => '加载更多';

  @override
  String get iptvServerUrlLabel => '服务器 URL';

  @override
  String get iptvServerUrlHint => 'Xtream 服务器 URL';

  @override
  String get iptvPasswordLabel => '密码';

  @override
  String get iptvPasswordHint => 'Xtream 密码';

  @override
  String get actionConnect => '连接';

  @override
  String get settingsRefreshIptvPlaylistsTitle => '刷新 IPTV 播放列表';

  @override
  String get activeSourceTitle => '活动源';

  @override
  String get statusActive => '已激活';

  @override
  String get statusNoActiveSource => '无活动源';

  @override
  String get overlayPreparingHome => '正在准备首页…';

  @override
  String get overlayLoadingMoviesAndSeries => '正在加载电影和剧集…';

  @override
  String get overlayLoadingCategories => '正在加载分类…';

  @override
  String get bootstrapRefreshing => '正在刷新 IPTV 列表…';

  @override
  String get bootstrapEnriching => '正在准备元数据…';

  @override
  String get errorPrepareHome => '无法准备首页';

  @override
  String get overlayOpeningHome => '正在打开首页…';

  @override
  String get overlayRefreshingIptvLists => '正在刷新 IPTV 列表…';

  @override
  String get overlayPreparingMetadata => '正在准备元数据…';

  @override
  String get errorHomeLoadTimeout => '首页加载超时';

  @override
  String get faqLabel => '常见问题';

  @override
  String get iptvUsernameLabel => '用户名';

  @override
  String get iptvUsernameHint => 'Xtream 用户名';

  @override
  String get actionBack => '返回';

  @override
  String get actionSeeAll => '查看全部';

  @override
  String get actionExpand => '展开';

  @override
  String get actionCollapse => '收起';

  @override
  String providerSearchPlaceholder(String provider) {
    return '在 $provider 中搜索…';
  }

  @override
  String get actionClearHistory => '清除历史记录';

  @override
  String get castTitle => '演员表';

  @override
  String get recommendationsTitle => '推荐';

  @override
  String get libraryHeader => '你的资料库';

  @override
  String get libraryDataInfo => '当实现 data/domain 后将显示数据。';

  @override
  String get libraryEmpty => '点赞电影、剧集或演员后，它们会出现在这里。';

  @override
  String get serie => '剧集';

  @override
  String get recherche => '搜索';

  @override
  String get notYetAvailable => '尚不可用';

  @override
  String get createPlaylistTitle => '创建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get addMedia => '添加媒体';

  @override
  String get renamePlaylist => '重命名';

  @override
  String get deletePlaylist => '删除';

  @override
  String get pinPlaylist => '置顶';

  @override
  String get unpinPlaylist => '取消置顶';

  @override
  String get playlistPinned => '播放列表已置顶';

  @override
  String get playlistUnpinned => '播放列表已取消置顶';

  @override
  String get playlistDeleted => '播放列表已删除';

  @override
  String playlistCreatedSuccess(String name) {
    return '已创建播放列表“$name”';
  }

  @override
  String playlistCreateError(String error) {
    return '创建播放列表失败：$error';
  }

  @override
  String get addedToPlaylist => '已添加';

  @override
  String get pinRecoveryLink => '找回 PIN 码';

  @override
  String get pinRecoveryTitle => '找回 PIN 码';

  @override
  String get pinRecoveryDescription => '通过你的账户邮箱接收验证码，以重设受保护个人资料的 PIN 码。';

  @override
  String get pinRecoveryRequestCodeButton => '发送代码';

  @override
  String get pinRecoveryCodeSentHint => '代码已发送到你账户的电子邮箱。请检查消息并在下方输入。';

  @override
  String get pinRecoveryComingSoon => '该功能即将推出。';

  @override
  String get pinRecoveryNotAvailable => '当前无法通过电子邮件找回 PIN 码。';

  @override
  String get pinRecoveryCodeLabel => '找回码';

  @override
  String get pinRecoveryCodeHint => '8 位数字';

  @override
  String get pinRecoveryVerifyButton => '验证代码';

  @override
  String get pinRecoveryCodeInvalid => '请输入 8 位数字验证码';

  @override
  String get pinRecoveryCodeExpired => '找回码已过期';

  @override
  String get pinRecoveryTooManyAttempts => '尝试次数过多。请稍后再试。';

  @override
  String get pinRecoveryUnknownError => '发生了意外错误';

  @override
  String get pinRecoveryNewPinLabel => '新 PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 位数字';

  @override
  String get pinRecoveryConfirmPinLabel => '确认 PIN';

  @override
  String get pinRecoveryConfirmPinHint => '再次输入 PIN';

  @override
  String get pinRecoveryResetButton => '重设 PIN 码';

  @override
  String get pinRecoveryPinInvalid => '请输入 4 到 6 位数字 PIN 码';

  @override
  String get pinRecoveryPinMismatch => '两次输入的 PIN 不一致';

  @override
  String get pinRecoveryResetSuccess => 'PIN 已更新';

  @override
  String get profilePinSaved => 'PIN 码已保存。';

  @override
  String get profilePinEditLabel => '编辑 PIN 码';

  @override
  String get settingsAccountsSection => '账户';

  @override
  String get settingsIptvSection => 'IPTV 设置';

  @override
  String get settingsSourcesManagement => '源管理';

  @override
  String get settingsSyncFrequency => '更新频率';

  @override
  String get settingsAppSection => '应用设置';

  @override
  String get settingsAccentColor => '强调色';

  @override
  String get settingsPlaybackSection => '播放设置';

  @override
  String get settingsPreferredAudioLanguage => '首选音频语言';

  @override
  String get settingsPreferredSubtitleLanguage => '首选字幕语言';

  @override
  String get libraryPlaylistsFilter => '播放列表';

  @override
  String get librarySagasFilter => '系列';

  @override
  String get libraryArtistsFilter => '艺人';

  @override
  String get librarySearchPlaceholder => '在我的资料库中搜索…';

  @override
  String get libraryInProgress => '继续观看';

  @override
  String get libraryFavoriteMovies => '喜欢的电影';

  @override
  String get libraryFavoriteSeries => '喜欢的剧集';

  @override
  String get libraryWatchHistory => '观看历史';

  @override
  String libraryItemCountPlural(int count) {
    return '$count 个项目';
  }

  @override
  String get searchPeopleTitle => '人物';

  @override
  String get searchSagasTitle => '系列';

  @override
  String get searchByProvidersTitle => '按平台';

  @override
  String get searchByGenresTitle => '按类型';

  @override
  String get personRoleActor => '演员';

  @override
  String get personRoleDirector => '导演';

  @override
  String get personRoleCreator => '创作者';

  @override
  String get tvDistribution => '演员表';

  @override
  String tvSeasonLabel(int number) {
    return '第 $number 季';
  }

  @override
  String get tvNoEpisodesAvailable => '没有可用的剧集';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return '继续观看 S$season · E$episode';
  }

  @override
  String get sagaViewPage => '查看页面';

  @override
  String get sagaStartNow => '立即开始';

  @override
  String get sagaContinue => '继续';

  @override
  String sagaMovieCount(int count) {
    return '$count 部电影';
  }

  @override
  String get sagaMoviesList => '电影列表';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies 部电影 - $shows 部剧集';
  }

  @override
  String get personPlayRandomly => '随机播放';

  @override
  String get personMoviesList => '电影列表';

  @override
  String get personSeriesList => '剧集列表';

  @override
  String get playlistPlayRandomly => '随机播放';

  @override
  String get playlistAddButton => '添加到播放列表';

  @override
  String get playlistSortButton => '排序';

  @override
  String get playlistSortByTitle => '排序方式';

  @override
  String get playlistSortByTitleOption => '标题';

  @override
  String get playlistSortRecentAdditions => '最近添加';

  @override
  String get playlistSortOldestFirst => '最早添加';

  @override
  String get playlistSortNewestFirst => '最新添加';

  @override
  String get playlistEmptyMessage => '该播放列表为空';

  @override
  String playlistItemCount(int count) {
    return '$count 个项目';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count 个项目';
  }

  @override
  String get playlistSeasonSingular => '季';

  @override
  String get playlistSeasonPlural => '季';

  @override
  String get playlistRenameTitle => '重命名播放列表';

  @override
  String get playlistNamePlaceholder => '播放列表名称';

  @override
  String playlistRenamedSuccess(String name) {
    return '播放列表已重命名为“$name”';
  }

  @override
  String get playlistDeleteTitle => '删除播放列表';

  @override
  String playlistDeleteConfirm(String title) {
    return '确定要删除“$title”吗？';
  }

  @override
  String get playlistDeletedSuccess => '播放列表已删除';

  @override
  String get playlistItemRemovedSuccess => '项目已移除';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '从播放列表中移除“$title”？';
  }

  @override
  String get categoryLoadFailed => '无法加载分类。';

  @override
  String get categoryEmpty => '该分类为空。';

  @override
  String get categoryLoadingMore => '正在加载更多…';

  @override
  String get movieNoPlaylistsAvailable => '没有可用的播放列表';

  @override
  String playlistAddedTo(String title) {
    return '已添加到“$title”';
  }

  @override
  String errorWithMessage(String message) {
    return '错误：$message';
  }

  @override
  String get movieNotAvailableInPlaylist => '该电影在播放列表中不可用';

  @override
  String errorPlaybackFailed(String message) {
    return '播放失败：$message';
  }

  @override
  String get movieNoMedia => '没有可显示的媒体';

  @override
  String get personNoData => '没有可显示的人物。';

  @override
  String get personGenericError => '加载该人物时发生错误。';

  @override
  String get personBiographyTitle => '简介';

  @override
  String get authOtpTitle => '登录';

  @override
  String get authOtpSubtitle => '请输入邮箱地址以及我们发送给你的 8 位验证码。';

  @override
  String get authOtpEmailLabel => '邮箱';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp => '我们将发送 8 位验证码。如有需要请检查垃圾邮件。';

  @override
  String get authOtpCodeLabel => '验证码';

  @override
  String get authOtpCodeHint => '8 位验证码';

  @override
  String get authOtpCodeHelp => '请输入通过电子邮件收到的 8 位验证码。';

  @override
  String get authOtpPrimarySend => '发送验证码';

  @override
  String get authOtpPrimarySubmit => '登录';

  @override
  String get authOtpResend => '重新发送验证码';

  @override
  String authOtpResendDisabled(int seconds) {
    return '请在 $seconds 秒后重试';
  }

  @override
  String get authOtpChangeEmail => '更换邮箱';

  @override
  String get resumePlayback => '继续播放';

  @override
  String get settingsCloudSyncSection => '云同步';

  @override
  String get settingsCloudSyncAuto => '自动同步';

  @override
  String get settingsCloudSyncNow => '立即同步';

  @override
  String get settingsCloudSyncInProgress => '正在同步…';

  @override
  String get settingsCloudSyncNever => '从不';

  @override
  String settingsCloudSyncError(Object error) {
    return '上次错误：$error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '未找到$entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '未找到$entity：$error';
  }

  @override
  String get entityProvider => '平台';

  @override
  String get entityGenre => '类型';

  @override
  String get entityPlaylist => '播放列表';

  @override
  String get entitySource => '源';

  @override
  String get entityMovie => '电影';

  @override
  String get entitySeries => '剧集';

  @override
  String get entityPerson => '人物';

  @override
  String get entitySaga => '系列';

  @override
  String get entityVideo => '视频';

  @override
  String get entityRoute => '路由';

  @override
  String get errorTimeoutLoading => '加载超时';

  @override
  String get parentalContentRestricted => '受限内容';

  @override
  String get parentalContentRestrictedDefault => '此内容已被该资料的家长控制阻止。';

  @override
  String get parentalReasonTooYoung => '此内容所需年龄高于该资料限制。';

  @override
  String get parentalReasonUnknownRating => '该内容的年龄分级不可用。';

  @override
  String get parentalReasonInvalidTmdbId => '该内容无法进行家长控制评估。';

  @override
  String get parentalUnlockButton => '解锁';

  @override
  String get actionOk => '确定';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get dialogSignOutBody => '确定要退出登录吗？';

  @override
  String get settingsUnableToOpenLink => '无法打开链接';

  @override
  String get settingsSyncDisabled => '已停用';

  @override
  String get settingsSyncEveryHour => '每小时';

  @override
  String get settingsSyncEvery2Hours => '每 2 小时';

  @override
  String get settingsSyncEvery4Hours => '每 4 小时';

  @override
  String get settingsSyncEvery6Hours => '每 6 小时';

  @override
  String get settingsSyncEveryDay => '每天';

  @override
  String get settingsSyncEvery2Days => '每 2 天';

  @override
  String get settingsColorCustom => '自定义';

  @override
  String get settingsColorBlue => '蓝色';

  @override
  String get settingsColorPink => '粉色';

  @override
  String get settingsColorGreen => '绿色';

  @override
  String get settingsColorPurple => '紫色';

  @override
  String get settingsColorOrange => '橙色';

  @override
  String get settingsColorTurquoise => '青绿色';

  @override
  String get settingsColorYellow => '黄色';

  @override
  String get settingsColorIndigo => '靛蓝';

  @override
  String get settingsCloudAccountTitle => '云账户';

  @override
  String get settingsAccountConnected => '已连接';

  @override
  String get settingsAccountLocalMode => '本地模式';

  @override
  String get settingsAccountCloudUnavailable => '云不可用';

  @override
  String get settingsSubtitlesTitle => '字幕';

  @override
  String get settingsSubtitlesSizeTitle => '文本大小';

  @override
  String get settingsSubtitlesColorTitle => '文本颜色';

  @override
  String get settingsSubtitlesFontTitle => '字体';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => '系统';

  @override
  String get settingsSubtitlesQuickSettingsTitle => '快速设置';

  @override
  String get settingsSubtitlesPreviewTitle => '预览';

  @override
  String get settingsSubtitlesPreviewSample => '这是字幕预览。\n可实时调整可读性。';

  @override
  String get settingsSubtitlesBackgroundTitle => '背景';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => '背景不透明度';

  @override
  String get settingsSubtitlesShadowTitle => '阴影';

  @override
  String get settingsSubtitlesShadowOff => '关闭';

  @override
  String get settingsSubtitlesShadowSoft => '柔和';

  @override
  String get settingsSubtitlesShadowStrong => '强';

  @override
  String get settingsSubtitlesFineSizeTitle => '精细大小';

  @override
  String get settingsSubtitlesFineSizeValueLabel => '缩放';

  @override
  String get settingsSubtitlesResetDefaults => '恢复默认';

  @override
  String get settingsSubtitlesPremiumLockedTitle => '高级字幕样式（Premium）';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      '背景、透明度、阴影预设和精细大小仅在 Movi Premium 中可用。';

  @override
  String get settingsSubtitlesPremiumLockedAction => '使用 Premium 解锁';

  @override
  String get settingsSyncSectionTitle => '音频/字幕同步';

  @override
  String get settingsSubtitleOffsetTitle => '字幕偏移';

  @override
  String get settingsAudioOffsetTitle => '音频偏移';

  @override
  String get settingsOffsetUnsupported => '此后端或平台暂不支持此功能。';

  @override
  String get settingsSyncResetOffsets => '重置同步偏移';

  @override
  String get aboutTmdbDisclaimer => '本产品使用 TMDB API，但未获得 TMDB 的认可或认证。';

  @override
  String get aboutCreditsSectionTitle => '致谢';

  @override
  String get actionSend => '发送';

  @override
  String get profilePinSetLabel => '设置 PIN 码';

  @override
  String get reportingProblemSentConfirmation => '举报已发送。谢谢。';

  @override
  String get reportingProblemBody => '如果此内容不适宜且在限制下仍可访问，请简要描述问题。';

  @override
  String get reportingProblemExampleHint => '示例：PEGI 12 下仍能看到恐怖片';

  @override
  String get settingsAutomaticOption => '自动';

  @override
  String get settingsPreferredPlaybackQuality => '首选播放画质';

  @override
  String settingsSignOutError(String error) {
    return '退出登录失败：$error';
  }

  @override
  String get settingsTermsOfUseTitle => '使用条款';

  @override
  String get settingsCloudSyncPremiumRequiredMessage => '云同步需要 Movi Premium。';
}
