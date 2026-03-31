// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeTitle => 'مرحبًا!';

  @override
  String get welcomeSubtitle => 'املأ تفضيلاتك لتخصيص Movi.';

  @override
  String get labelUsername => 'الاسم المستعار';

  @override
  String get labelPreferredLanguage => 'اللغة المفضلة';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get hintUsername => 'اسمك المستعار';

  @override
  String get errorFillFields => 'يرجى ملء الحقول بشكل صحيح.';

  @override
  String get homeWatchNow => 'مشاهدة';

  @override
  String get welcomeSourceTitle => 'مرحبًا!';

  @override
  String get welcomeSourceSubtitle => 'أضف مصدرًا لتخصيص تجربتك في Movi.';

  @override
  String get welcomeSourceAdd => 'إضافة مصدر';

  @override
  String get searchTitle => 'بحث';

  @override
  String get searchHint => 'اكتب ما تريد البحث عنه';

  @override
  String get clear => 'مسح';

  @override
  String get moviesTitle => 'أفلام';

  @override
  String get seriesTitle => 'مسلسلات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmpty => 'لا توجد عمليات بحث حديثة';

  @override
  String get delete => 'حذف';

  @override
  String resultsCount(int count) {
    return '($count نتيجة)';
  }

  @override
  String get errorUnknown => 'خطأ غير معروف';

  @override
  String errorConnectionFailed(String error) {
    return 'فشل الاتصال: $error';
  }

  @override
  String get errorConnectionGeneric => 'فشل الاتصال';

  @override
  String get validationRequired => 'مطلوب';

  @override
  String get validationInvalidUrl => 'رابط غير صالح';

  @override
  String get snackbarSourceAddedBackground =>
      'تمت إضافة مصدر IPTV. تتم المزامنة في الخلفية…';

  @override
  String get snackbarSourceAddedSynced => 'تمت إضافة مصدر IPTV ومزامنته';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSearch => 'بحث';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguageLabel => 'لغة التطبيق';

  @override
  String get settingsGeneralTitle => 'تفضيلات عامة';

  @override
  String get settingsDarkModeTitle => 'الوضع الداكن';

  @override
  String get settingsDarkModeSubtitle => 'فعّل سمة مناسبة للّيل.';

  @override
  String get settingsNotificationsTitle => 'الإشعارات';

  @override
  String get settingsNotificationsSubtitle =>
      'تلقي إشعارات بالإصدارات الجديدة.';

  @override
  String get settingsAccountTitle => 'الحساب';

  @override
  String get settingsProfileInfoTitle => 'معلومات الملف الشخصي';

  @override
  String get settingsProfileInfoSubtitle => 'الاسم، الصورة، التفضيلات';

  @override
  String get settingsAboutTitle => 'حول';

  @override
  String get settingsLegalMentionsTitle => 'إشعارات قانونية';

  @override
  String get settingsPrivacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get settingsHelpDiagnosticsSection => 'المساعدة والتشخيص';

  @override
  String get settingsExportErrorLogs => 'تصدير سجلات الأخطاء';

  @override
  String get diagnosticsExportTitle => 'تصدير سجلات الأخطاء';

  @override
  String get diagnosticsExportDescription =>
      'يتضمن التشخيص فقط سجلات WARN/ERROR الأخيرة ومعرّفات الحساب/الملف الشخصي المُجزّأة (إن كانت مفعّلة). لا ينبغي أن تظهر أي مفاتيح/رموز.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'تضمين معرّفات الحساب/الملف الشخصي (مُجزّأة)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'يساعد على ربط خطأ بدون كشف المعرّف الأصلي.';

  @override
  String get diagnosticsCopiedClipboard => 'تم نسخ التشخيص إلى الحافظة.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'تم حفظ التشخيص: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'نسخ';

  @override
  String get diagnosticsActionSave => 'حفظ';

  @override
  String get actionChangeVersion => 'تغيير الإصدار';

  @override
  String get semanticsBack => 'رجوع';

  @override
  String get semanticsMoreActions => 'مزيد من الإجراءات';

  @override
  String get snackbarLoadingPlaylists => 'جارٍ تحميل قوائم التشغيل…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'لا توجد قائمة تشغيل متاحة. أنشئ واحدة.';

  @override
  String errorAddToPlaylist(String error) {
    return 'خطأ عند الإضافة إلى قائمة التشغيل: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'هذا الوسيط موجود بالفعل في قائمة التشغيل هذه';

  @override
  String errorLoadingPlaylists(String message) {
    return 'خطأ عند تحميل قوائم التشغيل: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'لا تتوفر ميزة الإبلاغ لهذا المحتوى.';

  @override
  String get snackbarLoadingEpisodes => 'جارٍ تحميل الحلقات…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'الحلقة غير متاحة في قائمة التشغيل';

  @override
  String snackbarGenericError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get snackbarLoading => 'جارٍ التحميل…';

  @override
  String get snackbarNoVersionAvailable => 'لا توجد نسخة متاحة';

  @override
  String get snackbarVersionSaved => 'تم حفظ النسخة';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'النسخة $index';
  }

  @override
  String get actionReadMore => 'اقرأ المزيد';

  @override
  String get actionShowLess => 'إظهار أقل';

  @override
  String get actionViewPage => 'عرض الصفحة';

  @override
  String get semanticsSeeSagaPage => 'عرض صفحة السلسلة';

  @override
  String get libraryTypeSaga => 'سلسلة';

  @override
  String get libraryTypeInProgress => 'قيد المتابعة';

  @override
  String get libraryTypeFavoriteMovies => 'الأفلام المفضلة';

  @override
  String get libraryTypeFavoriteSeries => 'المسلسلات المفضلة';

  @override
  String get libraryTypeHistory => 'السجل';

  @override
  String get libraryTypePlaylist => 'قائمة تشغيل';

  @override
  String get libraryTypeArtist => 'فنان';

  @override
  String libraryItemCount(int count) {
    return '$count عنصر';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'تمت إعادة تسمية قائمة التشغيل إلى \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'تم حذف قائمة التشغيل';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'خطأ: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'هذا الوسيط موجود بالفعل في قائمة التشغيل';

  @override
  String get snackbarAddedToPlaylist => 'تمت الإضافة إلى قائمة التشغيل';

  @override
  String get addMediaTitle => 'إضافة وسيط';

  @override
  String get searchMinCharsHint => 'اكتب 3 أحرف على الأقل للبحث';

  @override
  String get badgeAdded => 'مضاف';

  @override
  String get snackbarNotAvailableOnSource => 'غير متاح على هذا المصدر';

  @override
  String get errorLoadingTitle => 'خطأ في التحميل';

  @override
  String errorLoadingWithMessage(String error) {
    return 'خطأ في التحميل: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'خطأ عند تحميل قوائم التشغيل: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'مسح عامل التصفية';

  @override
  String get homeErrorSwipeToRetry => 'حدث خطأ. اسحب للأسفل لإعادة المحاولة.';

  @override
  String get homeContinueWatching => 'متابعة المشاهدة';

  @override
  String get homeNoIptvSources =>
      'لا يوجد مصدر IPTV نشط. أضف مصدرًا من الإعدادات لرؤية الفئات.';

  @override
  String get homeNoTrends => 'لا يوجد محتوى رائج متاح';

  @override
  String get actionRefreshMetadata => 'تحديث البيانات الوصفية';

  @override
  String get actionChangeMetadata => 'تغيير البيانات الوصفية';

  @override
  String get actionAddToList => 'إضافة إلى قائمة';

  @override
  String get metadataRefreshed => 'تم تحديث البيانات الوصفية';

  @override
  String get errorRefreshingMetadata => 'خطأ عند تحديث البيانات الوصفية';

  @override
  String get actionMarkSeen => 'وضع علامة كمشاهد';

  @override
  String get actionMarkUnseen => 'وضع علامة كغير مشاهد';

  @override
  String get actionReportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get featureComingSoon => 'الميزة قريبًا';

  @override
  String get subtitlesMenuTitle => 'الترجمات';

  @override
  String get audioMenuTitle => 'الصوت';

  @override
  String get videoFitModeMenuTitle => 'وضع العرض';

  @override
  String get videoFitModeContain => 'الأبعاد الأصلية';

  @override
  String get videoFitModeCover => 'ملء الشاشة';

  @override
  String get actionDisable => 'تعطيل';

  @override
  String defaultTrackLabel(String id) {
    return 'مسار $id';
  }

  @override
  String get controlRewind10 => '10 ث';

  @override
  String get controlRewind30 => '30 ث';

  @override
  String get controlForward10 => '+ 10 ث';

  @override
  String get controlForward30 => '+ 30 ث';

  @override
  String get actionNextEpisode => 'الحلقة التالية';

  @override
  String get actionRestart => 'إعادة التشغيل';

  @override
  String get errorSeriesDataUnavailable => 'تعذر تحميل بيانات المسلسل';

  @override
  String get errorNextEpisodeFailed => 'تعذر تحديد الحلقة التالية';

  @override
  String get actionLoadMore => 'تحميل المزيد';

  @override
  String get iptvServerUrlLabel => 'رابط الخادم';

  @override
  String get iptvServerUrlHint => 'رابط خادم Xtream';

  @override
  String get iptvPasswordLabel => 'كلمة المرور';

  @override
  String get iptvPasswordHint => 'كلمة مرور Xtream';

  @override
  String get actionConnect => 'اتصال';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'تحديث قوائم تشغيل IPTV';

  @override
  String get activeSourceTitle => 'المصدر النشط';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusNoActiveSource => 'لا يوجد مصدر نشط';

  @override
  String get overlayPreparingHome => 'جارٍ تحضير الصفحة الرئيسية…';

  @override
  String get overlayLoadingMoviesAndSeries => 'جارٍ تحميل الأفلام والمسلسلات…';

  @override
  String get overlayLoadingCategories => 'جارٍ تحميل الفئات…';

  @override
  String get bootstrapRefreshing => 'جارٍ تحديث قوائم IPTV…';

  @override
  String get bootstrapEnriching => 'جارٍ تحضير البيانات الوصفية…';

  @override
  String get errorPrepareHome => 'تعذر تحضير الصفحة الرئيسية';

  @override
  String get overlayOpeningHome => 'جارٍ فتح الصفحة الرئيسية…';

  @override
  String get overlayRefreshingIptvLists => 'جارٍ تحديث قوائم IPTV…';

  @override
  String get overlayPreparingMetadata => 'جارٍ تحضير البيانات الوصفية…';

  @override
  String get errorHomeLoadTimeout => 'انتهت مهلة تحميل الصفحة الرئيسية';

  @override
  String get faqLabel => 'الأسئلة الشائعة';

  @override
  String get iptvUsernameLabel => 'اسم المستخدم';

  @override
  String get iptvUsernameHint => 'اسم مستخدم Xtream';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionSeeAll => 'عرض الكل';

  @override
  String get actionExpand => 'توسيع';

  @override
  String get actionCollapse => 'طيّ';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'ابحث على $provider...';
  }

  @override
  String get actionClearHistory => 'مسح السجل';

  @override
  String get castTitle => 'طاقم العمل';

  @override
  String get recommendationsTitle => 'اقتراحات';

  @override
  String get libraryHeader => 'مكتبتك';

  @override
  String get libraryDataInfo =>
      'سيتم عرض البيانات عند تنفيذ طبقة البيانات/النطاق.';

  @override
  String get libraryEmpty => 'أعجب بأفلام أو مسلسلات أو ممثلين لتظهر هنا.';

  @override
  String get serie => 'مسلسلات';

  @override
  String get recherche => 'بحث';

  @override
  String get notYetAvailable => 'غير متاح بعد';

  @override
  String get createPlaylistTitle => 'إنشاء قائمة تشغيل';

  @override
  String get playlistName => 'اسم قائمة التشغيل';

  @override
  String get addMedia => 'إضافة وسيط';

  @override
  String get renamePlaylist => 'إعادة تسمية';

  @override
  String get deletePlaylist => 'حذف';

  @override
  String get pinPlaylist => 'تثبيت';

  @override
  String get unpinPlaylist => 'إلغاء التثبيت';

  @override
  String get playlistPinned => 'تم تثبيت قائمة التشغيل';

  @override
  String get playlistUnpinned => 'تم إلغاء تثبيت قائمة التشغيل';

  @override
  String get playlistDeleted => 'تم حذف قائمة التشغيل';

  @override
  String playlistCreatedSuccess(String name) {
    return 'تم إنشاء قائمة التشغيل \"$name\"';
  }

  @override
  String playlistCreateError(String error) {
    return 'خطأ عند إنشاء قائمة التشغيل: $error';
  }

  @override
  String get addedToPlaylist => 'مضاف';

  @override
  String get pinRecoveryLink => 'استعادة رمز PIN';

  @override
  String get pinRecoveryTitle => 'استعادة رمز PIN';

  @override
  String get pinRecoveryDescription => 'استرجع رمز PIN لملفك الشخصي المحمي.';

  @override
  String get pinRecoveryComingSoon => 'هذه الميزة قادمة قريبًا.';

  @override
  String get pinRecoveryCodeLabel => 'رمز الاستعادة';

  @override
  String get pinRecoveryCodeHint => '8 أرقام';

  @override
  String get pinRecoveryVerifyButton => 'تحقق';

  @override
  String get pinRecoveryCodeInvalid => 'أدخل الرمز المكوّن من 8 أرقام';

  @override
  String get pinRecoveryCodeExpired => 'انتهت صلاحية رمز الاستعادة';

  @override
  String get pinRecoveryTooManyAttempts => 'محاولات كثيرة. حاول لاحقًا.';

  @override
  String get pinRecoveryUnknownError => 'حدث خطأ غير متوقع';

  @override
  String get pinRecoveryNewPinLabel => 'PIN جديد';

  @override
  String get pinRecoveryNewPinHint => '4-6 أرقام';

  @override
  String get pinRecoveryConfirmPinLabel => 'تأكيد PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'أعد إدخال PIN';

  @override
  String get pinRecoveryResetButton => 'تحديث PIN';

  @override
  String get pinRecoveryPinInvalid => 'أدخل PIN من 4 إلى 6 أرقام';

  @override
  String get pinRecoveryPinMismatch => 'رمزا PIN غير متطابقين';

  @override
  String get pinRecoveryResetSuccess => 'تم تحديث PIN';

  @override
  String get settingsAccountsSection => 'الحسابات';

  @override
  String get settingsIptvSection => 'إعدادات IPTV';

  @override
  String get settingsSourcesManagement => 'إدارة المصادر';

  @override
  String get settingsSyncFrequency => 'تكرار التحديث';

  @override
  String get settingsAppSection => 'إعدادات التطبيق';

  @override
  String get settingsAccentColor => 'لون التمييز';

  @override
  String get settingsPlaybackSection => 'إعدادات التشغيل';

  @override
  String get settingsPreferredAudioLanguage => 'اللغة المفضلة';

  @override
  String get settingsPreferredSubtitleLanguage => 'الترجمات المفضلة';

  @override
  String get libraryPlaylistsFilter => 'قوائم التشغيل';

  @override
  String get librarySagasFilter => 'السلاسل';

  @override
  String get libraryArtistsFilter => 'الفنانون';

  @override
  String get librarySearchPlaceholder => 'ابحث في مكتبتي...';

  @override
  String get libraryInProgress => 'قيد المتابعة';

  @override
  String get libraryFavoriteMovies => 'الأفلام المفضلة';

  @override
  String get libraryFavoriteSeries => 'المسلسلات المفضلة';

  @override
  String get libraryWatchHistory => 'سجل المشاهدة';

  @override
  String libraryItemCountPlural(int count) {
    return '$count عناصر';
  }

  @override
  String get searchPeopleTitle => 'الأشخاص';

  @override
  String get searchSagasTitle => 'السلاسل';

  @override
  String get searchByProvidersTitle => 'حسب المزوّدين';

  @override
  String get searchByGenresTitle => 'حسب الأنواع';

  @override
  String get personRoleActor => 'ممثل';

  @override
  String get personRoleDirector => 'مخرج';

  @override
  String get personRoleCreator => 'منشئ';

  @override
  String get tvDistribution => 'طاقم العمل';

  @override
  String tvSeasonLabel(int number) {
    return 'الموسم $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'لا توجد حلقات متاحة';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'متابعة S$season E$episode';
  }

  @override
  String get sagaViewPage => 'عرض الصفحة';

  @override
  String get sagaStartNow => 'ابدأ الآن';

  @override
  String get sagaContinue => 'متابعة';

  @override
  String sagaMovieCount(int count) {
    return '$count فيلم';
  }

  @override
  String get sagaMoviesList => 'قائمة الأفلام';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies أفلام - $shows مسلسلات';
  }

  @override
  String get personPlayRandomly => 'تشغيل عشوائيًا';

  @override
  String get personMoviesList => 'قائمة الأفلام';

  @override
  String get personSeriesList => 'قائمة المسلسلات';

  @override
  String get playlistPlayRandomly => 'تشغيل عشوائيًا';

  @override
  String get playlistAddButton => 'إضافة';

  @override
  String get playlistSortButton => 'ترتيب';

  @override
  String get playlistSortByTitle => 'ترتيب حسب';

  @override
  String get playlistSortByTitleOption => 'العنوان';

  @override
  String get playlistSortRecentAdditions => 'الإضافات الأخيرة';

  @override
  String get playlistSortOldestFirst => 'الأقدم أولًا';

  @override
  String get playlistSortNewestFirst => 'الأحدث أولًا';

  @override
  String get playlistEmptyMessage => 'لا توجد عناصر في قائمة التشغيل هذه';

  @override
  String playlistItemCount(int count) {
    return '$count عنصر';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count عناصر';
  }

  @override
  String get playlistSeasonSingular => 'موسم';

  @override
  String get playlistSeasonPlural => 'مواسم';

  @override
  String get playlistRenameTitle => 'إعادة تسمية قائمة التشغيل';

  @override
  String get playlistNamePlaceholder => 'اسم قائمة التشغيل';

  @override
  String playlistRenamedSuccess(String name) {
    return 'تمت إعادة تسمية قائمة التشغيل إلى \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'حذف';

  @override
  String playlistDeleteConfirm(String title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟';
  }

  @override
  String get playlistDeletedSuccess => 'تم حذف قائمة التشغيل';

  @override
  String get playlistItemRemovedSuccess => 'تمت إزالة العنصر';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'إزالة \"$title\" من قائمة التشغيل؟';
  }

  @override
  String get categoryLoadFailed => 'فشل تحميل الفئة.';

  @override
  String get categoryEmpty => 'لا توجد عناصر في هذه الفئة.';

  @override
  String get categoryLoadingMore => 'جارٍ تحميل المزيد…';

  @override
  String get movieNoPlaylistsAvailable => 'لا توجد قائمة تشغيل متاحة';

  @override
  String playlistAddedTo(String title) {
    return 'تمت الإضافة إلى \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'الفيلم غير متاح في قائمة التشغيل';

  @override
  String errorPlaybackFailed(String message) {
    return 'خطأ أثناء تشغيل الفيلم: $message';
  }

  @override
  String get movieNoMedia => 'لا توجد وسائط لعرضها';

  @override
  String get personNoData => 'لا توجد بيانات لعرضها.';

  @override
  String get personGenericError => 'حدث خطأ أثناء تحميل هذا الشخص.';

  @override
  String get personBiographyTitle => 'السيرة الذاتية';

  @override
  String get authOtpTitle => 'تسجيل الدخول';

  @override
  String get authOtpSubtitle =>
      'أدخل بريدك الإلكتروني والرمز المكوّن من 8 أرقام الذي سنرسله لك.';

  @override
  String get authOtpEmailLabel => 'البريد الإلكتروني';

  @override
  String get authOtpEmailHint => 'you@email';

  @override
  String get authOtpEmailHelp =>
      'سنرسل لك رمزًا من 8 أرقام. تحقّق من البريد العشوائي عند الحاجة.';

  @override
  String get authOtpCodeLabel => 'رمز التحقق';

  @override
  String get authOtpCodeHint => 'رمز من 8 أرقام';

  @override
  String get authOtpCodeHelp =>
      'أدخل الرمز المكوّن من 8 أرقام الذي وصل عبر البريد.';

  @override
  String get authOtpPrimarySend => 'إرسال الرمز';

  @override
  String get authOtpPrimarySubmit => 'تسجيل الدخول';

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'إعادة الإرسال بعد $secondsث';
  }

  @override
  String get authOtpChangeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get resumePlayback => 'متابعة التشغيل';

  @override
  String get settingsCloudSyncSection => 'مزامنة السحابة';

  @override
  String get settingsCloudSyncAuto => 'مزامنة تلقائية';

  @override
  String get settingsCloudSyncNow => 'زامن الآن';

  @override
  String get settingsCloudSyncInProgress => 'جارٍ المزامنة…';

  @override
  String get settingsCloudSyncNever => 'أبدًا';

  @override
  String settingsCloudSyncError(Object error) {
    return 'آخر خطأ: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return 'لم يتم العثور على $entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return 'لم يتم العثور على $entity: $error';
  }

  @override
  String get entityProvider => 'مزوّد';

  @override
  String get entityGenre => 'نوع';

  @override
  String get entityPlaylist => 'قائمة تشغيل';

  @override
  String get entitySource => 'مصدر';

  @override
  String get entityMovie => 'فيلم';

  @override
  String get entitySeries => 'مسلسل';

  @override
  String get entityPerson => 'شخص';

  @override
  String get entitySaga => 'سلسلة';

  @override
  String get entityVideo => 'فيديو';

  @override
  String get entityRoute => 'مسار';

  @override
  String get errorTimeoutLoading => 'انتهت مهلة التحميل';

  @override
  String get parentalContentRestricted => 'محتوى مقيّد';

  @override
  String get parentalContentRestrictedDefault =>
      'هذا المحتوى محظور بواسطة الرقابة الأبوية لهذا الملف الشخصي.';

  @override
  String get parentalReasonTooYoung =>
      'يتطلب هذا المحتوى عمرًا أعلى من حد هذا الملف الشخصي.';

  @override
  String get parentalReasonUnknownRating =>
      'تصنيف العمر لهذا المحتوى غير متاح.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'لا يمكن تقييم هذا المحتوى للرقابة الأبوية.';

  @override
  String get parentalUnlockButton => 'فتح';

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
  String get hc_chargement_episodes_en_cours_33fc4ace => 'جارٍ تحميل الحلقات…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'لا توجد قائمة تشغيل متاحة. أنشئ واحدة.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'خطأ عند تحميل قوائم التشغيل: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => 'تعذر فتح الرابط';

  @override
  String get hc_qualite_preferee_776dbeea => 'الجودة المفضلة';

  @override
  String get hc_annuler_49ba3292 => 'إلغاء';

  @override
  String get hc_deconnexion_903dca17 => 'تسجيل الخروج';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'خطأ عند تسجيل الخروج: \$e';

  @override
  String get hc_choisir_b030d590 => 'اختيار';

  @override
  String get hc_avantages_08d7f47c => 'المزايا';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'تم إرسال البلاغ. شكرًا لك.';

  @override
  String get hc_plus_tard_1f42ab3b => 'لاحقًا';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'إعادة التشغيل الآن';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'استخدام هذا المصدر؟';

  @override
  String get hc_utiliser_fb5e43ce => 'استخدام';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'تمت إضافة المصدر';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'إعدادات مقفلة';

  @override
  String get hc_compte_cloud_2812b31e => 'حساب سحابي';

  @override
  String get hc_se_connecter_fedf2439 => 'تسجيل الدخول';

  @override
  String get hc_propos_5345add5 => 'حول';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'سياسة الخصوصية';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'شروط الاستخدام';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'مصادر محفوظة';

  @override
  String get hc_rafraichir_be30b7d1 => 'تحديث';

  @override
  String get hc_activer_une_source_749ced38 => 'تفعيل مصدر';

  @override
  String get hc_nom_source_9a3e4156 => 'اسم المصدر';

  @override
  String get hc_mon_iptv_b239352c => 'IPTV الخاص بي';

  @override
  String get hc_username_84c29015 => 'اسم المستخدم';

  @override
  String get hc_password_8be3c943 => 'كلمة المرور';

  @override
  String get hc_server_url_1d5d1eff => 'رابط الخادم';

  @override
  String get hc_verification_pin_e17c8fe0 => 'التحقق من PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'تعيين PIN';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'لم يتم العثور على عرض الاشتراك: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'تم إلغاء عملية شراء الاشتراك بواسطة المستخدم.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'انتهت مهلة عملية المتجر: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 =>
      'خطأ HTTP أثناء المصافحة';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'استجابة غير JSON من خادم Xtream';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'استجابة غير صالحة من خادم Xtream';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      'غير متاح على هذا المصدر';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'تمت إزالة المصدر';

  @override
  String get hc_source_modifiee_335ef502 => 'تم تحديث المصدر';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'تعيين رمز PIN';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'وضع علامة كغير مشاهد';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'يلزم Movi Premium للمزامنة السحابية.';

  @override
  String get hc_auto_c614ba7c => 'تلقائي';

  @override
  String get hc_organiser_838a7e57 => 'تنظيم';

  @override
  String get hc_modifier_f260e757 => 'تعديل';

  @override
  String get hc_ajouter_87c57ed1 => 'إضافة';

  @override
  String get hc_source_active_e571305e => 'المصدر النشط';

  @override
  String get hc_autres_sources_e32592a6 => 'مصادر أخرى';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'ميزة الإبلاغ غير متاحة لهذا المحتوى.';

  @override
  String get hc_securisation_contenu_e5195111 => 'تأمين المحتوى';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'جارٍ التحقق من التصنيفات العمرية…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'عرض الكل';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'الإبلاغ عن مشكلة';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'إذا كان هذا المحتوى غير مناسب وكان متاحًا رغم القيود، فصف المشكلة بإيجاز.';

  @override
  String get hc_envoyer_e9ce243b => 'إرسال';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'تم إنشاء ملف طفل';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'تم إنشاء ملف طفل. لتأمين التطبيق وتحميل التصنيفات العمرية مسبقًا، يُنصح بإعادة تشغيل التطبيق.';

  @override
  String get hc_pseudo_4cf966c0 => 'الاسم المستعار';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'ملف طفل';

  @override
  String get hc_limite_d_age_5b170fc9 => 'الحد العمري';

  @override
  String get hc_code_pin_e79c48bd => 'رمز PIN';

  @override
  String get hc_changer_code_pin_3b069731 => 'تغيير رمز PIN';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'إزالة رمز PIN';

  @override
  String get hc_supprimer_pin_51850c7b => 'إزالة PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'حذف';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'يتطلب PIN ويفعّل فلتر PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'هل تريد تفعيل هذا المصدر الآن؟';

  @override
  String get hc_application_b291beb8 => 'التطبيق';

  @override
  String get hc_version_1_0_0_347e553c => 'الإصدار 1.0.0';

  @override
  String get hc_credits_293a6081 => 'الاعتمادات';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'يستخدم هذا المنتج واجهة TMDB البرمجية لكنه غير معتمد أو مُصادق عليه من TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'يستخدم هذا المنتج واجهة TMDB البرمجية لكنه غير معتمد أو مُصادق عليه من TMDB.';

  @override
  String get hc_verification_targets_d51632f8 => 'أهداف التحقق';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 =>
      'يجب أن يندمج التدرّج مع الإطار';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 =>
      'معرّف بث Xtream غير صالح: ...';

  @override
  String get hc_series_xtream_missing_poster_065b5103 =>
      'مسلسل xtream:... صورة الملصق مفقودة';

  @override
  String get hc_movie_not_found_a7fe72d9 => 'فيلم ... غير موجود ...';

  @override
  String get hc_missing_poster_1c9ba558 => '... صورة الملصق مفقودة';

  @override
  String get hc_invalid_watchlist_outbox_payload_327ac6c3 =>
      'حمولة outbox لقائمة المشاهدة غير صالحة.';

  @override
  String get hc_unknown_watchlist_operation_e9259c07 =>
      'عملية قائمة مشاهدة غير معروفة: ...';

  @override
  String get hc_invalid_playlist_outbox_payload_2d76e64f =>
      'حمولة outbox لقائمة التشغيل غير صالحة.';

  @override
  String get hc_unknown_playlist_operation_c98cbd41 =>
      'عملية قائمة تشغيل غير معروفة: ...';

  @override
  String get hc_url_invalide_aa227a66 => 'رابط غير صالح';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'IV قديم مفقود: لا يمكن فك تشفير النص المشفّر القديم.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'تحديث\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'القائمة\'';

  @override
  String get hc_retour_e5befb1f => 'رجوع';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'مزيد من الإجراءات\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'مزيد من الإجراءات';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c => 'semanticLabel: \'بحث\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'إضافة\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'موافق';

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String get dialogSignOutBody => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get settingsUnableToOpenLink => 'تعذر فتح الرابط';

  @override
  String get settingsSyncDisabled => 'معطّل';

  @override
  String get settingsSyncEveryHour => 'كل ساعة';

  @override
  String get settingsSyncEvery2Hours => 'كل ساعتين';

  @override
  String get settingsSyncEvery4Hours => 'كل 4 ساعات';

  @override
  String get settingsSyncEvery6Hours => 'كل 6 ساعات';

  @override
  String get settingsSyncEveryDay => 'كل يوم';

  @override
  String get settingsSyncEvery2Days => 'كل يومين';

  @override
  String get settingsColorCustom => 'مخصّص';

  @override
  String get settingsColorBlue => 'أزرق';

  @override
  String get settingsColorPink => 'وردي';

  @override
  String get settingsColorGreen => 'أخضر';

  @override
  String get settingsColorPurple => 'بنفسجي';

  @override
  String get settingsColorOrange => 'برتقالي';

  @override
  String get settingsColorTurquoise => 'فيروزي';

  @override
  String get settingsColorYellow => 'أصفر';

  @override
  String get settingsColorIndigo => 'نيلي';

  @override
  String get settingsCloudAccountTitle => 'حساب السحابة';

  @override
  String get settingsAccountConnected => 'متصل';

  @override
  String get settingsAccountLocalMode => 'الوضع المحلي';

  @override
  String get settingsAccountCloudUnavailable => 'السحابة غير متاحة';

  @override
  String get aboutTmdbDisclaimer =>
      'يستخدم هذا المنتج واجهة برمجة تطبيقات TMDB لكنه غير معتمد أو مُصدَّق من TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'الشكر والتقدير';
}
