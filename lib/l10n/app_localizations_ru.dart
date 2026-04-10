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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count результата)',
      many: '($count результатов)',
      few: '($count результата)',
      one: '($count результат)',
    );
    return '$_temp0';
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
    return 'Искать в $provider';
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
  String get pinRecoveryLink => 'Восстановить PIN';

  @override
  String get pinRecoveryTitle => 'Восстановить PIN';

  @override
  String get pinRecoveryDescription =>
      'Мы отправим 8-значный код на адрес электронной почты вашей учётной записи, чтобы вы могли сбросить PIN этого профиля.';

  @override
  String get pinRecoveryRequestCodeButton => 'Отправить код';

  @override
  String get pinRecoveryCodeSentHint =>
      'Код отправлен на электронную почту вашей учётной записи. Проверьте сообщения и введите его ниже.';

  @override
  String get pinRecoveryComingSoon => 'Эта функция скоро появится.';

  @override
  String get pinRecoveryNotAvailable =>
      'Восстановление PIN-кода по электронной почте сейчас недоступно.';

  @override
  String get pinRecoveryCodeLabel => 'Код восстановления';

  @override
  String get pinRecoveryCodeHint => '8 цифр';

  @override
  String get pinRecoveryVerifyButton => 'Проверить код';

  @override
  String get pinRecoveryCodeInvalid => 'Введите 8-значный код восстановления';

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
  String get pinRecoveryResetButton => 'Сбросить PIN';

  @override
  String get pinRecoveryPinInvalid => 'Введите PIN длиной от 4 до 6 цифр';

  @override
  String get pinRecoveryPinMismatch => 'PIN-коды не совпадают';

  @override
  String get pinRecoveryResetSuccess => 'PIN сброшен';

  @override
  String get profilePinSaved => 'PIN-код сохранён.';

  @override
  String get profilePinEditLabel => 'Изменить PIN-код';

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
  String get settingsPreferredAudioLanguage => 'Предпочитаемый язык аудио';

  @override
  String get settingsPreferredSubtitleLanguage =>
      'Предпочитаемый язык субтитров';

  @override
  String get libraryPlaylistsFilter => 'Плейлисты';

  @override
  String get librarySagasFilter => 'Саги';

  @override
  String get libraryArtistsFilter => 'Артисты';

  @override
  String get librarySearchPlaceholder => 'Поиск в моей библиотеке…';

  @override
  String get libraryInProgress => 'Продолжить просмотр';

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
    return 'Продолжить просмотр S$season · E$episode';
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
  String get playlistAddButton => 'Добавить в плейлист';

  @override
  String get playlistSortButton => 'Сортировать';

  @override
  String get playlistSortByTitle => 'Сортировать по';

  @override
  String get playlistSortByTitleOption => 'Название';

  @override
  String get playlistSortRecentAdditions => 'Недавно добавленные';

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
  String get playlistDeleteTitle => 'Удалить плейлист';

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
      'Введите email и 8-значный код, который мы вам отправим.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'name@example.com';

  @override
  String get authOtpEmailHelp =>
      'Мы отправим 8‑значный код. При необходимости проверьте спам.';

  @override
  String get authOtpCodeLabel => 'Код подтверждения';

  @override
  String get authOtpCodeHint => '8‑значный код';

  @override
  String get authOtpCodeHelp =>
      'Введите 8-значный код, полученный по электронной почте.';

  @override
  String get authOtpPrimarySend => 'Отправить код';

  @override
  String get authOtpPrimarySubmit => 'Войти';

  @override
  String get authOtpResend => 'Отправить код снова';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Повторная отправка кода через $seconds с';
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
      'Не поддерживается этим сервером или платформой.';

  @override
  String get settingsSyncResetOffsets => 'Сбросить смещения синхронизации';

  @override
  String get aboutTmdbDisclaimer =>
      'Этот продукт использует API TMDB, но не одобрен и не сертифицирован TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Благодарности';

  @override
  String get actionSend => 'Отправить';

  @override
  String get profilePinSetLabel => 'Установить PIN-код';

  @override
  String get reportingProblemSentConfirmation =>
      'Сообщение отправлено. Спасибо.';

  @override
  String get reportingProblemBody =>
      'Если этот контент не подходит и был доступен несмотря на ограничения, кратко опишите проблему.';

  @override
  String get reportingProblemExampleHint =>
      'Пример: фильм ужасов доступен несмотря на PEGI 12';

  @override
  String get settingsAutomaticOption => 'Авто';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Предпочтительное качество воспроизведения';

  @override
  String settingsSignOutError(String error) {
    return 'Ошибка при выходе: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Условия использования';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Для облачной синхронизации нужен Movi Premium.';
}
