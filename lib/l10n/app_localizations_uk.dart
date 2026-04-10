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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count результату)',
      many: '($count результатів)',
      few: '($count результати)',
      one: '(1 результат)',
      zero: '(0 результатів)',
    );
    return '$_temp0';
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
  String get libraryTypeInProgress => 'У процесі перегляду';

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
    return 'Шукати в $provider';
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
      'Ми надішлемо 8-значний код на електронну адресу вашого облікового запису, щоб ви могли скинути PIN-код цього профілю.';

  @override
  String get pinRecoveryRequestCodeButton => 'Надіслати код';

  @override
  String get pinRecoveryCodeSentHint =>
      'Код надіслано на електронну адресу вашого облікового запису. Перевірте повідомлення та введіть його нижче.';

  @override
  String get pinRecoveryComingSoon => 'Ця функція скоро зʼявиться.';

  @override
  String get pinRecoveryNotAvailable =>
      'Відновлення PIN-коду через електронну пошту наразі недоступне.';

  @override
  String get pinRecoveryCodeLabel => 'Код відновлення';

  @override
  String get pinRecoveryCodeHint => '8 цифр';

  @override
  String get pinRecoveryVerifyButton => 'Підтвердити код';

  @override
  String get pinRecoveryCodeInvalid => 'Введіть 8-значний код відновлення';

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
  String get pinRecoveryResetButton => 'Скинути PIN-код';

  @override
  String get pinRecoveryPinInvalid => 'Введіть PIN від 4 до 6 цифр';

  @override
  String get pinRecoveryPinMismatch => 'PIN-коди не збігаються';

  @override
  String get pinRecoveryResetSuccess => 'PIN-код скинуто';

  @override
  String get profilePinSaved => 'PIN-код збережено.';

  @override
  String get profilePinEditLabel => 'Редагувати PIN-код';

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
  String get settingsPreferredAudioLanguage => 'Бажана мова аудіо';

  @override
  String get settingsPreferredSubtitleLanguage => 'Бажана мова субтитрів';

  @override
  String get libraryPlaylistsFilter => 'Плейлисти';

  @override
  String get librarySagasFilter => 'Саги';

  @override
  String get libraryArtistsFilter => 'Артисти';

  @override
  String get librarySearchPlaceholder => 'Пошук у моїй бібліотеці…';

  @override
  String get libraryInProgress => 'Продовжити перегляд';

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
    return 'Продовжити S$season · E$episode';
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
  String get playlistAddButton => 'Додати до плейлиста';

  @override
  String get playlistSortButton => 'Сортувати';

  @override
  String get playlistSortByTitle => 'Сортувати за';

  @override
  String get playlistSortByTitleOption => 'Назва';

  @override
  String get playlistSortRecentAdditions => 'Нещодавно додані';

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
  String get playlistDeleteTitle => 'Видалити плейлист';

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
      'Введіть свою електронну адресу та 8-значний код, який ми вам надішлемо.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'name@example.com';

  @override
  String get authOtpEmailHelp =>
      'Ми надішлемо 8‑значний код. За потреби перевірте спам.';

  @override
  String get authOtpCodeLabel => 'Код підтвердження';

  @override
  String get authOtpCodeHint => '8‑значний код';

  @override
  String get authOtpCodeHelp =>
      'Введіть 8-значний код, отриманий електронною поштою.';

  @override
  String get authOtpPrimarySend => 'Надіслати код';

  @override
  String get authOtpPrimarySubmit => 'Увійти';

  @override
  String get authOtpResend => 'Надіслати код ще раз';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Повторно надіслати код через $seconds с';
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
  String get settingsSubtitlesTitle => 'Субтитри';

  @override
  String get settingsSubtitlesSizeTitle => 'Розмір тексту';

  @override
  String get settingsSubtitlesColorTitle => 'Колір тексту';

  @override
  String get settingsSubtitlesFontTitle => 'Шрифт';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Системний';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Швидкі налаштування';

  @override
  String get settingsSubtitlesPreviewTitle => 'Попередній перегляд';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Це попередній перегляд субтитрів.\nНалаштуйте читабельність у реальному часі.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Тло';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Непрозорість тла';

  @override
  String get settingsSubtitlesShadowTitle => 'Тінь';

  @override
  String get settingsSubtitlesShadowOff => 'Вимкнено';

  @override
  String get settingsSubtitlesShadowSoft => 'М’яка';

  @override
  String get settingsSubtitlesShadowStrong => 'Сильна';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Точний розмір';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Масштаб';

  @override
  String get settingsSubtitlesResetDefaults => 'Скинути до типових';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Розширений стиль субтитрів (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Тло, непрозорість, пресети тіні та точний розмір доступні в Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Розблокувати з Premium';

  @override
  String get settingsSyncSectionTitle => 'Синхронізація аудіо/субтитрів';

  @override
  String get settingsSubtitleOffsetTitle => 'Зсув субтитрів';

  @override
  String get settingsAudioOffsetTitle => 'Зсув аудіо';

  @override
  String get settingsOffsetUnsupported =>
      'Не підтримується цим бекендом або платформою.';

  @override
  String get settingsSyncResetOffsets => 'Скинути зсуви синхронізації';

  @override
  String get aboutTmdbDisclaimer =>
      'Цей продукт використовує API TMDB, але не схвалений і не сертифікований TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Подяки';

  @override
  String get actionSend => 'Надіслати';

  @override
  String get profilePinSetLabel => 'Установити PIN-код';

  @override
  String get reportingProblemSentConfirmation => 'Скаргу надіслано. Дякуємо.';

  @override
  String get reportingProblemBody =>
      'Якщо цей контент неприйнятний і був доступний попри обмеження, коротко опишіть проблему.';

  @override
  String get reportingProblemExampleHint =>
      'Приклад: фільм жахів доступний попри PEGI 12';

  @override
  String get settingsAutomaticOption => 'Авто';

  @override
  String get settingsPreferredPlaybackQuality => 'Бажана якість відтворення';

  @override
  String settingsSignOutError(String error) {
    return 'Помилка виходу: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Умови використання';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Для хмарної синхронізації потрібен Movi Premium.';
}
