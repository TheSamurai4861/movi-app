// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get welcomeTitle => 'ようこそ！';

  @override
  String get welcomeSubtitle => '好みを入力して Movi をカスタマイズしましょう。';

  @override
  String get labelUsername => 'ニックネーム';

  @override
  String get labelPreferredLanguage => '優先言語';

  @override
  String get actionContinue => '続ける';

  @override
  String get hintUsername => 'ニックネーム';

  @override
  String get errorFillFields => '入力内容を確認してください。';

  @override
  String get homeWatchNow => '視聴';

  @override
  String get welcomeSourceTitle => 'ようこそ！';

  @override
  String get welcomeSourceSubtitle => 'ソースを追加して Movi の体験をカスタマイズしましょう。';

  @override
  String get welcomeSourceAdd => 'ソースを追加';

  @override
  String get searchTitle => '検索';

  @override
  String get searchHint => '検索語を入力';

  @override
  String get clear => 'クリア';

  @override
  String get moviesTitle => '映画';

  @override
  String get seriesTitle => '番組';

  @override
  String get noResults => '結果がありません';

  @override
  String get historyTitle => '履歴';

  @override
  String get historyEmpty => '最近の検索はありません';

  @override
  String get delete => '削除';

  @override
  String resultsCount(int count) {
    return '（$count 件）';
  }

  @override
  String get errorUnknown => '不明なエラー';

  @override
  String errorConnectionFailed(String error) {
    return '接続に失敗しました: $error';
  }

  @override
  String get errorConnectionGeneric => '接続に失敗しました';

  @override
  String get validationRequired => '必須';

  @override
  String get validationInvalidUrl => '無効な URL';

  @override
  String get snackbarSourceAddedBackground => 'IPTV ソースを追加しました。バックグラウンドで同期中…';

  @override
  String get snackbarSourceAddedSynced => 'IPTV ソースを追加し、同期しました';

  @override
  String get navHome => 'ホーム';

  @override
  String get navSearch => '検索';

  @override
  String get navLibrary => 'ライブラリ';

  @override
  String get navSettings => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguageLabel => 'アプリの言語';

  @override
  String get settingsGeneralTitle => '一般設定';

  @override
  String get settingsDarkModeTitle => 'ダークモード';

  @override
  String get settingsDarkModeSubtitle => '目に優しいテーマを有効にします。';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsNotificationsSubtitle => '新着情報を通知します。';

  @override
  String get settingsAccountTitle => 'アカウント';

  @override
  String get settingsProfileInfoTitle => 'プロフィール情報';

  @override
  String get settingsProfileInfoSubtitle => '名前、アバター、設定';

  @override
  String get settingsAboutTitle => 'このアプリについて';

  @override
  String get settingsLegalMentionsTitle => '法的情報';

  @override
  String get settingsPrivacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionConfirm => '確認';

  @override
  String get actionRetry => '再試行';

  @override
  String get settingsHelpDiagnosticsSection => 'ヘルプと診断';

  @override
  String get settingsExportErrorLogs => 'エラーログを書き出し';

  @override
  String get diagnosticsExportTitle => 'エラーログを書き出し';

  @override
  String get diagnosticsExportDescription =>
      '診断には最新の WARN/ERROR ログと（有効時）ハッシュ化されたアカウント/プロフィール ID のみが含まれます。キー/トークンは含まれないはずです。';

  @override
  String get diagnosticsIncludeHashedIdsTitle => 'アカウント/プロフィール ID（ハッシュ）を含める';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      '生の ID を公開せずに不具合の関連付けに役立ちます。';

  @override
  String get diagnosticsCopiedClipboard => '診断情報をクリップボードにコピーしました。';

  @override
  String diagnosticsSavedFile(String fileName) {
    return '診断情報を保存しました: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'コピー';

  @override
  String get diagnosticsActionSave => '保存';

  @override
  String get actionChangeVersion => 'バージョンを変更';

  @override
  String get semanticsBack => '戻る';

  @override
  String get semanticsMoreActions => 'その他の操作';

  @override
  String get snackbarLoadingPlaylists => 'プレイリストを読み込み中…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      '利用可能なプレイリストがありません。作成してください。';

  @override
  String errorAddToPlaylist(String error) {
    return 'プレイリストに追加できませんでした: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'このメディアは既にこのプレイリストにあります';

  @override
  String errorLoadingPlaylists(String message) {
    return 'プレイリストの読み込み中にエラー: $message';
  }

  @override
  String get errorReportUnavailableForContent => 'このコンテンツでは報告機能を利用できません。';

  @override
  String get snackbarLoadingEpisodes => 'エピソードを読み込み中…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist => 'このエピソードはプレイリストで利用できません';

  @override
  String snackbarGenericError(String error) {
    return 'エラー: $error';
  }

  @override
  String get snackbarLoading => '読み込み中…';

  @override
  String get snackbarNoVersionAvailable => '利用可能なバージョンがありません';

  @override
  String get snackbarVersionSaved => 'バージョンを保存しました';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'バージョン $index';
  }

  @override
  String get actionReadMore => 'もっと見る';

  @override
  String get actionShowLess => '折りたたむ';

  @override
  String get actionViewPage => 'ページを見る';

  @override
  String get semanticsSeeSagaPage => 'サーガのページを見る';

  @override
  String get libraryTypeSaga => 'サーガ';

  @override
  String get libraryTypeInProgress => '視聴中';

  @override
  String get libraryTypeFavoriteMovies => 'お気に入りの映画';

  @override
  String get libraryTypeFavoriteSeries => 'お気に入りの番組';

  @override
  String get libraryTypeHistory => '履歴';

  @override
  String get libraryTypePlaylist => 'プレイリスト';

  @override
  String get libraryTypeArtist => 'アーティスト';

  @override
  String libraryItemCount(int count) {
    return '$count 件';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'プレイリスト名を「$name」に変更しました';
  }

  @override
  String get snackbarPlaylistDeleted => 'プレイリストを削除しました';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return '「$query」の結果がありません';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'エラー: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist => 'このメディアは既にプレイリストにあります';

  @override
  String get snackbarAddedToPlaylist => 'プレイリストに追加しました';

  @override
  String get addMediaTitle => 'メディアを追加';

  @override
  String get searchMinCharsHint => '検索には 3 文字以上入力してください';

  @override
  String get badgeAdded => '追加済み';

  @override
  String get snackbarNotAvailableOnSource => 'このソースでは利用できません';

  @override
  String get errorLoadingTitle => '読み込みエラー';

  @override
  String errorLoadingWithMessage(String error) {
    return '読み込みエラー: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'プレイリストの読み込み中にエラー: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'フィルターをクリア';

  @override
  String get homeErrorSwipeToRetry => 'エラーが発生しました。下にスワイプして再試行してください。';

  @override
  String get homeContinueWatching => '続きを見る';

  @override
  String get homeNoIptvSources =>
      '有効な IPTV ソースがありません。設定からソースを追加するとカテゴリが表示されます。';

  @override
  String get homeNoTrends => 'トレンドのコンテンツがありません';

  @override
  String get actionRefreshMetadata => 'メタデータを更新';

  @override
  String get actionChangeMetadata => 'メタデータを変更';

  @override
  String get actionAddToList => 'リストに追加';

  @override
  String get metadataRefreshed => 'メタデータを更新しました';

  @override
  String get errorRefreshingMetadata => 'メタデータ更新中にエラーが発生しました';

  @override
  String get actionMarkSeen => '視聴済みにする';

  @override
  String get actionMarkUnseen => '未視聴にする';

  @override
  String get actionReportProblem => '問題を報告';

  @override
  String get featureComingSoon => '近日公開';

  @override
  String get subtitlesMenuTitle => '字幕';

  @override
  String get audioMenuTitle => '音声';

  @override
  String get videoFitModeMenuTitle => '表示モード';

  @override
  String get videoFitModeContain => '元の比率';

  @override
  String get videoFitModeCover => '画面に合わせる';

  @override
  String get actionDisable => '無効';

  @override
  String defaultTrackLabel(String id) {
    return 'トラック $id';
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
  String get actionNextEpisode => '次のエピソード';

  @override
  String get actionRestart => '最初から';

  @override
  String get errorSeriesDataUnavailable => '番組データを読み込めません';

  @override
  String get errorNextEpisodeFailed => '次のエピソードを特定できません';

  @override
  String get actionLoadMore => 'さらに読み込む';

  @override
  String get iptvServerUrlLabel => 'サーバー URL';

  @override
  String get iptvServerUrlHint => 'Xtream サーバー URL';

  @override
  String get iptvPasswordLabel => 'パスワード';

  @override
  String get iptvPasswordHint => 'Xtream パスワード';

  @override
  String get actionConnect => '接続';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'IPTV プレイリストを更新';

  @override
  String get activeSourceTitle => '有効なソース';

  @override
  String get statusActive => '有効';

  @override
  String get statusNoActiveSource => '有効なソースがありません';

  @override
  String get overlayPreparingHome => 'ホームを準備中…';

  @override
  String get overlayLoadingMoviesAndSeries => '映画とドラマを読み込み中…';

  @override
  String get overlayLoadingCategories => 'カテゴリを読み込み中…';

  @override
  String get bootstrapRefreshing => 'IPTV リストを更新中…';

  @override
  String get bootstrapEnriching => 'メタデータを準備中…';

  @override
  String get errorPrepareHome => 'ホームを準備できません';

  @override
  String get overlayOpeningHome => 'ホームを開いています…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV リストを更新中…';

  @override
  String get overlayPreparingMetadata => 'メタデータを準備中…';

  @override
  String get errorHomeLoadTimeout => 'ホームの読み込みがタイムアウトしました';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'ユーザー名';

  @override
  String get iptvUsernameHint => 'Xtream ユーザー名';

  @override
  String get actionBack => '戻る';

  @override
  String get actionSeeAll => 'すべて表示';

  @override
  String get actionExpand => '展開';

  @override
  String get actionCollapse => '折りたたむ';

  @override
  String providerSearchPlaceholder(String provider) {
    return '$provider で検索…';
  }

  @override
  String get actionClearHistory => '履歴を消去';

  @override
  String get castTitle => 'キャスト';

  @override
  String get recommendationsTitle => 'おすすめ';

  @override
  String get libraryHeader => 'あなたのライブラリ';

  @override
  String get libraryDataInfo => 'データ/ドメインが実装されると表示されます。';

  @override
  String get libraryEmpty => '映画・番組・人物を「いいね」するとここに表示されます。';

  @override
  String get serie => '番組';

  @override
  String get recherche => '検索';

  @override
  String get notYetAvailable => 'まだ利用できません';

  @override
  String get createPlaylistTitle => 'プレイリストを作成';

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get addMedia => 'メディアを追加';

  @override
  String get renamePlaylist => '名前を変更';

  @override
  String get deletePlaylist => '削除';

  @override
  String get pinPlaylist => 'ピン留め';

  @override
  String get unpinPlaylist => 'ピン留め解除';

  @override
  String get playlistPinned => 'プレイリストをピン留めしました';

  @override
  String get playlistUnpinned => 'プレイリストのピン留めを解除しました';

  @override
  String get playlistDeleted => 'プレイリストを削除しました';

  @override
  String playlistCreatedSuccess(String name) {
    return 'プレイリスト「$name」を作成しました';
  }

  @override
  String playlistCreateError(String error) {
    return 'プレイリスト作成中にエラー: $error';
  }

  @override
  String get addedToPlaylist => '追加済み';

  @override
  String get pinRecoveryLink => 'PIN コードを復元';

  @override
  String get pinRecoveryTitle => 'PIN コードを復元';

  @override
  String get pinRecoveryDescription => '保護されたプロフィールの PIN コードを取得します。';

  @override
  String get pinRecoveryComingSoon => 'この機能は近日公開です。';

  @override
  String get pinRecoveryCodeLabel => '復元コード';

  @override
  String get pinRecoveryCodeHint => '8 桁';

  @override
  String get pinRecoveryVerifyButton => '確認';

  @override
  String get pinRecoveryCodeInvalid => '8 桁のコードを入力してください';

  @override
  String get pinRecoveryCodeExpired => '復元コードの有効期限が切れています';

  @override
  String get pinRecoveryTooManyAttempts => '試行回数が多すぎます。しばらくしてから再試行してください。';

  @override
  String get pinRecoveryUnknownError => '予期しないエラーが発生しました';

  @override
  String get pinRecoveryNewPinLabel => '新しい PIN';

  @override
  String get pinRecoveryNewPinHint => '4〜6 桁';

  @override
  String get pinRecoveryConfirmPinLabel => 'PIN を確認';

  @override
  String get pinRecoveryConfirmPinHint => 'PIN を再入力';

  @override
  String get pinRecoveryResetButton => 'PIN を更新';

  @override
  String get pinRecoveryPinInvalid => '4〜6 桁の PIN を入力してください';

  @override
  String get pinRecoveryPinMismatch => 'PIN が一致しません';

  @override
  String get pinRecoveryResetSuccess => 'PIN を更新しました';

  @override
  String get settingsAccountsSection => 'アカウント';

  @override
  String get settingsIptvSection => 'IPTV 設定';

  @override
  String get settingsSourcesManagement => 'ソース管理';

  @override
  String get settingsSyncFrequency => '更新頻度';

  @override
  String get settingsAppSection => 'アプリ設定';

  @override
  String get settingsAccentColor => 'アクセントカラー';

  @override
  String get settingsPlaybackSection => '再生設定';

  @override
  String get settingsPreferredAudioLanguage => '優先言語';

  @override
  String get settingsPreferredSubtitleLanguage => '優先字幕';

  @override
  String get libraryPlaylistsFilter => 'プレイリスト';

  @override
  String get librarySagasFilter => 'サーガ';

  @override
  String get libraryArtistsFilter => 'アーティスト';

  @override
  String get librarySearchPlaceholder => 'ライブラリ内を検索…';

  @override
  String get libraryInProgress => '視聴中';

  @override
  String get libraryFavoriteMovies => 'お気に入りの映画';

  @override
  String get libraryFavoriteSeries => 'お気に入りの番組';

  @override
  String get libraryWatchHistory => '視聴履歴';

  @override
  String libraryItemCountPlural(int count) {
    return '$count 件';
  }

  @override
  String get searchPeopleTitle => '人物';

  @override
  String get searchSagasTitle => 'サーガ';

  @override
  String get searchByProvidersTitle => '配信元';

  @override
  String get searchByGenresTitle => 'ジャンル';

  @override
  String get personRoleActor => '俳優';

  @override
  String get personRoleDirector => '監督';

  @override
  String get personRoleCreator => 'クリエイター';

  @override
  String get tvDistribution => 'キャスト';

  @override
  String tvSeasonLabel(int number) {
    return 'シーズン $number';
  }

  @override
  String get tvNoEpisodesAvailable => '利用可能なエピソードがありません';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return '続きから S$season E$episode';
  }

  @override
  String get sagaViewPage => 'ページを見る';

  @override
  String get sagaStartNow => '今すぐ開始';

  @override
  String get sagaContinue => '続ける';

  @override
  String sagaMovieCount(int count) {
    return '$count 本';
  }

  @override
  String get sagaMoviesList => '映画一覧';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies 本 - $shows 本';
  }

  @override
  String get personPlayRandomly => 'ランダム再生';

  @override
  String get personMoviesList => '映画一覧';

  @override
  String get personSeriesList => '番組一覧';

  @override
  String get playlistPlayRandomly => 'ランダム再生';

  @override
  String get playlistAddButton => '追加';

  @override
  String get playlistSortButton => '並べ替え';

  @override
  String get playlistSortByTitle => '並べ替え';

  @override
  String get playlistSortByTitleOption => 'タイトル';

  @override
  String get playlistSortRecentAdditions => '追加順（新しい）';

  @override
  String get playlistSortOldestFirst => '追加順（古い）';

  @override
  String get playlistSortNewestFirst => '追加順（新しい）';

  @override
  String get playlistEmptyMessage => 'このプレイリストには項目がありません';

  @override
  String playlistItemCount(int count) {
    return '$count 件';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count 件';
  }

  @override
  String get playlistSeasonSingular => 'シーズン';

  @override
  String get playlistSeasonPlural => 'シーズン';

  @override
  String get playlistRenameTitle => 'プレイリスト名を変更';

  @override
  String get playlistNamePlaceholder => 'プレイリスト名';

  @override
  String playlistRenamedSuccess(String name) {
    return 'プレイリスト名を「$name」に変更しました';
  }

  @override
  String get playlistDeleteTitle => '削除';

  @override
  String playlistDeleteConfirm(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get playlistDeletedSuccess => 'プレイリストを削除しました';

  @override
  String get playlistItemRemovedSuccess => '項目を削除しました';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '「$title」をプレイリストから削除しますか？';
  }

  @override
  String get categoryLoadFailed => 'カテゴリを読み込めませんでした。';

  @override
  String get categoryEmpty => 'このカテゴリに項目がありません。';

  @override
  String get categoryLoadingMore => 'さらに読み込み中…';

  @override
  String get movieNoPlaylistsAvailable => '利用可能なプレイリストがありません';

  @override
  String playlistAddedTo(String title) {
    return '「$title」に追加しました';
  }

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'この映画はプレイリストで利用できません';

  @override
  String errorPlaybackFailed(String message) {
    return '再生に失敗しました: $message';
  }

  @override
  String get movieNoMedia => '表示できるメディアがありません';

  @override
  String get personNoData => '表示できる人物がいません。';

  @override
  String get personGenericError => '人物情報の読み込み中にエラーが発生しました。';

  @override
  String get personBiographyTitle => '略歴';

  @override
  String get authOtpTitle => 'サインイン';

  @override
  String get authOtpSubtitle => 'メールアドレスと送信された 8 桁のコードを入力してください。';

  @override
  String get authOtpEmailLabel => 'メール';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp => '8 桁のコードを送信します。必要に応じて迷惑メールも確認してください。';

  @override
  String get authOtpCodeLabel => '確認コード';

  @override
  String get authOtpCodeHint => '8 桁のコード';

  @override
  String get authOtpCodeHelp => 'メールで受け取った 8 桁のコードを入力してください。';

  @override
  String get authOtpPrimarySend => 'コードを送信';

  @override
  String get authOtpPrimarySubmit => 'サインイン';

  @override
  String get authOtpResend => 'コードを再送';

  @override
  String authOtpResendDisabled(int seconds) {
    return '$seconds 秒後に再送';
  }

  @override
  String get authOtpChangeEmail => 'メールを変更';

  @override
  String get resumePlayback => '再生を再開';

  @override
  String get settingsCloudSyncSection => 'クラウド同期';

  @override
  String get settingsCloudSyncAuto => '自動同期';

  @override
  String get settingsCloudSyncNow => '今すぐ同期';

  @override
  String get settingsCloudSyncInProgress => '同期中…';

  @override
  String get settingsCloudSyncNever => 'しない';

  @override
  String settingsCloudSyncError(Object error) {
    return '直近のエラー: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity が見つかりません';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity が見つかりません: $error';
  }

  @override
  String get entityProvider => '配信元';

  @override
  String get entityGenre => 'ジャンル';

  @override
  String get entityPlaylist => 'プレイリスト';

  @override
  String get entitySource => 'ソース';

  @override
  String get entityMovie => '映画';

  @override
  String get entitySeries => '番組';

  @override
  String get entityPerson => '人物';

  @override
  String get entitySaga => 'サーガ';

  @override
  String get entityVideo => '動画';

  @override
  String get entityRoute => 'ルート';

  @override
  String get errorTimeoutLoading => '読み込みがタイムアウトしました';

  @override
  String get parentalContentRestricted => '制限されたコンテンツ';

  @override
  String get parentalContentRestrictedDefault =>
      'このコンテンツはこのプロフィールのペアレンタルコントロールでブロックされています。';

  @override
  String get parentalReasonTooYoung => 'このコンテンツはプロフィールの上限より高い年齢が必要です。';

  @override
  String get parentalReasonUnknownRating => 'このコンテンツの年齢レーティングがありません。';

  @override
  String get parentalReasonInvalidTmdbId => 'このコンテンツはペアレンタルコントロールで評価できません。';

  @override
  String get parentalUnlockButton => '解除';

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
  String get hc_chargement_episodes_en_cours_33fc4ace => 'エピソードを読み込み中…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      '利用可能なプレイリストがありません。作成してください。';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'プレイリストの読み込み中にエラー: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => 'リンクを開けません';

  @override
  String get hc_qualite_preferee_776dbeea => '優先品質';

  @override
  String get hc_annuler_49ba3292 => 'キャンセル';

  @override
  String get hc_deconnexion_903dca17 => 'サインアウト';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'サインアウト中にエラー: \$e';

  @override
  String get hc_choisir_b030d590 => '選択';

  @override
  String get hc_avantages_08d7f47c => '特典';

  @override
  String get hc_signalement_envoye_merci_d302e576 => '報告を送信しました。ありがとうございます。';

  @override
  String get hc_plus_tard_1f42ab3b => '後で';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => '今すぐ再起動';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'このソースを使用しますか？';

  @override
  String get hc_utiliser_fb5e43ce => '使用する';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'ソースを追加しました';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'ロックされた設定';

  @override
  String get hc_compte_cloud_2812b31e => 'クラウドアカウント';

  @override
  String get hc_se_connecter_fedf2439 => 'サインイン';

  @override
  String get hc_propos_5345add5 => 'このアプリについて';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'プライバシーポリシー';

  @override
  String get hc_conditions_dutilisation_9074eac7 => '利用規約';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => '保存済みソース';

  @override
  String get hc_rafraichir_be30b7d1 => '更新';

  @override
  String get hc_activer_une_source_749ced38 => 'ソースを有効化';

  @override
  String get hc_nom_source_9a3e4156 => 'ソース名';

  @override
  String get hc_mon_iptv_b239352c => 'マイ IPTV';

  @override
  String get hc_username_84c29015 => 'ユーザー名';

  @override
  String get hc_password_8be3c943 => 'パスワード';

  @override
  String get hc_server_url_1d5d1eff => 'サーバー URL';

  @override
  String get hc_verification_pin_e17c8fe0 => 'PIN の確認';

  @override
  String get hc_definir_un_pin_f9c2178d => 'PIN を設定';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'サブスクリプションのオファーが見つかりません: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'サブスクリプション購入はユーザーによりキャンセルされました。';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'ストア操作がタイムアウトしました: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 => 'ハンドシェイク中の HTTP エラー';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Xtream サーバーから JSON ではない応答';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'Xtream サーバーから無効な応答';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 => 'このソースでは利用できません';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'ソースを削除しました';

  @override
  String get hc_source_modifiee_335ef502 => 'ソースを更新しました';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'PIN コードを設定';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => '未視聴にする';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'サインアウトしますか？';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'クラウド同期には Movi Premium が必要です。';

  @override
  String get hc_auto_c614ba7c => '自動';

  @override
  String get hc_organiser_838a7e57 => '並べ替え';

  @override
  String get hc_modifier_f260e757 => '編集';

  @override
  String get hc_ajouter_87c57ed1 => '追加';

  @override
  String get hc_source_active_e571305e => '有効なソース';

  @override
  String get hc_autres_sources_e32592a6 => 'その他のソース';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'このコンテンツでは報告機能を利用できません。';

  @override
  String get hc_securisation_contenu_e5195111 => 'コンテンツを保護中';

  @override
  String get hc_verification_classifications_d_age_006eebfe => '年齢レーティングを確認中…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'すべて表示';

  @override
  String get hc_signaler_un_probleme_13183c0f => '問題を報告';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      '不適切なコンテンツが制限にもかかわらず表示された場合、問題を簡単に説明してください。';

  @override
  String get hc_envoyer_e9ce243b => '送信';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => '子どもプロフィールを作成しました';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      '子どもプロフィールを作成しました。アプリの保護と年齢レーティングの事前読み込みのため、アプリの再起動をおすすめします。';

  @override
  String get hc_pseudo_4cf966c0 => 'ニックネーム';

  @override
  String get hc_profil_enfant_2c8a01c0 => '子どもプロフィール';

  @override
  String get hc_limite_d_age_5b170fc9 => '年齢上限';

  @override
  String get hc_code_pin_e79c48bd => 'PIN コード';

  @override
  String get hc_changer_code_pin_3b069731 => 'PIN コードを変更';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'PIN コードを削除';

  @override
  String get hc_supprimer_pin_51850c7b => 'PIN を削除';

  @override
  String get hc_supprimer_1acfc1c7 => '削除';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'PIN が必須になり、PEGI フィルターが有効になります。';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'このソースを今すぐ有効にしますか？';

  @override
  String get hc_application_b291beb8 => 'アプリ';

  @override
  String get hc_version_1_0_0_347e553c => 'バージョン 1.0.0';

  @override
  String get hc_credits_293a6081 => 'クレジット';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      '本製品は TMDB API を使用していますが、TMDB によって承認または認定されていません。';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      '本製品は TMDB API を使用していますが、TMDB によって承認または認定されていません。';

  @override
  String get hc_verification_targets_d51632f8 => '検証対象';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 => 'フェードはフレームに溶け込む必要があります';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 => '無効な Xtream streamId: ...';

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
  String get hc_url_invalide_aa227a66 => '無効な URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'更新\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'メニュー\'';

  @override
  String get hc_retour_e5befb1f => '戻る';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'その他の操作\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'その他の操作';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c => 'semanticLabel: \'検索\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'追加\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'ログアウト';

  @override
  String get dialogSignOutBody => 'ログアウトしますか？';

  @override
  String get settingsUnableToOpenLink => 'リンクを開けませんでした';

  @override
  String get settingsSyncDisabled => '無効';

  @override
  String get settingsSyncEveryHour => '1時間ごと';

  @override
  String get settingsSyncEvery2Hours => '2時間ごと';

  @override
  String get settingsSyncEvery4Hours => '4時間ごと';

  @override
  String get settingsSyncEvery6Hours => '6時間ごと';

  @override
  String get settingsSyncEveryDay => '毎日';

  @override
  String get settingsSyncEvery2Days => '2日ごと';

  @override
  String get settingsColorCustom => 'カスタム';

  @override
  String get settingsColorBlue => '青';

  @override
  String get settingsColorPink => 'ピンク';

  @override
  String get settingsColorGreen => '緑';

  @override
  String get settingsColorPurple => '紫';

  @override
  String get settingsColorOrange => 'オレンジ';

  @override
  String get settingsColorTurquoise => 'ターコイズ';

  @override
  String get settingsColorYellow => '黄';

  @override
  String get settingsColorIndigo => 'インディゴ';

  @override
  String get settingsCloudAccountTitle => 'クラウドアカウント';

  @override
  String get settingsAccountConnected => '接続済み';

  @override
  String get settingsAccountLocalMode => 'ローカルモード';

  @override
  String get settingsAccountCloudUnavailable => 'クラウド利用不可';

  @override
  String get settingsSubtitlesTitle => '字幕';

  @override
  String get settingsSubtitlesSizeTitle => '文字サイズ';

  @override
  String get settingsSubtitlesColorTitle => '文字色';

  @override
  String get settingsSubtitlesFontTitle => 'フォント';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'システム';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'クイック設定';

  @override
  String get settingsSubtitlesPreviewTitle => 'プレビュー';

  @override
  String get settingsSubtitlesPreviewSample =>
      'これは字幕のプレビューです。\n読みやすさをリアルタイムで調整できます。';

  @override
  String get settingsSubtitlesBackgroundTitle => '背景';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => '背景の不透明度';

  @override
  String get settingsSubtitlesShadowTitle => '影';

  @override
  String get settingsSubtitlesShadowOff => 'オフ';

  @override
  String get settingsSubtitlesShadowSoft => '弱';

  @override
  String get settingsSubtitlesShadowStrong => '強';

  @override
  String get settingsSubtitlesFineSizeTitle => '細かなサイズ';

  @override
  String get settingsSubtitlesFineSizeValueLabel => '倍率';

  @override
  String get settingsSubtitlesResetDefaults => 'デフォルトに戻す';

  @override
  String get settingsSubtitlesPremiumLockedTitle => '高度な字幕スタイル（Premium）';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      '背景、不透明度、影プリセット、細かなサイズは Movi Premium で利用できます。';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Premiumで解除';

  @override
  String get settingsSyncSectionTitle => '音声/字幕の同期';

  @override
  String get settingsSubtitleOffsetTitle => '字幕オフセット';

  @override
  String get settingsAudioOffsetTitle => '音声オフセット';

  @override
  String get settingsOffsetUnsupported => 'このバックエンドまたはプラットフォームでは未対応です。';

  @override
  String get settingsSyncResetOffsets => '同期オフセットをリセット';

  @override
  String get aboutTmdbDisclaimer =>
      'この製品はTMDB APIを使用していますが、TMDBによって承認または認定されたものではありません。';

  @override
  String get aboutCreditsSectionTitle => 'クレジット';
}
