// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcomeTitle => 'Добро пожаловать!';

  @override
  String get welcomeSubtitle =>
      'Заполните предпочтения, чтобы персонализировать Movi.';

  @override
  String get labelUsername => 'Никнейм';

  @override
  String get labelPreferredLanguage => 'Предпочитаемый язык';

  @override
  String get actionContinue => 'Продолжить';

  @override
  String get hintUsername => 'Ваш никнейм';

  @override
  String get errorFillFields => 'Пожалуйста, корректно заполните поля.';

  @override
  String get homeWatchNow => 'Смотреть';

  @override
  String get welcomeSourceTitle => 'Добро пожаловать!';

  @override
  String get welcomeSourceSubtitle =>
      'Добавьте источник, чтобы персонализировать ваш опыт в Movi.';

  @override
  String get welcomeSourceAdd => 'Добавить источник';

  @override
  String get searchTitle => 'Поиск';

  @override
  String get searchHint => 'Введите запрос';

  @override
  String get clear => 'Очистить';

  @override
  String get moviesTitle => 'Фильмы';

  @override
  String get seriesTitle => 'Сериалы';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get historyTitle => 'История';

  @override
  String get historyEmpty => 'Нет недавних поисков';

  @override
  String get delete => 'Удалить';

  @override
  String resultsCount(int count) {
    return '($count результатов)';
  }

  @override
  String get errorUnknown => 'Неизвестная ошибка';

  @override
  String errorConnectionFailed(String error) {
    return 'Не удалось подключиться: $error';
  }

  @override
  String get errorConnectionGeneric => 'Не удалось подключиться';

  @override
  String get validationRequired => 'Обязательно';

  @override
  String get validationInvalidUrl => 'Неверный URL';

  @override
  String get snackbarSourceAddedBackground =>
      'Источник IPTV добавлен. Синхронизация в фоновом режиме…';

  @override
  String get snackbarSourceAddedSynced =>
      'Источник IPTV добавлен и синхронизирован';

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageLabel => 'Язык приложения';

  @override
  String get settingsGeneralTitle => 'Общие предпочтения';

  @override
  String get settingsDarkModeTitle => 'Тёмная тема';

  @override
  String get settingsDarkModeSubtitle =>
      'Включите тему, удобную для ночного режима.';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsNotificationsSubtitle =>
      'Получайте уведомления о новых релизах.';

  @override
  String get settingsAccountTitle => 'Аккаунт';

  @override
  String get settingsProfileInfoTitle => 'Информация профиля';

  @override
  String get settingsProfileInfoSubtitle => 'Имя, аватар, предпочтения';

  @override
  String get settingsAboutTitle => 'О приложении';

  @override
  String get settingsLegalMentionsTitle => 'Юридическая информация';

  @override
  String get settingsPrivacyPolicyTitle => 'Политика конфиденциальности';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionConfirm => 'Подтвердить';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get settingsHelpDiagnosticsSection => 'Помощь и диагностика';

  @override
  String get settingsExportErrorLogs => 'Экспорт журналов ошибок';

  @override
  String get diagnosticsExportTitle => 'Экспорт журналов ошибок';

  @override
  String get diagnosticsExportDescription =>
      'Диагностика включает только недавние логи WARN/ERROR и хешированные идентификаторы аккаунта/профиля (если включено). Ключи/токены не должны появляться.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Включать идентификаторы аккаунта/профиля (хешированные)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Помогает сопоставить баг без раскрытия исходного ID.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Диагностика скопирована в буфер обмена.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Диагностика сохранена: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Копировать';

  @override
  String get diagnosticsActionSave => 'Сохранить';

  @override
  String get actionChangeVersion => 'Сменить версию';

  @override
  String get semanticsBack => 'Назад';

  @override
  String get semanticsMoreActions => 'Больше действий';

  @override
  String get snackbarLoadingPlaylists => 'Загрузка плейлистов…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Нет доступного плейлиста. Создайте новый.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Ошибка добавления в плейлист: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'Этот медиаконтент уже есть в этом плейлисте';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Ошибка загрузки плейлистов: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Отчёт/жалоба недоступны для этого контента.';

  @override
  String get snackbarLoadingEpisodes => 'Загрузка эпизодов…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Эпизод недоступен в плейлисте';

  @override
  String snackbarGenericError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get snackbarLoading => 'Загрузка…';

  @override
  String get snackbarNoVersionAvailable => 'Нет доступной версии';

  @override
  String get snackbarVersionSaved => 'Версия сохранена';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Версия $index';
  }

  @override
  String get actionReadMore => 'Подробнее';

  @override
  String get actionShowLess => 'Свернуть';

  @override
  String get actionViewPage => 'Открыть страницу';

  @override
  String get semanticsSeeSagaPage => 'Открыть страницу саги';

  @override
  String get libraryTypeSaga => 'Сага';

  @override
  String get libraryTypeInProgress => 'В процессе';

  @override
  String get libraryTypeFavoriteMovies => 'Любимые фильмы';

  @override
  String get libraryTypeFavoriteSeries => 'Любимые сериалы';

  @override
  String get libraryTypeHistory => 'История';

  @override
  String get libraryTypePlaylist => 'Плейлист';

  @override
  String get libraryTypeArtist => 'Артист';

  @override
  String libraryItemCount(int count) {
    return '$count элемент';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Плейлист переименован в «$name»';
  }

  @override
  String get snackbarPlaylistDeleted => 'Плейлист удалён';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Нет результатов для «$query»';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Этот медиаконтент уже есть в плейлисте';

  @override
  String get snackbarAddedToPlaylist => 'Добавлено в плейлист';

  @override
  String get addMediaTitle => 'Добавить медиа';

  @override
  String get searchMinCharsHint => 'Введите минимум 3 символа для поиска';

  @override
  String get badgeAdded => 'Добавлено';

  @override
  String get snackbarNotAvailableOnSource => 'Недоступно на этом источнике';

  @override
  String get errorLoadingTitle => 'Ошибка загрузки';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Ошибка загрузки плейлистов: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Очистить фильтр';

  @override
  String get homeErrorSwipeToRetry =>
      'Произошла ошибка. Потяните вниз, чтобы повторить.';

  @override
  String get homeContinueWatching => 'Продолжить просмотр';

  @override
  String get homeNoIptvSources =>
      'Нет активного источника IPTV. Добавьте источник в Настройках, чтобы увидеть категории.';

  @override
  String get homeNoTrends => 'Нет доступного трендового контента';

  @override
  String get actionRefreshMetadata => 'Обновить метаданные';

  @override
  String get actionChangeMetadata => 'Изменить метаданные';

  @override
  String get actionAddToList => 'Добавить в список';

  @override
  String get metadataRefreshed => 'Метаданные обновлены';

  @override
  String get errorRefreshingMetadata => 'Ошибка обновления метаданных';

  @override
  String get actionMarkSeen => 'Отметить как просмотренное';

  @override
  String get actionMarkUnseen => 'Отметить как непросмотренное';

  @override
  String get actionReportProblem => 'Сообщить о проблеме';

  @override
  String get featureComingSoon => 'Скоро будет доступно';

  @override
  String get subtitlesMenuTitle => 'Субтитры';

  @override
  String get audioMenuTitle => 'Аудио';

  @override
  String get videoFitModeMenuTitle => 'Режим отображения';

  @override
  String get videoFitModeContain => 'Оригинальные пропорции';

  @override
  String get videoFitModeCover => 'Заполнить экран';

  @override
  String get actionDisable => 'Отключить';

  @override
  String defaultTrackLabel(String id) {
    return 'Дорожка $id';
  }

  @override
  String get controlRewind10 => '10 с';

  @override
  String get controlRewind30 => '30 с';

  @override
  String get controlForward10 => '+ 10 с';

  @override
  String get controlForward30 => '+ 30 с';

  @override
  String get actionNextEpisode => 'Следующий эпизод';

  @override
  String get actionRestart => 'Начать заново';

  @override
  String get errorSeriesDataUnavailable =>
      'Не удалось загрузить данные сериала';

  @override
  String get errorNextEpisodeFailed => 'Не удалось определить следующий эпизод';

  @override
  String get actionLoadMore => 'Загрузить ещё';

  @override
  String get iptvServerUrlLabel => 'URL сервера';

  @override
  String get iptvServerUrlHint => 'URL сервера Xtream';

  @override
  String get iptvPasswordLabel => 'Пароль';

  @override
  String get iptvPasswordHint => 'Пароль Xtream';

  @override
  String get actionConnect => 'Подключиться';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Обновить плейлисты IPTV';

  @override
  String get activeSourceTitle => 'Активный источник';

  @override
  String get statusActive => 'Активен';

  @override
  String get statusNoActiveSource => 'Нет активного источника';

  @override
  String get overlayPreparingHome => 'Подготовка главной…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Загрузка фильмов и сериалов…';

  @override
  String get overlayLoadingCategories => 'Загрузка категорий…';

  @override
  String get bootstrapRefreshing => 'Обновление списков IPTV…';

  @override
  String get bootstrapEnriching => 'Подготовка метаданных…';

  @override
  String get errorPrepareHome => 'Не удалось подготовить главную страницу';

  @override
  String get overlayOpeningHome => 'Открытие главной…';

  @override
  String get overlayRefreshingIptvLists => 'Обновление списков IPTV…';

  @override
  String get overlayPreparingMetadata => 'Подготовка метаданных…';

  @override
  String get errorHomeLoadTimeout => 'Таймаут загрузки главной';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Имя пользователя';

  @override
  String get iptvUsernameHint => 'Имя пользователя Xtream';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionSeeAll => 'Показать всё';

  @override
  String get actionExpand => 'Развернуть';

  @override
  String get actionCollapse => 'Свернуть';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Поиск в $provider…';
  }

  @override
  String get actionClearHistory => 'Очистить историю';

  @override
  String get castTitle => 'Актёры';

  @override
  String get recommendationsTitle => 'Рекомендации';

  @override
  String get libraryHeader => 'Ваша библиотека';

  @override
  String get libraryDataInfo =>
      'Данные будут отображаться после реализации слоя data/domain.';

  @override
  String get libraryEmpty =>
      'Поставьте лайк фильмам, сериалам или актёрам, чтобы они появились здесь.';

  @override
  String get serie => 'Сериалы';

  @override
  String get recherche => 'Поиск';

  @override
  String get notYetAvailable => 'Пока недоступно';

  @override
  String get createPlaylistTitle => 'Создать плейлист';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get addMedia => 'Добавить медиа';

  @override
  String get renamePlaylist => 'Переименовать';

  @override
  String get deletePlaylist => 'Удалить';

  @override
  String get pinPlaylist => 'Закрепить';

  @override
  String get unpinPlaylist => 'Открепить';

  @override
  String get playlistPinned => 'Плейлист закреплён';

  @override
  String get playlistUnpinned => 'Плейлист откреплён';

  @override
  String get playlistDeleted => 'Плейлист удалён';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Плейлист «$name» создан';
  }

  @override
  String playlistCreateError(String error) {
    return 'Ошибка создания плейлиста: $error';
  }

  @override
  String get addedToPlaylist => 'Добавлено';

  @override
  String get pinRecoveryLink => 'Восстановить PIN-код';

  @override
  String get pinRecoveryTitle => 'Восстановить PIN-код';

  @override
  String get pinRecoveryDescription =>
      'Восстановите PIN-код для защищённого профиля.';

  @override
  String get pinRecoveryRequestCodeButton => 'Send code';

  @override
  String get pinRecoveryCodeSentHint =>
      'Code sent to your account email. Check your messages and enter it below.';

  @override
  String get pinRecoveryComingSoon => 'Эта функция скоро появится.';

  @override
  String get pinRecoveryNotAvailable =>
      'PIN recovery by email is currently unavailable.';

  @override
  String get pinRecoveryCodeLabel => 'Код восстановления';

  @override
  String get pinRecoveryCodeHint => '8 цифр';

  @override
  String get pinRecoveryVerifyButton => 'Проверить';

  @override
  String get pinRecoveryCodeInvalid => 'Введите 8-значный код';

  @override
  String get pinRecoveryCodeExpired => 'Код восстановления истёк';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Слишком много попыток. Попробуйте позже.';

  @override
  String get pinRecoveryUnknownError => 'Произошла непредвиденная ошибка';

  @override
  String get pinRecoveryNewPinLabel => 'Новый PIN';

  @override
  String get pinRecoveryNewPinHint => '4–6 цифр';

  @override
  String get pinRecoveryConfirmPinLabel => 'Подтвердить PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Повторите PIN';

  @override
  String get pinRecoveryResetButton => 'Обновить PIN';

  @override
  String get pinRecoveryPinInvalid => 'Введите PIN длиной от 4 до 6 цифр';

  @override
  String get pinRecoveryPinMismatch => 'PIN-коды не совпадают';

  @override
  String get pinRecoveryResetSuccess => 'PIN обновлён';

  @override
  String get profilePinSaved => 'PIN saved.';

  @override
  String get profilePinEditLabel => 'Edit PIN code';

  @override
  String get settingsAccountsSection => 'Аккаунты';

  @override
  String get settingsIptvSection => 'Настройки IPTV';

  @override
  String get settingsSourcesManagement => 'Управление источниками';

  @override
  String get settingsSyncFrequency => 'Частота обновления';

  @override
  String get settingsAppSection => 'Настройки приложения';

  @override
  String get settingsAccentColor => 'Акцентный цвет';

  @override
  String get settingsPlaybackSection => 'Настройки воспроизведения';

  @override
  String get settingsPreferredAudioLanguage => 'Предпочитаемый язык';

  @override
  String get settingsPreferredSubtitleLanguage => 'Предпочитаемые субтитры';

  @override
  String get libraryPlaylistsFilter => 'Плейлисты';

  @override
  String get librarySagasFilter => 'Саги';

  @override
  String get libraryArtistsFilter => 'Артисты';

  @override
  String get librarySearchPlaceholder => 'Поиск в моей библиотеке…';

  @override
  String get libraryInProgress => 'В процессе';

  @override
  String get libraryFavoriteMovies => 'Любимые фильмы';

  @override
  String get libraryFavoriteSeries => 'Любимые сериалы';

  @override
  String get libraryWatchHistory => 'История просмотров';

  @override
  String libraryItemCountPlural(int count) {
    return '$count элементов';
  }

  @override
  String get searchPeopleTitle => 'Люди';

  @override
  String get searchSagasTitle => 'Саги';

  @override
  String get searchByProvidersTitle => 'По провайдерам';

  @override
  String get searchByGenresTitle => 'По жанрам';

  @override
  String get personRoleActor => 'Актёр';

  @override
  String get personRoleDirector => 'Режиссёр';

  @override
  String get personRoleCreator => 'Создатель';

  @override
  String get tvDistribution => 'Актёры';

  @override
  String tvSeasonLabel(int number) {
    return 'Сезон $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Нет доступных эпизодов';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Продолжить S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Открыть страницу';

  @override
  String get sagaStartNow => 'Начать сейчас';

  @override
  String get sagaContinue => 'Продолжить';

  @override
  String sagaMovieCount(int count) {
    return '$count фильмов';
  }

  @override
  String get sagaMoviesList => 'Список фильмов';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies фильмов — $shows сериалов';
  }

  @override
  String get personPlayRandomly => 'Случайное воспроизведение';

  @override
  String get personMoviesList => 'Список фильмов';

  @override
  String get personSeriesList => 'Список сериалов';

  @override
  String get playlistPlayRandomly => 'Случайное воспроизведение';

  @override
  String get playlistAddButton => 'Добавить';

  @override
  String get playlistSortButton => 'Сортировать';

  @override
  String get playlistSortByTitle => 'Сортировать по';

  @override
  String get playlistSortByTitleOption => 'Название';

  @override
  String get playlistSortRecentAdditions => 'Недавние добавления';

  @override
  String get playlistSortOldestFirst => 'Сначала старые';

  @override
  String get playlistSortNewestFirst => 'Сначала новые';

  @override
  String get playlistEmptyMessage => 'В этом плейлисте нет элементов';

  @override
  String playlistItemCount(int count) {
    return '$count элемент';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count элементов';
  }

  @override
  String get playlistSeasonSingular => 'сезон';

  @override
  String get playlistSeasonPlural => 'сезонов';

  @override
  String get playlistRenameTitle => 'Переименовать плейлист';

  @override
  String get playlistNamePlaceholder => 'Название плейлиста';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Плейлист переименован в «$name»';
  }

  @override
  String get playlistDeleteTitle => 'Удалить';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String get playlistDeletedSuccess => 'Плейлист удалён';

  @override
  String get playlistItemRemovedSuccess => 'Элемент удалён';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Удалить «$title» из плейлиста?';
  }

  @override
  String get categoryLoadFailed => 'Не удалось загрузить категорию.';

  @override
  String get categoryEmpty => 'В этой категории нет элементов.';

  @override
  String get categoryLoadingMore => 'Загрузка ещё…';

  @override
  String get movieNoPlaylistsAvailable => 'Нет доступного плейлиста';

  @override
  String playlistAddedTo(String title) {
    return 'Добавлено в «$title»';
  }

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'Фильм недоступен в плейлисте';

  @override
  String errorPlaybackFailed(String message) {
    return 'Ошибка воспроизведения: $message';
  }

  @override
  String get movieNoMedia => 'Нет медиа для отображения';

  @override
  String get personNoData => 'Нет данных для отображения.';

  @override
  String get personGenericError =>
      'Произошла ошибка при загрузке этого человека.';

  @override
  String get personBiographyTitle => 'Биография';

  @override
  String get authOtpTitle => 'Войти';

  @override
  String get authOtpSubtitle =>
      'Введите email и 8‑значный код, который мы вам отправим.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp =>
      'Мы отправим 8‑значный код. При необходимости проверьте спам.';

  @override
  String get authOtpCodeLabel => 'Код подтверждения';

  @override
  String get authOtpCodeHint => '8‑значный код';

  @override
  String get authOtpCodeHelp => 'Введите 8‑значный код, полученный по email.';

  @override
  String get authOtpPrimarySend => 'Отправить код';

  @override
  String get authOtpPrimarySubmit => 'Войти';

  @override
  String get authOtpResend => 'Отправить код снова';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Повторная отправка через $seconds с';
  }

  @override
  String get authOtpChangeEmail => 'Изменить email';

  @override
  String get resumePlayback => 'Продолжить воспроизведение';

  @override
  String get settingsCloudSyncSection => 'Облачная синхронизация';

  @override
  String get settingsCloudSyncAuto => 'Автосинхронизация';

  @override
  String get settingsCloudSyncNow => 'Синхронизировать сейчас';

  @override
  String get settingsCloudSyncInProgress => 'Синхронизация…';

  @override
  String get settingsCloudSyncNever => 'Никогда';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Последняя ошибка: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity не найден(о)';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity не найден(о): $error';
  }

  @override
  String get entityProvider => 'Провайдер';

  @override
  String get entityGenre => 'Жанр';

  @override
  String get entityPlaylist => 'Плейлист';

  @override
  String get entitySource => 'Источник';

  @override
  String get entityMovie => 'Фильм';

  @override
  String get entitySeries => 'Сериал';

  @override
  String get entityPerson => 'Человек';

  @override
  String get entitySaga => 'Сага';

  @override
  String get entityVideo => 'Видео';

  @override
  String get entityRoute => 'Маршрут';

  @override
  String get errorTimeoutLoading => 'Истекло время ожидания загрузки';

  @override
  String get parentalContentRestricted => 'Ограниченный контент';

  @override
  String get parentalContentRestrictedDefault =>
      'Этот контент заблокирован родительским контролем профиля.';

  @override
  String get parentalReasonTooYoung =>
      'Для этого контента требуется возраст выше лимита профиля.';

  @override
  String get parentalReasonUnknownRating =>
      'Возрастной рейтинг для этого контента недоступен.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Этот контент нельзя оценить для родительского контроля.';

  @override
  String get parentalUnlockButton => 'Разблокировать';

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
  String get hc_chargement_episodes_en_cours_33fc4ace => 'Загрузка эпизодов…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Нет доступного плейлиста. Создайте новый.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Ошибка загрузки плейлистов: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => 'Не удалось открыть ссылку';

  @override
  String get hc_qualite_preferee_776dbeea => 'Предпочитаемое качество';

  @override
  String get hc_annuler_49ba3292 => 'Отмена';

  @override
  String get hc_deconnexion_903dca17 => 'Выйти';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Ошибка выхода: \$e';

  @override
  String get hc_choisir_b030d590 => 'Выбрать';

  @override
  String get hc_avantages_08d7f47c => 'Преимущества';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Сообщение отправлено. Спасибо.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Позже';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Перезапустить сейчас';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Использовать этот источник?';

  @override
  String get hc_utiliser_fb5e43ce => 'Использовать';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Источник добавлен';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Заблокированные настройки';

  @override
  String get hc_compte_cloud_2812b31e => 'Облачный аккаунт';

  @override
  String get hc_se_connecter_fedf2439 => 'Войти';

  @override
  String get hc_propos_5345add5 => 'О приложении';

  @override
  String get hc_politique_confidentialite_42b0e51e =>
      'Политика конфиденциальности';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Условия использования';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Сохранённые источники';

  @override
  String get hc_rafraichir_be30b7d1 => 'Обновить';

  @override
  String get hc_activer_une_source_749ced38 => 'Активировать источник';

  @override
  String get hc_nom_source_9a3e4156 => 'Название источника';

  @override
  String get hc_mon_iptv_b239352c => 'Мой IPTV';

  @override
  String get hc_username_84c29015 => 'Имя пользователя';

  @override
  String get hc_password_8be3c943 => 'Пароль';

  @override
  String get hc_server_url_1d5d1eff => 'URL сервера';

  @override
  String get hc_verification_pin_e17c8fe0 => 'Проверка PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'Установить PIN';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'Предложение подписки не найдено: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'Покупка подписки была отменена пользователем.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'Операция магазина превысила таймаут: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 =>
      'HTTP-ошибка во время handshake';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Не‑JSON ответ от сервера Xtream';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'Некорректный ответ от сервера Xtream';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      'Недоступно на этом источнике';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Источник удалён';

  @override
  String get hc_source_modifiee_335ef502 => 'Источник изменён';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'Установить PIN-код';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Отметить как непросмотренное';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Вы действительно хотите выйти?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Для облачной синхронизации нужен Movi Premium.';

  @override
  String get hc_auto_c614ba7c => 'Авто';

  @override
  String get hc_organiser_838a7e57 => 'Упорядочить';

  @override
  String get hc_modifier_f260e757 => 'Изменить';

  @override
  String get hc_ajouter_87c57ed1 => 'Добавить';

  @override
  String get hc_source_active_e571305e => 'Активный источник';

  @override
  String get hc_autres_sources_e32592a6 => 'Другие источники';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Функция жалобы недоступна для этого контента.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Защита контента';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Проверка возрастных рейтингов…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Показать всё';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Сообщить о проблеме';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Если этот контент не подходит и был доступен несмотря на ограничения, кратко опишите проблему.';

  @override
  String get hc_envoyer_e9ce243b => 'Отправить';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Детский профиль создан';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Создан детский профиль. Чтобы защитить приложение и предварительно загрузить возрастные рейтинги, рекомендуется перезапустить приложение.';

  @override
  String get hc_pseudo_4cf966c0 => 'Никнейм';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Детский профиль';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Возрастной лимит';

  @override
  String get hc_code_pin_e79c48bd => 'PIN-код';

  @override
  String get hc_changer_code_pin_3b069731 => 'Изменить PIN-код';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'Удалить PIN-код';

  @override
  String get hc_supprimer_pin_51850c7b => 'Удалить PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'Удалить';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Требует PIN и включает фильтр PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Активировать этот источник сейчас?';

  @override
  String get hc_application_b291beb8 => 'Приложение';

  @override
  String get hc_version_1_0_0_347e553c => 'Версия 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Благодарности';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Этот продукт использует TMDB API, но не одобрен и не сертифицирован TMDB.';

  @override
  String get hc_verification_targets_d51632f8 => 'Цели проверки';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 => 'Переход должен «съедать» кадр';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 =>
      'Неверный Xtream streamId: ...';

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
  String get hc_url_invalide_aa227a66 => 'Неверный URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Обновить\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Меню\'';

  @override
  String get hc_retour_e5befb1f => 'Назад';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Больше действий\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Больше действий';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c => 'semanticLabel: \'Поиск\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'Добавить\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Выйти';

  @override
  String get dialogSignOutBody => 'Вы уверены, что хотите выйти?';

  @override
  String get settingsUnableToOpenLink => 'Не удалось открыть ссылку';

  @override
  String get settingsSyncDisabled => 'Отключено';

  @override
  String get settingsSyncEveryHour => 'Каждый час';

  @override
  String get settingsSyncEvery2Hours => 'Каждые 2 часа';

  @override
  String get settingsSyncEvery4Hours => 'Каждые 4 часа';

  @override
  String get settingsSyncEvery6Hours => 'Каждые 6 часов';

  @override
  String get settingsSyncEveryDay => 'Каждый день';

  @override
  String get settingsSyncEvery2Days => 'Каждые 2 дня';

  @override
  String get settingsColorCustom => 'Свой';

  @override
  String get settingsColorBlue => 'Синий';

  @override
  String get settingsColorPink => 'Розовый';

  @override
  String get settingsColorGreen => 'Зелёный';

  @override
  String get settingsColorPurple => 'Фиолетовый';

  @override
  String get settingsColorOrange => 'Оранжевый';

  @override
  String get settingsColorTurquoise => 'Бирюзовый';

  @override
  String get settingsColorYellow => 'Жёлтый';

  @override
  String get settingsColorIndigo => 'Индиго';

  @override
  String get settingsCloudAccountTitle => 'Облачный аккаунт';

  @override
  String get settingsAccountConnected => 'Подключено';

  @override
  String get settingsAccountLocalMode => 'Локальный режим';

  @override
  String get settingsAccountCloudUnavailable => 'Облако недоступно';

  @override
  String get settingsSubtitlesTitle => 'Субтитры';

  @override
  String get settingsSubtitlesSizeTitle => 'Размер текста';

  @override
  String get settingsSubtitlesColorTitle => 'Цвет текста';

  @override
  String get settingsSubtitlesFontTitle => 'Шрифт';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Системный';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Быстрые настройки';

  @override
  String get settingsSubtitlesPreviewTitle => 'Предпросмотр';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Это предпросмотр субтитров.\nНастройте читаемость в реальном времени.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Фон';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Непрозрачность фона';

  @override
  String get settingsSubtitlesShadowTitle => 'Тень';

  @override
  String get settingsSubtitlesShadowOff => 'Выкл';

  @override
  String get settingsSubtitlesShadowSoft => 'Мягкая';

  @override
  String get settingsSubtitlesShadowStrong => 'Сильная';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Точная настройка размера';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Масштаб';

  @override
  String get settingsSubtitlesResetDefaults => 'Сбросить по умолчанию';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Расширенный стиль субтитров (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Фон, непрозрачность, пресеты тени и тонкая настройка размера доступны в Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Открыть с Premium';

  @override
  String get settingsSyncSectionTitle => 'Синхронизация аудио/субтитров';

  @override
  String get settingsSubtitleOffsetTitle => 'Смещение субтитров';

  @override
  String get settingsAudioOffsetTitle => 'Смещение аудио';

  @override
  String get settingsOffsetUnsupported =>
      'Не поддерживается этим backend или платформой.';

  @override
  String get settingsSyncResetOffsets => 'Сбросить смещения синхронизации';

  @override
  String get aboutTmdbDisclaimer =>
      'Этот продукт использует API TMDB, но не одобрен и не сертифицирован TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Благодарности';
}
