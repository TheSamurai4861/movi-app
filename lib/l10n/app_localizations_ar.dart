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
  String get welcomeSubtitle => 'أدخل تفضيلاتك لتخصيص تجربة Movi.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count نتيجة)',
      many: '($count نتيجة)',
      few: '($count نتائج)',
      two: '(نتيجتان)',
      one: '(نتيجة واحدة)',
      zero: '(لا نتائج)',
    );
    return '$_temp0';
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
  String get settingsAboutTitle => 'حول التطبيق';

  @override
  String get settingsLegalMentionsTitle => 'الإشعارات القانونية';

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
      'يتضمن ملف التشخيص فقط أحدث سجلات WARN/ERROR ومعرّفات الحساب/الملف الشخصي المُجزّأة عند تفعيلها. يجب ألا تظهر أي مفاتيح أو رموز وصول.';

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
  String get homeNoTrends => 'لا يوجد محتوى رائج حاليًا';

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
  String get featureComingSoon => 'الميزة ستتوفر قريبًا';

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
  String get iptvServerUrlHint => 'عنوان خادم Xtream';

  @override
  String get iptvPasswordLabel => 'كلمة المرور';

  @override
  String get iptvPasswordHint => 'كلمة مرور Xtream';

  @override
  String get actionConnect => 'اتصل';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'تحديث قوائم تشغيل IPTV';

  @override
  String get activeSourceTitle => 'المصدر النشط';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusNoActiveSource => 'لا يوجد مصدر نشط';

  @override
  String get overlayPreparingHome => 'جارٍ تجهيز الصفحة الرئيسية…';

  @override
  String get overlayLoadingMoviesAndSeries => 'جارٍ تحميل الأفلام والمسلسلات…';

  @override
  String get overlayLoadingCategories => 'جارٍ تحميل الفئات…';

  @override
  String get bootstrapRefreshing => 'جارٍ تحديث قوائم IPTV…';

  @override
  String get bootstrapEnriching => 'جارٍ تجهيز البيانات الوصفية…';

  @override
  String get errorPrepareHome => 'تعذر تجهيز الصفحة الرئيسية';

  @override
  String get overlayOpeningHome => 'جارٍ فتح الصفحة الرئيسية…';

  @override
  String get overlayRefreshingIptvLists => 'جارٍ تحديث قوائم IPTV…';

  @override
  String get overlayPreparingMetadata => 'جارٍ تجهيز البيانات الوصفية…';

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
  String get actionSeeAll => 'عرض الجميع';

  @override
  String get actionExpand => 'توسيع';

  @override
  String get actionCollapse => 'طيّ';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'ابحث في $provider…';
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
      'ستظهر البيانات عند اكتمال تنفيذ طبقتَي البيانات والنطاق.';

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
  String get pinRecoveryDescription =>
      'سنرسل رمزًا مكوّنًا من 8 أرقام إلى البريد الإلكتروني المرتبط بحسابك لإعادة تعيين رمز PIN لهذا الملف الشخصي.';

  @override
  String get pinRecoveryRequestCodeButton => 'إرسال الرمز';

  @override
  String get pinRecoveryCodeSentHint =>
      'تم إرسال الرمز إلى البريد الإلكتروني المرتبط بحسابك. تحقّق من رسائلك وأدخله أدناه.';

  @override
  String get pinRecoveryComingSoon => 'هذه الميزة قادمة قريبًا.';

  @override
  String get pinRecoveryNotAvailable =>
      'استعادة رمز PIN عبر البريد الإلكتروني غير متاحة حاليًا.';

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
  String get pinRecoveryNewPinLabel => 'رمز PIN جديد';

  @override
  String get pinRecoveryNewPinHint => '4-6 أرقام';

  @override
  String get pinRecoveryConfirmPinLabel => 'تأكيد رمز PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'أعد إدخال رمز PIN';

  @override
  String get pinRecoveryResetButton => 'تحديث رمز PIN';

  @override
  String get pinRecoveryPinInvalid => 'أدخل رمز PIN مكوّنًا من 4 إلى 6 أرقام';

  @override
  String get pinRecoveryPinMismatch => 'رمزا PIN غير متطابقين';

  @override
  String get pinRecoveryResetSuccess => 'تم تحديث رمز PIN';

  @override
  String get profilePinSaved => 'تم حفظ رمز PIN.';

  @override
  String get profilePinEditLabel => 'تعديل رمز PIN';

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
  String get settingsPreferredAudioLanguage => 'اللغة الصوتية المفضلة';

  @override
  String get settingsPreferredSubtitleLanguage => 'لغة الترجمة المفضلة';

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
  String get personRoleCreator => 'منشئ العمل';

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
    return 'متابعة الموسم $season الحلقة $episode';
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
    return '$movies أفلام · $shows مسلسلات';
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
  String get authOtpEmailHint => 'name@example.com';

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
    return 'إعادة إرسال الرمز خلال $seconds ث';
  }

  @override
  String get authOtpChangeEmail => 'تغيير البريد الإلكتروني';

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
  String get authForgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get authForgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور.';

  @override
  String get authForgotPasswordInfoNeutral =>
      'سيتم إرسال رسالة إعادة تعيين كلمة المرور إلى هذا البريد الإلكتروني إذا كان الحساب موجودًا.';

  @override
  String get authForgotPasswordPrimarySubmit => 'إرسال الرابط';

  @override
  String get authForgotPasswordBackToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get authPasswordUseOtp => 'Use email code instead';

  @override
  String get resumePlayback => 'متابعة التشغيل';

  @override
  String get settingsCloudSyncSection => 'مزامنة السحابة';

  @override
  String get settingsCloudSyncAuto => 'مزامنة تلقائية';

  @override
  String get settingsCloudSyncNow => 'المزامنة الآن';

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
  String get parentalUnlockButton => 'إلغاء القفل';

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
  String get settingsAccountCloudUnavailable => 'السحابة غير متوفرة';

  @override
  String get settingsSubtitlesTitle => 'الترجمات';

  @override
  String get settingsSubtitlesSizeTitle => 'حجم النص';

  @override
  String get settingsSubtitlesColorTitle => 'لون النص';

  @override
  String get settingsSubtitlesFontTitle => 'الخط';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'النظام';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'إعدادات سريعة';

  @override
  String get settingsSubtitlesPreviewTitle => 'معاينة';

  @override
  String get settingsSubtitlesPreviewSample =>
      'هذه معاينة للترجمة.\nاضبط سهولة القراءة مباشرة.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'الخلفية';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'شفافية الخلفية';

  @override
  String get settingsSubtitlesShadowTitle => 'الظل';

  @override
  String get settingsSubtitlesShadowOff => 'إيقاف';

  @override
  String get settingsSubtitlesShadowSoft => 'خفيف';

  @override
  String get settingsSubtitlesShadowStrong => 'قوي';

  @override
  String get settingsSubtitlesFineSizeTitle => 'حجم دقيق';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'المقياس';

  @override
  String get settingsSubtitlesResetDefaults => 'إعادة الضبط الافتراضي';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'نمط ترجمة متقدّم (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'الخلفية والشفافية وإعدادات الظل والحجم الدقيق متاحة مع Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'افتحها مع Premium';

  @override
  String get settingsSyncSectionTitle => 'مزامنة الصوت/الترجمة';

  @override
  String get settingsSubtitleOffsetTitle => 'إزاحة الترجمة';

  @override
  String get settingsAudioOffsetTitle => 'إزاحة الصوت';

  @override
  String get settingsOffsetUnsupported =>
      'غير مدعوم في هذه الواجهة الخلفية أو على هذه المنصة.';

  @override
  String get settingsSyncResetOffsets => 'إعادة ضبط إزاحات المزامنة';

  @override
  String get aboutTmdbDisclaimer =>
      'يستخدم هذا المنتج واجهة برمجة تطبيقات TMDB لكنه غير معتمد أو مُصدَّق من TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'الشكر والتقدير';

  @override
  String get actionSend => 'إرسال';

  @override
  String get profilePinSetLabel => 'تعيين رمز PIN';

  @override
  String get reportingProblemSentConfirmation => 'تم إرسال البلاغ. شكرًا لك.';

  @override
  String get reportingProblemBody =>
      'إذا كان هذا المحتوى غير مناسب وكان متاحًا رغم القيود، فصف المشكلة باختصار.';

  @override
  String get reportingProblemExampleHint =>
      'مثال: فيلم رعب ظاهر رغم تصنيف PEGI 12';

  @override
  String get settingsAutomaticOption => 'تلقائي';

  @override
  String get settingsPreferredPlaybackQuality => 'جودة التشغيل المفضلة';

  @override
  String settingsSignOutError(String error) {
    return 'خطأ أثناء تسجيل الخروج: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'شروط الاستخدام';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'يتطلب مزامنة السحابة Movi Premium.';
}
