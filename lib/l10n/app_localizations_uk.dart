// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get welcomeTitle => 'Ласкаво просимо!';

  @override
  String get welcomeSubtitle =>
      'Заповніть уподобання, щоб персоналізувати Movi.';

  @override
  String get labelUsername => 'Нікнейм';

  @override
  String get labelPreferredLanguage => 'Бажана мова';

  @override
  String get actionContinue => 'Продовжити';

  @override
  String get hintUsername => 'Ваш нікнейм';

  @override
  String get errorFillFields => 'Будь ласка, коректно заповніть поля.';

  @override
  String get homeWatchNow => 'Дивитися';

  @override
  String get welcomeSourceTitle => 'Ласкаво просимо!';

  @override
  String get welcomeSourceSubtitle =>
      'Додайте джерело, щоб персоналізувати ваш досвід у Movi.';

  @override
  String get welcomeSourceAdd => 'Додати джерело';

  @override
  String get searchTitle => 'Пошук';

  @override
  String get searchHint => 'Введіть запит';

  @override
  String get clear => 'Очистити';

  @override
  String get moviesTitle => 'Фільми';

  @override
  String get seriesTitle => 'Серіали';

  @override
  String get noResults => 'Немає результатів';

  @override
  String get historyTitle => 'Історія';

  @override
  String get historyEmpty => 'Немає нещодавніх пошуків';

  @override
  String get delete => 'Видалити';

  @override
  String resultsCount(int count) {
    return '($count результатів)';
  }

  @override
  String get errorUnknown => 'Невідома помилка';

  @override
  String errorConnectionFailed(String error) {
    return 'Не вдалося підключитися: $error';
  }

  @override
  String get errorConnectionGeneric => 'Не вдалося підключитися';

  @override
  String get validationRequired => 'Обовʼязково';

  @override
  String get validationInvalidUrl => 'Недійсний URL';

  @override
  String get snackbarSourceAddedBackground =>
      'Джерело IPTV додано. Синхронізація у фоновому режимі…';

  @override
  String get snackbarSourceAddedSynced =>
      'Джерело IPTV додано та синхронізовано';

  @override
  String get navHome => 'Головна';

  @override
  String get navSearch => 'Пошук';

  @override
  String get navLibrary => 'Бібліотека';

  @override
  String get navSettings => 'Налаштування';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsLanguageLabel => 'Мова застосунку';

  @override
  String get settingsGeneralTitle => 'Загальні налаштування';

  @override
  String get settingsDarkModeTitle => 'Темна тема';

  @override
  String get settingsDarkModeSubtitle => 'Увімкніть тему, зручну для ночі.';

  @override
  String get settingsNotificationsTitle => 'Сповіщення';

  @override
  String get settingsNotificationsSubtitle =>
      'Отримуйте сповіщення про нові релізи.';

  @override
  String get settingsAccountTitle => 'Обліковий запис';

  @override
  String get settingsProfileInfoTitle => 'Інформація профілю';

  @override
  String get settingsProfileInfoSubtitle => 'Імʼя, аватар, налаштування';

  @override
  String get settingsAboutTitle => 'Про застосунок';

  @override
  String get settingsLegalMentionsTitle => 'Юридична інформація';

  @override
  String get settingsPrivacyPolicyTitle => 'Політика конфіденційності';

  @override
  String get actionCancel => 'Скасувати';

  @override
  String get actionConfirm => 'Підтвердити';

  @override
  String get actionRetry => 'Повторити';

  @override
  String get settingsHelpDiagnosticsSection => 'Допомога та діагностика';

  @override
  String get settingsExportErrorLogs => 'Експорт журналів помилок';

  @override
  String get diagnosticsExportTitle => 'Експорт журналів помилок';

  @override
  String get diagnosticsExportDescription =>
      'Діагностика містить лише нещодавні логи WARN/ERROR та хешовані ідентифікатори облікового запису/профілю (якщо ввімкнено). Ключі/токени не мають зʼявлятися.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Додавати ідентифікатори облікового запису/профілю (хешовані)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Допомагає співставити баг, не розкриваючи первинний ID.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Діагностику скопійовано в буфер обміну.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Діагностику збережено: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Копіювати';

  @override
  String get diagnosticsActionSave => 'Зберегти';

  @override
  String get actionChangeVersion => 'Змінити версію';

  @override
  String get semanticsBack => 'Назад';

  @override
  String get semanticsMoreActions => 'Більше дій';

  @override
  String get snackbarLoadingPlaylists => 'Завантаження плейлистів…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Немає доступного плейлиста. Створіть новий.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Помилка додавання до плейлиста: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'Цей медіаконтент уже є в цьому плейлисті';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Помилка завантаження плейлистів: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Скарга/звіт недоступні для цього контенту.';

  @override
  String get snackbarLoadingEpisodes => 'Завантаження епізодів…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Епізод недоступний у плейлисті';

  @override
  String snackbarGenericError(String error) {
    return 'Помилка: $error';
  }

  @override
  String get snackbarLoading => 'Завантаження…';

  @override
  String get snackbarNoVersionAvailable => 'Немає доступної версії';

  @override
  String get snackbarVersionSaved => 'Версію збережено';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Версія $index';
  }

  @override
  String get actionReadMore => 'Докладніше';

  @override
  String get actionShowLess => 'Згорнути';

  @override
  String get actionViewPage => 'Відкрити сторінку';

  @override
  String get semanticsSeeSagaPage => 'Відкрити сторінку саги';

  @override
  String get libraryTypeSaga => 'Сага';

  @override
  String get libraryTypeInProgress => 'У процесі';

  @override
  String get libraryTypeFavoriteMovies => 'Улюблені фільми';

  @override
  String get libraryTypeFavoriteSeries => 'Улюблені серіали';

  @override
  String get libraryTypeHistory => 'Історія';

  @override
  String get libraryTypePlaylist => 'Плейлист';

  @override
  String get libraryTypeArtist => 'Артист';

  @override
  String libraryItemCount(int count) {
    return '$count елемент';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Плейлист перейменовано на «$name»';
  }

  @override
  String get snackbarPlaylistDeleted => 'Плейлист видалено';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Видалити «$title»?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Немає результатів для «$query»';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Помилка: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Цей медіаконтент уже є в плейлисті';

  @override
  String get snackbarAddedToPlaylist => 'Додано до плейлиста';

  @override
  String get addMediaTitle => 'Додати медіа';

  @override
  String get searchMinCharsHint => 'Введіть щонайменше 3 символи для пошуку';

  @override
  String get badgeAdded => 'Додано';

  @override
  String get snackbarNotAvailableOnSource => 'Недоступно для цього джерела';

  @override
  String get errorLoadingTitle => 'Помилка завантаження';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Помилка завантаження: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Помилка завантаження плейлистів: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Очистити фільтр';

  @override
  String get homeErrorSwipeToRetry =>
      'Сталася помилка. Потягніть униз, щоб повторити.';

  @override
  String get homeContinueWatching => 'Продовжити перегляд';

  @override
  String get homeNoIptvSources =>
      'Немає активного джерела IPTV. Додайте джерело в Налаштуваннях, щоб побачити категорії.';

  @override
  String get homeNoTrends => 'Немає доступного трендового контенту';

  @override
  String get actionRefreshMetadata => 'Оновити метадані';

  @override
  String get actionChangeMetadata => 'Змінити метадані';

  @override
  String get actionAddToList => 'Додати до списку';

  @override
  String get metadataRefreshed => 'Метадані оновлено';

  @override
  String get errorRefreshingMetadata => 'Помилка оновлення метаданих';

  @override
  String get actionMarkSeen => 'Позначити як переглянуте';

  @override
  String get actionMarkUnseen => 'Позначити як непереглянуте';

  @override
  String get actionReportProblem => 'Повідомити про проблему';

  @override
  String get featureComingSoon => 'Незабаром';

  @override
  String get subtitlesMenuTitle => 'Субтитри';

  @override
  String get audioMenuTitle => 'Аудіо';

  @override
  String get videoFitModeMenuTitle => 'Режим відображення';

  @override
  String get videoFitModeContain => 'Оригінальні пропорції';

  @override
  String get videoFitModeCover => 'Заповнити екран';

  @override
  String get actionDisable => 'Вимкнути';

  @override
  String defaultTrackLabel(String id) {
    return 'Доріжка $id';
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
  String get actionNextEpisode => 'Наступний епізод';

  @override
  String get actionRestart => 'Почати спочатку';

  @override
  String get errorSeriesDataUnavailable =>
      'Не вдалося завантажити дані серіалу';

  @override
  String get errorNextEpisodeFailed => 'Не вдалося визначити наступний епізод';

  @override
  String get actionLoadMore => 'Завантажити ще';

  @override
  String get iptvServerUrlLabel => 'URL сервера';

  @override
  String get iptvServerUrlHint => 'URL сервера Xtream';

  @override
  String get iptvPasswordLabel => 'Пароль';

  @override
  String get iptvPasswordHint => 'Пароль Xtream';

  @override
  String get actionConnect => 'Підключитися';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Оновити плейлисти IPTV';

  @override
  String get activeSourceTitle => 'Активне джерело';

  @override
  String get statusActive => 'Активний';

  @override
  String get statusNoActiveSource => 'Немає активного джерела';

  @override
  String get overlayPreparingHome => 'Підготовка головної…';

  @override
  String get overlayLoadingMoviesAndSeries =>
      'Завантаження фільмів і серіалів…';

  @override
  String get overlayLoadingCategories => 'Завантаження категорій…';

  @override
  String get bootstrapRefreshing => 'Оновлення списків IPTV…';

  @override
  String get bootstrapEnriching => 'Підготовка метаданих…';

  @override
  String get errorPrepareHome => 'Не вдалося підготувати головну сторінку';

  @override
  String get overlayOpeningHome => 'Відкриття головної…';

  @override
  String get overlayRefreshingIptvLists => 'Оновлення списків IPTV…';

  @override
  String get overlayPreparingMetadata => 'Підготовка метаданих…';

  @override
  String get errorHomeLoadTimeout => 'Таймаут завантаження головної';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Імʼя користувача';

  @override
  String get iptvUsernameHint => 'Імʼя користувача Xtream';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionSeeAll => 'Показати все';

  @override
  String get actionExpand => 'Розгорнути';

  @override
  String get actionCollapse => 'Згорнути';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Пошук у $provider…';
  }

  @override
  String get actionClearHistory => 'Очистити історію';

  @override
  String get castTitle => 'Актори';

  @override
  String get recommendationsTitle => 'Рекомендації';

  @override
  String get libraryHeader => 'Ваша бібліотека';

  @override
  String get libraryDataInfo =>
      'Дані будуть відображені після реалізації шару data/domain.';

  @override
  String get libraryEmpty =>
      'Лайкніть фільми, серіали або акторів, щоб вони зʼявилися тут.';

  @override
  String get serie => 'Серіали';

  @override
  String get recherche => 'Пошук';

  @override
  String get notYetAvailable => 'Поки недоступно';

  @override
  String get createPlaylistTitle => 'Створити плейлист';

  @override
  String get playlistName => 'Назва плейлиста';

  @override
  String get addMedia => 'Додати медіа';

  @override
  String get renamePlaylist => 'Перейменувати';

  @override
  String get deletePlaylist => 'Видалити';

  @override
  String get pinPlaylist => 'Закріпити';

  @override
  String get unpinPlaylist => 'Відкріпити';

  @override
  String get playlistPinned => 'Плейлист закріплено';

  @override
  String get playlistUnpinned => 'Плейлист відкріплено';

  @override
  String get playlistDeleted => 'Плейлист видалено';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Плейлист «$name» створено';
  }

  @override
  String playlistCreateError(String error) {
    return 'Помилка створення плейлиста: $error';
  }

  @override
  String get addedToPlaylist => 'Додано';

  @override
  String get pinRecoveryLink => 'Відновити PIN-код';

  @override
  String get pinRecoveryTitle => 'Відновити PIN-код';

  @override
  String get pinRecoveryDescription =>
      'Відновіть PIN-код для захищеного профілю.';

  @override
  String get pinRecoveryComingSoon => 'Ця функція скоро зʼявиться.';

  @override
  String get pinRecoveryCodeLabel => 'Код відновлення';

  @override
  String get pinRecoveryCodeHint => '8 цифр';

  @override
  String get pinRecoveryVerifyButton => 'Перевірити';

  @override
  String get pinRecoveryCodeInvalid => 'Введіть 8-значний код';

  @override
  String get pinRecoveryCodeExpired => 'Код відновлення прострочено';

  @override
  String get pinRecoveryTooManyAttempts => 'Забагато спроб. Спробуйте пізніше.';

  @override
  String get pinRecoveryUnknownError => 'Сталася неочікувана помилка';

  @override
  String get pinRecoveryNewPinLabel => 'Новий PIN';

  @override
  String get pinRecoveryNewPinHint => '4–6 цифр';

  @override
  String get pinRecoveryConfirmPinLabel => 'Підтвердити PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Повторіть PIN';

  @override
  String get pinRecoveryResetButton => 'Оновити PIN';

  @override
  String get pinRecoveryPinInvalid => 'Введіть PIN від 4 до 6 цифр';

  @override
  String get pinRecoveryPinMismatch => 'PIN-коди не збігаються';

  @override
  String get pinRecoveryResetSuccess => 'PIN оновлено';

  @override
  String get settingsAccountsSection => 'Облікові записи';

  @override
  String get settingsIptvSection => 'Налаштування IPTV';

  @override
  String get settingsSourcesManagement => 'Керування джерелами';

  @override
  String get settingsSyncFrequency => 'Частота оновлення';

  @override
  String get settingsAppSection => 'Налаштування застосунку';

  @override
  String get settingsAccentColor => 'Акцентний колір';

  @override
  String get settingsPlaybackSection => 'Налаштування відтворення';

  @override
  String get settingsPreferredAudioLanguage => 'Бажана мова';

  @override
  String get settingsPreferredSubtitleLanguage => 'Бажані субтитри';

  @override
  String get libraryPlaylistsFilter => 'Плейлисти';

  @override
  String get librarySagasFilter => 'Саги';

  @override
  String get libraryArtistsFilter => 'Артисти';

  @override
  String get librarySearchPlaceholder => 'Пошук у моїй бібліотеці…';

  @override
  String get libraryInProgress => 'У процесі';

  @override
  String get libraryFavoriteMovies => 'Улюблені фільми';

  @override
  String get libraryFavoriteSeries => 'Улюблені серіали';

  @override
  String get libraryWatchHistory => 'Історія переглядів';

  @override
  String libraryItemCountPlural(int count) {
    return '$count елементів';
  }

  @override
  String get searchPeopleTitle => 'Люди';

  @override
  String get searchSagasTitle => 'Саги';

  @override
  String get searchByProvidersTitle => 'За провайдерами';

  @override
  String get searchByGenresTitle => 'За жанрами';

  @override
  String get personRoleActor => 'Актор';

  @override
  String get personRoleDirector => 'Режисер';

  @override
  String get personRoleCreator => 'Творець';

  @override
  String get tvDistribution => 'Актори';

  @override
  String tvSeasonLabel(int number) {
    return 'Сезон $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Немає доступних епізодів';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Продовжити S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Відкрити сторінку';

  @override
  String get sagaStartNow => 'Почати зараз';

  @override
  String get sagaContinue => 'Продовжити';

  @override
  String sagaMovieCount(int count) {
    return '$count фільмів';
  }

  @override
  String get sagaMoviesList => 'Список фільмів';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies фільмів — $shows серіалів';
  }

  @override
  String get personPlayRandomly => 'Випадкове відтворення';

  @override
  String get personMoviesList => 'Список фільмів';

  @override
  String get personSeriesList => 'Список серіалів';

  @override
  String get playlistPlayRandomly => 'Випадкове відтворення';

  @override
  String get playlistAddButton => 'Додати';

  @override
  String get playlistSortButton => 'Сортувати';

  @override
  String get playlistSortByTitle => 'Сортувати за';

  @override
  String get playlistSortByTitleOption => 'Назва';

  @override
  String get playlistSortRecentAdditions => 'Нещодавні додавання';

  @override
  String get playlistSortOldestFirst => 'Спочатку старі';

  @override
  String get playlistSortNewestFirst => 'Спочатку нові';

  @override
  String get playlistEmptyMessage => 'У цьому плейлисті немає елементів';

  @override
  String playlistItemCount(int count) {
    return '$count елемент';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count елементів';
  }

  @override
  String get playlistSeasonSingular => 'сезон';

  @override
  String get playlistSeasonPlural => 'сезонів';

  @override
  String get playlistRenameTitle => 'Перейменувати плейлист';

  @override
  String get playlistNamePlaceholder => 'Назва плейлиста';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Плейлист перейменовано на «$name»';
  }

  @override
  String get playlistDeleteTitle => 'Видалити';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Видалити «$title»?';
  }

  @override
  String get playlistDeletedSuccess => 'Плейлист видалено';

  @override
  String get playlistItemRemovedSuccess => 'Елемент видалено';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Видалити «$title» з плейлиста?';
  }

  @override
  String get categoryLoadFailed => 'Не вдалося завантажити категорію.';

  @override
  String get categoryEmpty => 'У цій категорії немає елементів.';

  @override
  String get categoryLoadingMore => 'Завантаження ще…';

  @override
  String get movieNoPlaylistsAvailable => 'Немає доступного плейлиста';

  @override
  String playlistAddedTo(String title) {
    return 'Додано до «$title»';
  }

  @override
  String errorWithMessage(String message) {
    return 'Помилка: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'Фільм недоступний у плейлисті';

  @override
  String errorPlaybackFailed(String message) {
    return 'Помилка відтворення: $message';
  }

  @override
  String get movieNoMedia => 'Немає медіа для показу';

  @override
  String get personNoData => 'Немає даних для показу.';

  @override
  String get personGenericError =>
      'Сталася помилка під час завантаження цієї людини.';

  @override
  String get personBiographyTitle => 'Біографія';

  @override
  String get authOtpTitle => 'Увійти';

  @override
  String get authOtpSubtitle =>
      'Введіть email та 8‑значний код, який ми вам надішлемо.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp =>
      'Ми надішлемо 8‑значний код. За потреби перевірте спам.';

  @override
  String get authOtpCodeLabel => 'Код підтвердження';

  @override
  String get authOtpCodeHint => '8‑значний код';

  @override
  String get authOtpCodeHelp => 'Введіть 8‑значний код, отриманий на email.';

  @override
  String get authOtpPrimarySend => 'Надіслати код';

  @override
  String get authOtpPrimarySubmit => 'Увійти';

  @override
  String get authOtpResend => 'Надіслати код ще раз';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Надіслати знову через $seconds с';
  }

  @override
  String get authOtpChangeEmail => 'Змінити email';

  @override
  String get resumePlayback => 'Продовжити відтворення';

  @override
  String get settingsCloudSyncSection => 'Хмарна синхронізація';

  @override
  String get settingsCloudSyncAuto => 'Автосинхронізація';

  @override
  String get settingsCloudSyncNow => 'Синхронізувати зараз';

  @override
  String get settingsCloudSyncInProgress => 'Синхронізація…';

  @override
  String get settingsCloudSyncNever => 'Ніколи';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Остання помилка: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity не знайдено';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity не знайдено: $error';
  }

  @override
  String get entityProvider => 'Провайдер';

  @override
  String get entityGenre => 'Жанр';

  @override
  String get entityPlaylist => 'Плейлист';

  @override
  String get entitySource => 'Джерело';

  @override
  String get entityMovie => 'Фільм';

  @override
  String get entitySeries => 'Серіал';

  @override
  String get entityPerson => 'Людина';

  @override
  String get entitySaga => 'Сага';

  @override
  String get entityVideo => 'Відео';

  @override
  String get entityRoute => 'Маршрут';

  @override
  String get errorTimeoutLoading => 'Час очікування завантаження минув';

  @override
  String get parentalContentRestricted => 'Обмежений контент';

  @override
  String get parentalContentRestrictedDefault =>
      'Цей контент заблоковано батьківським контролем профілю.';

  @override
  String get parentalReasonTooYoung =>
      'Для цього контенту потрібен вік вищий за ліміт профілю.';

  @override
  String get parentalReasonUnknownRating =>
      'Віковий рейтинг для цього контенту недоступний.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Цей контент не можна оцінити для батьківського контролю.';

  @override
  String get parentalUnlockButton => 'Розблокувати';

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
  String get hc_chargement_episodes_en_cours_33fc4ace =>
      'Завантаження епізодів…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Немає доступного плейлиста. Створіть новий.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Помилка завантаження плейлистів: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa =>
      'Не вдалося відкрити посилання';

  @override
  String get hc_qualite_preferee_776dbeea => 'Бажана якість';

  @override
  String get hc_annuler_49ba3292 => 'Скасувати';

  @override
  String get hc_deconnexion_903dca17 => 'Вийти';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Помилка виходу: \$e';

  @override
  String get hc_choisir_b030d590 => 'Вибрати';

  @override
  String get hc_avantages_08d7f47c => 'Переваги';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Повідомлення надіслано. Дякуємо.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Пізніше';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Перезапустити зараз';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Використати це джерело?';

  @override
  String get hc_utiliser_fb5e43ce => 'Використати';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Джерело додано';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Заблоковані налаштування';

  @override
  String get hc_compte_cloud_2812b31e => 'Хмарний обліковий запис';

  @override
  String get hc_se_connecter_fedf2439 => 'Увійти';

  @override
  String get hc_propos_5345add5 => 'Про застосунок';

  @override
  String get hc_politique_confidentialite_42b0e51e =>
      'Політика конфіденційності';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Умови використання';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Збережені джерела';

  @override
  String get hc_rafraichir_be30b7d1 => 'Оновити';

  @override
  String get hc_activer_une_source_749ced38 => 'Активувати джерело';

  @override
  String get hc_nom_source_9a3e4156 => 'Назва джерела';

  @override
  String get hc_mon_iptv_b239352c => 'Мій IPTV';

  @override
  String get hc_username_84c29015 => 'Імʼя користувача';

  @override
  String get hc_password_8be3c943 => 'Пароль';

  @override
  String get hc_server_url_1d5d1eff => 'URL сервера';

  @override
  String get hc_verification_pin_e17c8fe0 => 'Перевірка PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'Установити PIN';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'Пропозицію підписки не знайдено: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'Купівлю підписки скасовано користувачем.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'Операція магазину перевищила таймаут: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 =>
      'HTTP-помилка під час handshake';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Не‑JSON відповідь від сервера Xtream';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'Некоректна відповідь від сервера Xtream';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      'Недоступно на цьому джерелі';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Джерело видалено';

  @override
  String get hc_source_modifiee_335ef502 => 'Джерело змінено';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'Установити PIN-код';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Позначити як непереглянуте';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Ви дійсно хочете вийти?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Для хмарної синхронізації потрібен Movi Premium.';

  @override
  String get hc_auto_c614ba7c => 'Авто';

  @override
  String get hc_organiser_838a7e57 => 'Упорядкувати';

  @override
  String get hc_modifier_f260e757 => 'Змінити';

  @override
  String get hc_ajouter_87c57ed1 => 'Додати';

  @override
  String get hc_source_active_e571305e => 'Активне джерело';

  @override
  String get hc_autres_sources_e32592a6 => 'Інші джерела';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Скарга недоступна для цього контенту.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Захист контенту';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Перевірка вікових рейтингів…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Показати все';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Повідомити про проблему';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Якщо цей контент неприйнятний і був доступний попри обмеження, коротко опишіть проблему.';

  @override
  String get hc_envoyer_e9ce243b => 'Надіслати';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Дитячий профіль створено';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Дитячий профіль створено. Щоб захистити застосунок і попередньо завантажити вікові рейтинги, рекомендується перезапустити застосунок.';

  @override
  String get hc_pseudo_4cf966c0 => 'Нікнейм';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Дитячий профіль';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Віковий ліміт';

  @override
  String get hc_code_pin_e79c48bd => 'PIN-код';

  @override
  String get hc_changer_code_pin_3b069731 => 'Змінити PIN-код';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'Видалити PIN-код';

  @override
  String get hc_supprimer_pin_51850c7b => 'Видалити PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'Видалити';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Потрібен PIN і вмикає фільтр PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Активувати це джерело зараз?';

  @override
  String get hc_application_b291beb8 => 'Застосунок';

  @override
  String get hc_version_1_0_0_347e553c => 'Версія 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Подяки';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Цей продукт використовує TMDB API, але не схвалений і не сертифікований TMDB.';

  @override
  String get hc_verification_targets_d51632f8 => 'Цілі перевірки';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 =>
      'Плавний перехід має «поглинати» кадр';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 =>
      'Недійсний Xtream streamId: ...';

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
  String get hc_url_invalide_aa227a66 => 'Недійсний URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Оновити\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Меню\'';

  @override
  String get hc_retour_e5befb1f => 'Назад';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Більше дій\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Більше дій';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c => 'semanticLabel: \'Пошук\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'Додати\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Вийти';

  @override
  String get dialogSignOutBody => 'Ви впевнені, що хочете вийти?';

  @override
  String get settingsUnableToOpenLink => 'Не вдалося відкрити посилання';

  @override
  String get settingsSyncDisabled => 'Вимкнено';

  @override
  String get settingsSyncEveryHour => 'Щогодини';

  @override
  String get settingsSyncEvery2Hours => 'Кожні 2 години';

  @override
  String get settingsSyncEvery4Hours => 'Кожні 4 години';

  @override
  String get settingsSyncEvery6Hours => 'Кожні 6 годин';

  @override
  String get settingsSyncEveryDay => 'Щодня';

  @override
  String get settingsSyncEvery2Days => 'Кожні 2 дні';

  @override
  String get settingsColorCustom => 'Власний';

  @override
  String get settingsColorBlue => 'Синій';

  @override
  String get settingsColorPink => 'Рожевий';

  @override
  String get settingsColorGreen => 'Зелений';

  @override
  String get settingsColorPurple => 'Фіолетовий';

  @override
  String get settingsColorOrange => 'Помаранчевий';

  @override
  String get settingsColorTurquoise => 'Бірюзовий';

  @override
  String get settingsColorYellow => 'Жовтий';

  @override
  String get settingsColorIndigo => 'Індиго';

  @override
  String get settingsCloudAccountTitle => 'Хмарний обліковий запис';

  @override
  String get settingsAccountConnected => 'Підключено';

  @override
  String get settingsAccountLocalMode => 'Локальний режим';

  @override
  String get settingsAccountCloudUnavailable => 'Хмара недоступна';

  @override
  String get aboutTmdbDisclaimer =>
      'Цей продукт використовує API TMDB, але не схвалений і не сертифікований TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Подяки';
}
