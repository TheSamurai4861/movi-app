// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get welcomeTitle => 'Hoş geldiniz!';

  @override
  String get welcomeSubtitle =>
      'Movi’yi kişiselleştirmek için tercihlerinizi doldurun.';

  @override
  String get labelUsername => 'Takma ad';

  @override
  String get labelPreferredLanguage => 'Tercih edilen dil';

  @override
  String get actionContinue => 'Devam';

  @override
  String get hintUsername => 'Takma adınız';

  @override
  String get errorFillFields => 'Lütfen alanları doğru şekilde doldurun.';

  @override
  String get homeWatchNow => 'İzle';

  @override
  String get welcomeSourceTitle => 'Hoş geldiniz!';

  @override
  String get welcomeSourceSubtitle =>
      'Movi’de deneyiminizi kişiselleştirmek için bir kaynak ekleyin.';

  @override
  String get welcomeSourceAdd => 'Kaynak ekle';

  @override
  String get searchTitle => 'Ara';

  @override
  String get searchHint => 'Aramanızı yazın';

  @override
  String get clear => 'Temizle';

  @override
  String get moviesTitle => 'Filmler';

  @override
  String get seriesTitle => 'Diziler';

  @override
  String get noResults => 'Sonuç yok';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historyEmpty => 'Yakın arama yok';

  @override
  String get delete => 'Sil';

  @override
  String resultsCount(int count) {
    return '($count sonuç)';
  }

  @override
  String get errorUnknown => 'Bilinmeyen hata';

  @override
  String errorConnectionFailed(String error) {
    return 'Bağlantı başarısız: $error';
  }

  @override
  String get errorConnectionGeneric => 'Bağlantı başarısız';

  @override
  String get validationRequired => 'Zorunlu';

  @override
  String get validationInvalidUrl => 'Geçersiz URL';

  @override
  String get snackbarSourceAddedBackground =>
      'IPTV kaynağı eklendi. Arka planda senkronize ediliyor…';

  @override
  String get snackbarSourceAddedSynced =>
      'IPTV kaynağı eklendi ve senkronize edildi';

  @override
  String get navHome => 'Ana sayfa';

  @override
  String get navSearch => 'Ara';

  @override
  String get navLibrary => 'Kütüphane';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageLabel => 'Uygulama dili';

  @override
  String get settingsGeneralTitle => 'Genel tercihler';

  @override
  String get settingsDarkModeTitle => 'Karanlık mod';

  @override
  String get settingsDarkModeSubtitle => 'Geceye uygun bir tema etkinleştirin.';

  @override
  String get settingsNotificationsTitle => 'Bildirimler';

  @override
  String get settingsNotificationsSubtitle => 'Yeni çıkanlardan haberdar olun.';

  @override
  String get settingsAccountTitle => 'Hesap';

  @override
  String get settingsProfileInfoTitle => 'Profil bilgileri';

  @override
  String get settingsProfileInfoSubtitle => 'İsim, avatar, tercihler';

  @override
  String get settingsAboutTitle => 'Hakkında';

  @override
  String get settingsLegalMentionsTitle => 'Yasal bilgiler';

  @override
  String get settingsPrivacyPolicyTitle => 'Gizlilik politikası';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionConfirm => 'Onayla';

  @override
  String get actionRetry => 'Yeniden dene';

  @override
  String get settingsHelpDiagnosticsSection => 'Yardım ve tanılama';

  @override
  String get settingsExportErrorLogs => 'Hata günlüklerini dışa aktar';

  @override
  String get diagnosticsExportTitle => 'Hata günlüklerini dışa aktar';

  @override
  String get diagnosticsExportDescription =>
      'Tanılama yalnızca son WARN/ERROR günlüklerini ve (etkinse) karmalanmış hesap/profil tanımlayıcılarını içerir. Hiçbir anahtar/token görünmemelidir.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Hesap/profil tanımlayıcılarını (karmalanmış) dahil et';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Ham kimliği ifşa etmeden hatayı ilişkilendirmeye yardımcı olur.';

  @override
  String get diagnosticsCopiedClipboard => 'Tanılama panoya kopyalandı.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Tanılama kaydedildi: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Kopyala';

  @override
  String get diagnosticsActionSave => 'Kaydet';

  @override
  String get actionChangeVersion => 'Sürümü değiştir';

  @override
  String get semanticsBack => 'Geri';

  @override
  String get semanticsMoreActions => 'Daha fazla işlem';

  @override
  String get snackbarLoadingPlaylists => 'Oynatma listeleri yükleniyor…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Oynatma listesi yok. Bir tane oluşturun.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Oynatma listesine eklenirken hata: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Bu medya zaten bu oynatma listesinde';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Oynatma listeleri yüklenirken hata: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Bu içerik için raporlama kullanılamıyor.';

  @override
  String get snackbarLoadingEpisodes => 'Bölümler yükleniyor…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Bölüm oynatma listesinde kullanılamıyor';

  @override
  String snackbarGenericError(String error) {
    return 'Hata: $error';
  }

  @override
  String get snackbarLoading => 'Yükleniyor…';

  @override
  String get snackbarNoVersionAvailable => 'Sürüm yok';

  @override
  String get snackbarVersionSaved => 'Sürüm kaydedildi';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Sürüm $index';
  }

  @override
  String get actionReadMore => 'Devamını oku';

  @override
  String get actionShowLess => 'Daha az göster';

  @override
  String get actionViewPage => 'Sayfayı görüntüle';

  @override
  String get semanticsSeeSagaPage => 'Saga sayfasını gör';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'İzlemeye devam et';

  @override
  String get libraryTypeFavoriteMovies => 'Favori filmler';

  @override
  String get libraryTypeFavoriteSeries => 'Favori diziler';

  @override
  String get libraryTypeHistory => 'Geçmiş';

  @override
  String get libraryTypePlaylist => 'Oynatma listesi';

  @override
  String get libraryTypeArtist => 'Sanatçı';

  @override
  String libraryItemCount(int count) {
    return '$count öğe';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Oynatma listesinin adı \"$name\" olarak değiştirildi';
  }

  @override
  String get snackbarPlaylistDeleted => 'Oynatma listesi silindi';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '\"$title\" silinsin mi?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return '\"$query\" için sonuç yok';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Hata: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Bu medya zaten oynatma listesinde';

  @override
  String get snackbarAddedToPlaylist => 'Oynatma listesine eklendi';

  @override
  String get addMediaTitle => 'Medya ekle';

  @override
  String get searchMinCharsHint => 'Aramak için en az 3 karakter yazın';

  @override
  String get badgeAdded => 'Eklendi';

  @override
  String get snackbarNotAvailableOnSource => 'Bu kaynakta kullanılamıyor';

  @override
  String get errorLoadingTitle => 'Yükleme hatası';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Yükleme hatası: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Oynatma listeleri yüklenirken hata: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Filtreyi temizle';

  @override
  String get homeErrorSwipeToRetry =>
      'Bir hata oluştu. Yenilemek için aşağı kaydırın.';

  @override
  String get homeContinueWatching => 'İzlemeye devam et';

  @override
  String get homeNoIptvSources =>
      'Etkin IPTV kaynağı yok. Kategorilerinizi görmek için Ayarlar’dan bir kaynak ekleyin.';

  @override
  String get homeNoTrends => 'Trend içerik yok';

  @override
  String get actionRefreshMetadata => 'Meta verileri yenile';

  @override
  String get actionChangeMetadata => 'Meta verileri değiştir';

  @override
  String get actionAddToList => 'Listeye ekle';

  @override
  String get metadataRefreshed => 'Meta veriler yenilendi';

  @override
  String get errorRefreshingMetadata => 'Meta veriler yenilenirken hata';

  @override
  String get actionMarkSeen => 'İzlendi olarak işaretle';

  @override
  String get actionMarkUnseen => 'İzlenmedi olarak işaretle';

  @override
  String get actionReportProblem => 'Sorun bildir';

  @override
  String get featureComingSoon => 'Özellik yakında';

  @override
  String get subtitlesMenuTitle => 'Altyazılar';

  @override
  String get audioMenuTitle => 'Ses';

  @override
  String get videoFitModeMenuTitle => 'Görüntü modu';

  @override
  String get videoFitModeContain => 'Orijinal oran';

  @override
  String get videoFitModeCover => 'Ekranı doldur';

  @override
  String get actionDisable => 'Devre dışı bırak';

  @override
  String defaultTrackLabel(String id) {
    return 'Parça $id';
  }

  @override
  String get controlRewind10 => '10 sn';

  @override
  String get controlRewind30 => '30 sn';

  @override
  String get controlForward10 => '+ 10 sn';

  @override
  String get controlForward30 => '+ 30 sn';

  @override
  String get actionNextEpisode => 'Sonraki bölüm';

  @override
  String get actionRestart => 'Yeniden başlat';

  @override
  String get errorSeriesDataUnavailable => 'Dizi verileri yüklenemedi';

  @override
  String get errorNextEpisodeFailed => 'Sonraki bölüm belirlenemedi';

  @override
  String get actionLoadMore => 'Daha fazla yükle';

  @override
  String get iptvServerUrlLabel => 'Sunucu URL’si';

  @override
  String get iptvServerUrlHint => 'Xtream sunucu URL’si';

  @override
  String get iptvPasswordLabel => 'Şifre';

  @override
  String get iptvPasswordHint => 'Xtream şifresi';

  @override
  String get actionConnect => 'Bağlan';

  @override
  String get settingsRefreshIptvPlaylistsTitle =>
      'IPTV oynatma listelerini yenile';

  @override
  String get activeSourceTitle => 'Etkin kaynak';

  @override
  String get statusActive => 'Etkin';

  @override
  String get statusNoActiveSource => 'Etkin kaynak yok';

  @override
  String get overlayPreparingHome => 'Ana sayfa hazırlanıyor…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Filmler ve diziler yükleniyor…';

  @override
  String get overlayLoadingCategories => 'Kategoriler yükleniyor…';

  @override
  String get bootstrapRefreshing => 'IPTV listeleri yenileniyor…';

  @override
  String get bootstrapEnriching => 'Meta veriler hazırlanıyor…';

  @override
  String get errorPrepareHome => 'Ana sayfa hazırlanamadı';

  @override
  String get overlayOpeningHome => 'Ana sayfa açılıyor…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV listeleri yenileniyor…';

  @override
  String get overlayPreparingMetadata => 'Meta veriler hazırlanıyor…';

  @override
  String get errorHomeLoadTimeout => 'Ana sayfa yükleme zaman aşımı';

  @override
  String get faqLabel => 'SSS';

  @override
  String get iptvUsernameLabel => 'Kullanıcı adı';

  @override
  String get iptvUsernameHint => 'Xtream kullanıcı adı';

  @override
  String get actionBack => 'Geri';

  @override
  String get actionSeeAll => 'Tümünü gör';

  @override
  String get actionExpand => 'Genişlet';

  @override
  String get actionCollapse => 'Daralt';

  @override
  String providerSearchPlaceholder(String provider) {
    return '$provider içinde ara';
  }

  @override
  String get actionClearHistory => 'Geçmişi temizle';

  @override
  String get castTitle => 'Oyuncular';

  @override
  String get recommendationsTitle => 'Öneriler';

  @override
  String get libraryHeader => 'Kütüphaneniz';

  @override
  String get libraryDataInfo =>
      'Veriler, data/domain uygulandığında görüntülenecek.';

  @override
  String get libraryEmpty =>
      'Beğendiğiniz film, dizi veya oyuncular burada görünecek.';

  @override
  String get serie => 'Dizi';

  @override
  String get recherche => 'Ara';

  @override
  String get notYetAvailable => 'Henüz mevcut değil';

  @override
  String get createPlaylistTitle => 'Oynatma listesi oluştur';

  @override
  String get playlistName => 'Oynatma listesi adı';

  @override
  String get addMedia => 'Medya ekle';

  @override
  String get renamePlaylist => 'Yeniden adlandır';

  @override
  String get deletePlaylist => 'Sil';

  @override
  String get pinPlaylist => 'Sabitle';

  @override
  String get unpinPlaylist => 'Sabitlemeyi kaldır';

  @override
  String get playlistPinned => 'Oynatma listesi sabitlendi';

  @override
  String get playlistUnpinned => 'Oynatma listesi sabitlemesi kaldırıldı';

  @override
  String get playlistDeleted => 'Oynatma listesi silindi';

  @override
  String playlistCreatedSuccess(String name) {
    return '\"$name\" oynatma listesi oluşturuldu';
  }

  @override
  String playlistCreateError(String error) {
    return 'Oynatma listesi oluşturulurken hata: $error';
  }

  @override
  String get addedToPlaylist => 'Eklendi';

  @override
  String get pinRecoveryLink => 'PIN’i kurtar';

  @override
  String get pinRecoveryTitle => 'PIN’i kurtar';

  @override
  String get pinRecoveryDescription =>
      'Korumalı profiliniz için PIN’i sıfırlama kodunu alın.';

  @override
  String get pinRecoveryRequestCodeButton => 'Kodu gönder';

  @override
  String get pinRecoveryCodeSentHint =>
      'Kod, hesap e-posta adresinize gönderildi. Mesajlarınızı kontrol edin ve aşağıya girin.';

  @override
  String get pinRecoveryComingSoon => 'Bu özellik yakında geliyor.';

  @override
  String get pinRecoveryNotAvailable =>
      'E-posta ile PIN kurtarma şu anda kullanılamıyor.';

  @override
  String get pinRecoveryCodeLabel => 'Kurtarma kodu';

  @override
  String get pinRecoveryCodeHint => '8 hane';

  @override
  String get pinRecoveryVerifyButton => 'Kodu doğrula';

  @override
  String get pinRecoveryCodeInvalid => '8 haneli kodu girin.';

  @override
  String get pinRecoveryCodeExpired => 'Kurtarma kodunun süresi doldu';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Çok fazla deneme. Daha sonra tekrar deneyin.';

  @override
  String get pinRecoveryUnknownError => 'Beklenmeyen bir hata oluştu';

  @override
  String get pinRecoveryNewPinLabel => 'Yeni PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 hane';

  @override
  String get pinRecoveryConfirmPinLabel => 'PIN’i onayla';

  @override
  String get pinRecoveryConfirmPinHint => 'PIN’i tekrar girin';

  @override
  String get pinRecoveryResetButton => 'PIN’i sıfırla';

  @override
  String get pinRecoveryPinInvalid => '4 ila 6 haneli bir PIN girin.';

  @override
  String get pinRecoveryPinMismatch => 'PIN’ler eşleşmiyor';

  @override
  String get pinRecoveryResetSuccess => 'PIN güncellendi';

  @override
  String get profilePinSaved => 'PIN kaydedildi.';

  @override
  String get profilePinEditLabel => 'PIN kodunu düzenle';

  @override
  String get settingsAccountsSection => 'Hesaplar';

  @override
  String get settingsIptvSection => 'IPTV ayarları';

  @override
  String get settingsSourcesManagement => 'Kaynak yönetimi';

  @override
  String get settingsSyncFrequency => 'Güncelleme sıklığı';

  @override
  String get settingsAppSection => 'Uygulama ayarları';

  @override
  String get settingsAccentColor => 'Vurgu rengi';

  @override
  String get settingsPlaybackSection => 'Oynatma ayarları';

  @override
  String get settingsPreferredAudioLanguage => 'Tercih edilen ses dili';

  @override
  String get settingsPreferredSubtitleLanguage => 'Tercih edilen altyazı dili';

  @override
  String get libraryPlaylistsFilter => 'Oynatma listeleri';

  @override
  String get librarySagasFilter => 'Sagalara';

  @override
  String get libraryArtistsFilter => 'Sanatçılar';

  @override
  String get librarySearchPlaceholder => 'Kütüphanemde ara...';

  @override
  String get libraryInProgress => 'İzlemeye devam et';

  @override
  String get libraryFavoriteMovies => 'Favori filmler';

  @override
  String get libraryFavoriteSeries => 'Favori diziler';

  @override
  String get libraryWatchHistory => 'İzleme geçmişi';

  @override
  String libraryItemCountPlural(int count) {
    return '$count öğe';
  }

  @override
  String get searchPeopleTitle => 'Kişiler';

  @override
  String get searchSagasTitle => 'Sagalara';

  @override
  String get searchByProvidersTitle => 'Sağlayıcılara göre';

  @override
  String get searchByGenresTitle => 'Türlere göre';

  @override
  String get personRoleActor => 'Oyuncu';

  @override
  String get personRoleDirector => 'Yönetmen';

  @override
  String get personRoleCreator => 'Yaratıcı';

  @override
  String get tvDistribution => 'Oyuncular';

  @override
  String tvSeasonLabel(int number) {
    return 'Sezon $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Bölüm yok';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Devam et S$season · B$episode';
  }

  @override
  String get sagaViewPage => 'Sayfayı görüntüle';

  @override
  String get sagaStartNow => 'Şimdi başla';

  @override
  String get sagaContinue => 'Devam';

  @override
  String sagaMovieCount(int count) {
    return '$count film';
  }

  @override
  String get sagaMoviesList => 'Film listesi';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies film - $shows dizi';
  }

  @override
  String get personPlayRandomly => 'Rastgele oynat';

  @override
  String get personMoviesList => 'Film listesi';

  @override
  String get personSeriesList => 'Dizi listesi';

  @override
  String get playlistPlayRandomly => 'Rastgele oynat';

  @override
  String get playlistAddButton => 'Çalma listesine ekle';

  @override
  String get playlistSortButton => 'Sırala';

  @override
  String get playlistSortByTitle => 'Sırala';

  @override
  String get playlistSortByTitleOption => 'Başlık';

  @override
  String get playlistSortRecentAdditions => 'Son eklenenler';

  @override
  String get playlistSortOldestFirst => 'Önce en eski';

  @override
  String get playlistSortNewestFirst => 'Önce en yeni';

  @override
  String get playlistEmptyMessage => 'Bu oynatma listesinde öğe yok';

  @override
  String playlistItemCount(int count) {
    return '$count öğe';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count öğe';
  }

  @override
  String get playlistSeasonSingular => 'sezon';

  @override
  String get playlistSeasonPlural => 'sezon';

  @override
  String get playlistRenameTitle => 'Oynatma listesini yeniden adlandır';

  @override
  String get playlistNamePlaceholder => 'Oynatma listesi adı';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Oynatma listesinin adı \"$name\" olarak değiştirildi';
  }

  @override
  String get playlistDeleteTitle => 'Çalma listesini sil';

  @override
  String playlistDeleteConfirm(String title) {
    return '\"$title\" silinsin mi?';
  }

  @override
  String get playlistDeletedSuccess => 'Oynatma listesi silindi';

  @override
  String get playlistItemRemovedSuccess => 'Öğe kaldırıldı';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '\"$title\" oynatma listesinden kaldırılsın mı?';
  }

  @override
  String get categoryLoadFailed => 'Kategori yüklenemedi.';

  @override
  String get categoryEmpty => 'Bu kategoride öğe yok.';

  @override
  String get categoryLoadingMore => 'Daha fazlası yükleniyor…';

  @override
  String get movieNoPlaylistsAvailable => 'Oynatma listesi yok';

  @override
  String playlistAddedTo(String title) {
    return '\"$title\" listesine eklendi';
  }

  @override
  String errorWithMessage(String message) {
    return 'Hata: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Film oynatma listesinde mevcut değil';

  @override
  String errorPlaybackFailed(String message) {
    return 'Film oynatılırken hata: $message';
  }

  @override
  String get movieNoMedia => 'Gösterilecek medya yok';

  @override
  String get personNoData => 'Gösterilecek kişi yok.';

  @override
  String get personGenericError => 'Bu kişi yüklenirken hata oluştu.';

  @override
  String get personBiographyTitle => 'Biyografi';

  @override
  String get authOtpTitle => 'Giriş yap';

  @override
  String get authOtpSubtitle =>
      'E-posta adresinizi ve size gönderdiğimiz 8 haneli kodu girin.';

  @override
  String get authOtpEmailLabel => 'E‑posta';

  @override
  String get authOtpEmailHint => 'you@email';

  @override
  String get authOtpEmailHelp =>
      '8 haneli bir kod göndereceğiz. Gerekirse spam klasörünü kontrol edin.';

  @override
  String get authOtpCodeLabel => 'Doğrulama kodu';

  @override
  String get authOtpCodeHint => '8 haneli kod';

  @override
  String get authOtpCodeHelp => 'E-posta ile gönderilen 8 haneli kodu girin.';

  @override
  String get authOtpPrimarySend => 'Kodu gönder';

  @override
  String get authOtpPrimarySubmit => 'Giriş yap';

  @override
  String get authOtpResend => 'Kodu tekrar gönder';

  @override
  String authOtpResendDisabled(int seconds) {
    return '$seconds sn sonra yeniden gönder';
  }

  @override
  String get authOtpChangeEmail => 'E‑postayı değiştir';

  @override
  String get resumePlayback => 'Oynatmaya devam et';

  @override
  String get settingsCloudSyncSection => 'Bulut senkronizasyonu';

  @override
  String get settingsCloudSyncAuto => 'Otomatik senkronizasyon';

  @override
  String get settingsCloudSyncNow => 'Şimdi senkronize et';

  @override
  String get settingsCloudSyncInProgress => 'Senkronize ediliyor…';

  @override
  String get settingsCloudSyncNever => 'Asla';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Son hata: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity bulunamadı';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity bulunamadı: $error';
  }

  @override
  String get entityProvider => 'Sağlayıcı';

  @override
  String get entityGenre => 'Tür';

  @override
  String get entityPlaylist => 'Oynatma listesi';

  @override
  String get entitySource => 'Kaynak';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Dizi';

  @override
  String get entityPerson => 'Kişi';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Video';

  @override
  String get entityRoute => 'Rota';

  @override
  String get errorTimeoutLoading => 'Yükleme zaman aşımına uğradı';

  @override
  String get parentalContentRestricted => 'Kısıtlı içerik';

  @override
  String get parentalContentRestrictedDefault =>
      'Bu içerik, bu profilin ebeveyn denetimleri tarafından engellendi.';

  @override
  String get parentalReasonTooYoung =>
      'Bu içerik, bu profilin sınırından daha yüksek bir yaş gerektirir.';

  @override
  String get parentalReasonUnknownRating =>
      'Bu içerik için yaş derecelendirmesi mevcut değil.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Bu içerik ebeveyn denetimi için değerlendirilemiyor.';

  @override
  String get parentalUnlockButton => 'Kilidi aç';

  @override
  String get actionOk => 'Tamam';

  @override
  String get actionSignOut => 'Çıkış yap';

  @override
  String get dialogSignOutBody => 'Çıkış yapmak istediğine emin misin?';

  @override
  String get settingsUnableToOpenLink => 'Bağlantı açılamadı';

  @override
  String get settingsSyncDisabled => 'Devre dışı';

  @override
  String get settingsSyncEveryHour => 'Her saat';

  @override
  String get settingsSyncEvery2Hours => '2 saatte bir';

  @override
  String get settingsSyncEvery4Hours => '4 saatte bir';

  @override
  String get settingsSyncEvery6Hours => '6 saatte bir';

  @override
  String get settingsSyncEveryDay => 'Her gün';

  @override
  String get settingsSyncEvery2Days => '2 günde bir';

  @override
  String get settingsColorCustom => 'Özel';

  @override
  String get settingsColorBlue => 'Mavi';

  @override
  String get settingsColorPink => 'Pembe';

  @override
  String get settingsColorGreen => 'Yeşil';

  @override
  String get settingsColorPurple => 'Mor';

  @override
  String get settingsColorOrange => 'Turuncu';

  @override
  String get settingsColorTurquoise => 'Turkuaz';

  @override
  String get settingsColorYellow => 'Sarı';

  @override
  String get settingsColorIndigo => 'İndigo';

  @override
  String get settingsCloudAccountTitle => 'Bulut hesabı';

  @override
  String get settingsAccountConnected => 'Bağlı';

  @override
  String get settingsAccountLocalMode => 'Yerel mod';

  @override
  String get settingsAccountCloudUnavailable => 'Bulut kullanılamıyor';

  @override
  String get settingsSubtitlesTitle => 'Altyazılar';

  @override
  String get settingsSubtitlesSizeTitle => 'Metin boyutu';

  @override
  String get settingsSubtitlesColorTitle => 'Metin rengi';

  @override
  String get settingsSubtitlesFontTitle => 'Yazı tipi';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Sistem';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Hızlı ayarlar';

  @override
  String get settingsSubtitlesPreviewTitle => 'Önizleme';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Bu bir altyazı önizlemesidir.\nOkunabilirliği anlık olarak ayarlayın.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Arka plan';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Arka plan opaklığı';

  @override
  String get settingsSubtitlesShadowTitle => 'Gölge';

  @override
  String get settingsSubtitlesShadowOff => 'Kapalı';

  @override
  String get settingsSubtitlesShadowSoft => 'Yumuşak';

  @override
  String get settingsSubtitlesShadowStrong => 'Güçlü';

  @override
  String get settingsSubtitlesFineSizeTitle => 'İnce boyut';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Ölçek';

  @override
  String get settingsSubtitlesResetDefaults => 'Varsayılana sıfırla';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Gelişmiş altyazı stili (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Arka plan, opaklık, gölge önayarları ve ince boyut Movi Premium ile kullanılabilir.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Premium ile aç';

  @override
  String get settingsSyncSectionTitle => 'Ses/altyazı senkronu';

  @override
  String get settingsSubtitleOffsetTitle => 'Altyazı gecikmesi';

  @override
  String get settingsAudioOffsetTitle => 'Ses gecikmesi';

  @override
  String get settingsOffsetUnsupported =>
      'Bu arka uçta veya platformda desteklenmiyor.';

  @override
  String get settingsSyncResetOffsets => 'Senkron gecikmelerini sıfırla';

  @override
  String get aboutTmdbDisclaimer =>
      'Bu ürün TMDB API\'sini kullanır ancak TMDB tarafından desteklenmez veya sertifikalandırılmaz.';

  @override
  String get aboutCreditsSectionTitle => 'Katkıda bulunanlar';

  @override
  String get actionSend => 'Gönder';

  @override
  String get profilePinSetLabel => 'PIN kodu belirle';

  @override
  String get reportingProblemSentConfirmation =>
      'Bildirim gönderildi. Teşekkürler.';

  @override
  String get reportingProblemBody =>
      'Bu içerik uygun değilse ve kısıtlamalara rağmen erişilebildiyse, sorunu kısaca açıklayın.';

  @override
  String get reportingProblemExampleHint =>
      'Örnek: PEGI 12 olmasına rağmen korku filmi görünüyor';

  @override
  String get settingsAutomaticOption => 'Otomatik';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Tercih edilen oynatma kalitesi';

  @override
  String settingsSignOutError(String error) {
    return 'Oturum kapatılırken hata: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Kullanım koşulları';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Bulut senkronizasyonu için Movi Premium gerekir.';
}
