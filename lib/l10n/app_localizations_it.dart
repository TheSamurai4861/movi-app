// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get welcomeTitle => 'Benvenuto!';

  @override
  String get welcomeSubtitle =>
      'Compila le tue preferenze per personalizzare Movi.';

  @override
  String get labelUsername => 'Nickname';

  @override
  String get labelPreferredLanguage => 'Lingua preferita';

  @override
  String get actionContinue => 'Continua';

  @override
  String get hintUsername => 'Il tuo nickname';

  @override
  String get errorFillFields => 'Compila correttamente i campi.';

  @override
  String get homeWatchNow => 'Guarda ora';

  @override
  String get welcomeSourceTitle => 'Benvenuto!';

  @override
  String get welcomeSourceSubtitle =>
      'Aggiungi una sorgente per personalizzare la tua esperienza su Movi.';

  @override
  String get welcomeSourceAdd => 'Aggiungi una sorgente';

  @override
  String get searchTitle => 'Cerca';

  @override
  String get searchHint => 'Scrivi la tua ricerca';

  @override
  String get clear => 'Cancella';

  @override
  String get moviesTitle => 'Film';

  @override
  String get seriesTitle => 'Serie';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get historyEmpty => 'Nessuna ricerca recente';

  @override
  String get delete => 'Elimina';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
      zero: 'Nessun risultato',
    );
    return '$_temp0';
  }

  @override
  String get errorUnknown => 'Errore sconosciuto';

  @override
  String errorConnectionFailed(String error) {
    return 'Connessione non riuscita: $error';
  }

  @override
  String get errorConnectionGeneric => 'Connessione non riuscita';

  @override
  String get validationRequired => 'Obbligatorio';

  @override
  String get validationInvalidUrl => 'URL non valido';

  @override
  String get snackbarSourceAddedBackground =>
      'Sorgente IPTV aggiunta. Sincronizzazione in background…';

  @override
  String get snackbarSourceAddedSynced =>
      'Sorgente IPTV aggiunta e sincronizzata';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Cerca';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguageLabel => 'Lingua dell’app';

  @override
  String get settingsGeneralTitle => 'Preferenze generali';

  @override
  String get settingsDarkModeTitle => 'Modalità scura';

  @override
  String get settingsDarkModeSubtitle => 'Abilita un tema adatto alla notte.';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsNotificationsSubtitle =>
      'Ricevi avvisi sulle nuove uscite.';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsProfileInfoTitle => 'Informazioni profilo';

  @override
  String get settingsProfileInfoSubtitle => 'Nome, avatar, preferenze';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsLegalMentionsTitle => 'Note legali';

  @override
  String get settingsPrivacyPolicyTitle => 'Informativa sulla privacy';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionConfirm => 'Conferma';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get settingsHelpDiagnosticsSection => 'Aiuto e diagnostica';

  @override
  String get settingsExportErrorLogs => 'Esporta log di errore';

  @override
  String get diagnosticsExportTitle => 'Esporta log di errore';

  @override
  String get diagnosticsExportDescription =>
      'La diagnostica include solo log WARN/ERROR recenti e identificativi account/profilo con hash (se abilitato). Non dovrebbero comparire chiavi/token.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Includi identificativi account/profilo (hash)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Aiuta a correlare un bug senza esporre l’ID originale.';

  @override
  String get diagnosticsCopiedClipboard => 'Diagnostica copiata negli appunti.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnostica salvata: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Copia';

  @override
  String get diagnosticsActionSave => 'Salva';

  @override
  String get actionChangeVersion => 'Cambia versione';

  @override
  String get semanticsBack => 'Indietro';

  @override
  String get semanticsMoreActions => 'Altre azioni';

  @override
  String get snackbarLoadingPlaylists => 'Caricamento delle playlist…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Nessuna playlist disponibile. Creane una.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Errore durante l’aggiunta alla playlist: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'Questo contenuto è già presente in questa playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Errore durante il caricamento delle playlist: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Segnalazione non disponibile per questo contenuto.';

  @override
  String get snackbarLoadingEpisodes => 'Caricamento episodi…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Episodio non disponibile nella playlist';

  @override
  String snackbarGenericError(String error) {
    return 'Errore: $error';
  }

  @override
  String get snackbarLoading => 'Caricamento…';

  @override
  String get snackbarNoVersionAvailable => 'Nessuna versione disponibile';

  @override
  String get snackbarVersionSaved => 'Versione salvata';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Versione $index';
  }

  @override
  String get actionReadMore => 'Leggi di più';

  @override
  String get actionShowLess => 'Mostra meno';

  @override
  String get actionViewPage => 'Vedi pagina';

  @override
  String get semanticsSeeSagaPage => 'Vedi la pagina della saga';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'Continua a guardare';

  @override
  String get libraryTypeFavoriteMovies => 'Film preferiti';

  @override
  String get libraryTypeFavoriteSeries => 'Serie preferite';

  @override
  String get libraryTypeHistory => 'Cronologia';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Artista';

  @override
  String libraryItemCount(int count) {
    return '$count elemento';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist rinominata in \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist eliminata';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Sei sicuro di voler eliminare \"$title\"?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Nessun risultato per \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Errore: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Questo contenuto è già nella playlist';

  @override
  String get snackbarAddedToPlaylist => 'Aggiunto alla playlist';

  @override
  String get addMediaTitle => 'Aggiungi media';

  @override
  String get searchMinCharsHint => 'Digita almeno 3 caratteri per cercare';

  @override
  String get badgeAdded => 'Aggiunto';

  @override
  String get snackbarNotAvailableOnSource =>
      'Non disponibile su questa sorgente';

  @override
  String get errorLoadingTitle => 'Errore di caricamento';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Errore: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Errore durante il caricamento: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Rimuovi filtro';

  @override
  String get homeErrorSwipeToRetry =>
      'Si è verificato un errore. Scorri verso il basso per riprovare.';

  @override
  String get homeContinueWatching => 'Continua a guardare';

  @override
  String get homeNoIptvSources =>
      'Nessuna sorgente IPTV attiva. Aggiungi una sorgente in Impostazioni per vedere le tue categorie.';

  @override
  String get homeNoTrends => 'Nessun contenuto di tendenza disponibile';

  @override
  String get actionRefreshMetadata => 'Aggiorna metadati';

  @override
  String get actionChangeMetadata => 'Cambia metadati';

  @override
  String get actionAddToList => 'Aggiungi a una lista';

  @override
  String get metadataRefreshed => 'Metadati aggiornati';

  @override
  String get errorRefreshingMetadata =>
      'Errore durante l\'aggiornamento dei metadati';

  @override
  String get actionMarkSeen => 'Segna come visto';

  @override
  String get actionMarkUnseen => 'Segna come non visto';

  @override
  String get actionReportProblem => 'Segnala un problema';

  @override
  String get featureComingSoon => 'Funzionalità in arrivo';

  @override
  String get subtitlesMenuTitle => 'Sottotitoli';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Modalità di visualizzazione';

  @override
  String get videoFitModeContain => 'Proporzioni originali';

  @override
  String get videoFitModeCover => 'Riempire schermo';

  @override
  String get actionDisable => 'Disattiva';

  @override
  String defaultTrackLabel(String id) {
    return 'Traccia $id';
  }

  @override
  String get controlRewind10 => '10 s';

  @override
  String get controlRewind30 => '30 s';

  @override
  String get controlForward10 => '+ 10 s';

  @override
  String get controlForward30 => '+ 30 s';

  @override
  String get actionNextEpisode => 'Prossimo episodio';

  @override
  String get actionRestart => 'Ricomincia';

  @override
  String get errorSeriesDataUnavailable =>
      'Impossibile caricare i dati della serie';

  @override
  String get errorNextEpisodeFailed =>
      'Impossibile determinare il prossimo episodio';

  @override
  String get actionLoadMore => 'Carica di più';

  @override
  String get iptvServerUrlLabel => 'URL del server';

  @override
  String get iptvServerUrlHint => 'URL del server Xtream';

  @override
  String get iptvPasswordLabel => 'Password';

  @override
  String get iptvPasswordHint => 'Password Xtream';

  @override
  String get actionConnect => 'Connetti';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Aggiorna playlist IPTV';

  @override
  String get activeSourceTitle => 'Sorgente attiva';

  @override
  String get statusActive => 'Attivo';

  @override
  String get statusNoActiveSource => 'Nessuna sorgente attiva';

  @override
  String get overlayPreparingHome => 'Preparazione home…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Caricamento di film e serie…';

  @override
  String get overlayLoadingCategories => 'Caricamento categorie…';

  @override
  String get bootstrapRefreshing => 'Aggiornamento delle liste IPTV…';

  @override
  String get bootstrapEnriching => 'Preparazione dei metadati…';

  @override
  String get errorPrepareHome => 'Impossibile preparare la pagina home';

  @override
  String get overlayOpeningHome => 'Apertura home…';

  @override
  String get overlayRefreshingIptvLists => 'Aggiornamento liste IPTV…';

  @override
  String get overlayPreparingMetadata => 'Preparazione metadati…';

  @override
  String get errorHomeLoadTimeout => 'Timeout caricamento home';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Nome utente';

  @override
  String get iptvUsernameHint => 'Nome utente Xtream';

  @override
  String get actionBack => 'Indietro';

  @override
  String get actionSeeAll => 'Vedi tutto';

  @override
  String get actionExpand => 'Espandi';

  @override
  String get actionCollapse => 'Riduci';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Cerca in $provider';
  }

  @override
  String get actionClearHistory => 'Cancella cronologia';

  @override
  String get castTitle => 'Cast';

  @override
  String get recommendationsTitle => 'Consigli';

  @override
  String get libraryHeader => 'La tua videoteca';

  @override
  String get libraryDataInfo =>
      'I dati verranno mostrati quando data/domain sarà implementato.';

  @override
  String get libraryEmpty =>
      'Metti like a film, serie o attori per vederli apparire qui.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Ricerca';

  @override
  String get notYetAvailable => 'Non ancora disponibile';

  @override
  String get createPlaylistTitle => 'Crea playlist';

  @override
  String get playlistName => 'Nome playlist';

  @override
  String get addMedia => 'Aggiungi media';

  @override
  String get renamePlaylist => 'Rinomina';

  @override
  String get deletePlaylist => 'Elimina';

  @override
  String get pinPlaylist => 'Fissa';

  @override
  String get unpinPlaylist => 'Rimuovi fissaggio';

  @override
  String get playlistPinned => 'Playlist fissata';

  @override
  String get playlistUnpinned => 'Playlist non fissata';

  @override
  String get playlistDeleted => 'Playlist eliminata';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" creata';
  }

  @override
  String playlistCreateError(String error) {
    return 'Errore durante la creazione: $error';
  }

  @override
  String get addedToPlaylist => 'Aggiunto';

  @override
  String get pinRecoveryLink => 'Recupera il PIN';

  @override
  String get pinRecoveryTitle => 'Recupera il PIN';

  @override
  String get pinRecoveryDescription =>
      'Ti invieremo un codice di 8 cifre all\'indirizzo email del tuo account per reimpostare il PIN di questo profilo.';

  @override
  String get pinRecoveryRequestCodeButton => 'Invia codice';

  @override
  String get pinRecoveryCodeSentHint =>
      'Codice inviato all\'e-mail del tuo account. Controlla i messaggi e inseriscilo qui sotto.';

  @override
  String get pinRecoveryComingSoon => 'Questa funzione arriverà presto.';

  @override
  String get pinRecoveryNotAvailable =>
      'Il recupero del PIN tramite e-mail non è attualmente disponibile.';

  @override
  String get pinRecoveryCodeLabel => 'Codice di recupero';

  @override
  String get pinRecoveryCodeHint => '8 cifre';

  @override
  String get pinRecoveryVerifyButton => 'Verifica';

  @override
  String get pinRecoveryCodeInvalid =>
      'Inserisci il codice di recupero di 8 cifre';

  @override
  String get pinRecoveryCodeExpired => 'Il codice di recupero è scaduto';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Troppi tentativi. Riprova più tardi.';

  @override
  String get pinRecoveryUnknownError => 'Si è verificato un errore imprevisto';

  @override
  String get pinRecoveryNewPinLabel => 'Nuovo PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 cifre';

  @override
  String get pinRecoveryConfirmPinLabel => 'Conferma PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Ripeti il PIN';

  @override
  String get pinRecoveryResetButton => 'Reimposta PIN';

  @override
  String get pinRecoveryPinInvalid => 'Inserisci un PIN da 4 a 6 cifre';

  @override
  String get pinRecoveryPinMismatch => 'I PIN non coincidono';

  @override
  String get pinRecoveryResetSuccess => 'PIN aggiornato';

  @override
  String get profilePinSaved => 'PIN salvato.';

  @override
  String get profilePinEditLabel => 'Modifica codice PIN';

  @override
  String get settingsAccountsSection => 'Account';

  @override
  String get settingsIptvSection => 'Impostazioni IPTV';

  @override
  String get settingsSourcesManagement => 'Gestione sorgenti';

  @override
  String get settingsSyncFrequency => 'Frequenza di aggiornamento';

  @override
  String get settingsAppSection => 'Impostazioni app';

  @override
  String get settingsAccentColor => 'Colore di accento';

  @override
  String get settingsPlaybackSection => 'Impostazioni di riproduzione';

  @override
  String get settingsPreferredAudioLanguage => 'Lingua audio preferita';

  @override
  String get settingsPreferredSubtitleLanguage =>
      'Lingua dei sottotitoli preferita';

  @override
  String get libraryPlaylistsFilter => 'Playlist';

  @override
  String get librarySagasFilter => 'Saghe';

  @override
  String get libraryArtistsFilter => 'Artisti';

  @override
  String get librarySearchPlaceholder => 'Cerca nella mia libreria...';

  @override
  String get libraryInProgress => 'Continua a guardare';

  @override
  String get libraryFavoriteMovies => 'Film preferiti';

  @override
  String get libraryFavoriteSeries => 'Serie preferite';

  @override
  String get libraryWatchHistory => 'Cronologia di visualizzazione';

  @override
  String libraryItemCountPlural(int count) {
    return '$count elementi';
  }

  @override
  String get searchPeopleTitle => 'Persone';

  @override
  String get searchSagasTitle => 'Saghe';

  @override
  String get searchByProvidersTitle => 'Per provider';

  @override
  String get searchByGenresTitle => 'Per generi';

  @override
  String get personRoleActor => 'Attore';

  @override
  String get personRoleDirector => 'Regista';

  @override
  String get personRoleCreator => 'Creatore';

  @override
  String get tvDistribution => 'Cast';

  @override
  String tvSeasonLabel(int number) {
    return 'Stagione $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Nessun episodio disponibile';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Riprendi S$season · E$episode';
  }

  @override
  String get sagaViewPage => 'Visualizza pagina';

  @override
  String get sagaStartNow => 'Inizia ora';

  @override
  String get sagaContinue => 'Continua';

  @override
  String sagaMovieCount(int count) {
    return '$count film';
  }

  @override
  String get sagaMoviesList => 'Lista film';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies film - $shows serie';
  }

  @override
  String get personPlayRandomly => 'Riproduci casualmente';

  @override
  String get personMoviesList => 'Lista film';

  @override
  String get personSeriesList => 'Lista serie';

  @override
  String get playlistPlayRandomly => 'Riproduci casualmente';

  @override
  String get playlistAddButton => 'Aggiungi';

  @override
  String get playlistSortButton => 'Ordina';

  @override
  String get playlistSortByTitle => 'Ordina per';

  @override
  String get playlistSortByTitleOption => 'Titolo';

  @override
  String get playlistSortRecentAdditions => 'Aggiunti di recente';

  @override
  String get playlistSortOldestFirst => 'Più vecchi prima';

  @override
  String get playlistSortNewestFirst => 'Più recenti prima';

  @override
  String get playlistEmptyMessage => 'Nessun elemento in questa playlist';

  @override
  String playlistItemCount(int count) {
    return '$count elemento';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count elementi';
  }

  @override
  String get playlistSeasonSingular => 'stagione';

  @override
  String get playlistSeasonPlural => 'stagioni';

  @override
  String get playlistRenameTitle => 'Rinomina playlist';

  @override
  String get playlistNamePlaceholder => 'Nome playlist';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Playlist rinominata in \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Elimina playlist';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Sei sicuro di voler eliminare \"$title\"?';
  }

  @override
  String get playlistDeletedSuccess => 'Playlist eliminata';

  @override
  String get playlistItemRemovedSuccess => 'Elemento rimosso';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Rimuovere \"$title\" dalla playlist?';
  }

  @override
  String get categoryLoadFailed => 'Errore nel caricamento della categoria.';

  @override
  String get categoryEmpty => 'Nessun elemento in questa categoria.';

  @override
  String get categoryLoadingMore => 'Caricamento in corso…';

  @override
  String get movieNoPlaylistsAvailable => 'Nessuna playlist disponibile';

  @override
  String playlistAddedTo(String title) {
    return 'Aggiunto a \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Film non disponibile nella playlist';

  @override
  String errorPlaybackFailed(String message) {
    return 'Errore durante la riproduzione del film: $message';
  }

  @override
  String get movieNoMedia => 'Nessun contenuto da mostrare';

  @override
  String get personNoData => 'Nessuna persona da mostrare.';

  @override
  String get personGenericError =>
      'Si è verificato un errore durante il caricamento di questa persona.';

  @override
  String get personBiographyTitle => 'Biografia';

  @override
  String get authOtpTitle => 'Accedi';

  @override
  String get authOtpSubtitle =>
      'Inserisci il tuo indirizzo email e il codice di 8 cifre che ti invieremo.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'nome@esempio.com';

  @override
  String get authOtpEmailHelp =>
      'Ti invieremo un codice a 8 cifre. Controlla lo spam se necessario.';

  @override
  String get authOtpCodeLabel => 'Codice di verifica';

  @override
  String get authOtpCodeHint => 'Codice a 8 cifre';

  @override
  String get authOtpCodeHelp =>
      'Inserisci il codice di 8 cifre ricevuto via email.';

  @override
  String get authOtpPrimarySend => 'Invia codice';

  @override
  String get authOtpPrimarySubmit => 'Accedi';

  @override
  String get authOtpResend => 'Reinvia codice';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Reinvia il codice tra $seconds s';
  }

  @override
  String get authOtpChangeEmail => 'Cambia email';

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
  String get authForgotPasswordTitle => 'Password dimenticata';

  @override
  String get authForgotPasswordSubtitle =>
      'Inserisci la tua e-mail per ricevere un link per reimpostare la password.';

  @override
  String get authForgotPasswordInfoNeutral =>
      'Un\'e-mail per reimpostare la password verrà inviata a questo indirizzo se esiste un account.';

  @override
  String get authForgotPasswordPrimarySubmit => 'Invia il link';

  @override
  String get authForgotPasswordBackToSignIn => 'Torna all\'accesso';

  @override
  String get authPasswordUseOtp => 'Use email code instead';

  @override
  String get resumePlayback => 'Riprendi la riproduzione';

  @override
  String get settingsCloudSyncSection => 'Sincronizzazione cloud';

  @override
  String get settingsCloudSyncAuto => 'Sincronizzazione automatica';

  @override
  String get settingsCloudSyncNow => 'Sincronizza ora';

  @override
  String get settingsCloudSyncInProgress => 'Sincronizzazione…';

  @override
  String get settingsCloudSyncNever => 'Mai';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Ultimo errore: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity non trovato';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity non trovato: $error';
  }

  @override
  String get entityProvider => 'Provider';

  @override
  String get entityGenre => 'Genere';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Sorgente';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Serie';

  @override
  String get entityPerson => 'Persona';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Video';

  @override
  String get entityRoute => 'Percorso';

  @override
  String get errorTimeoutLoading => 'Timeout durante il caricamento';

  @override
  String get parentalContentRestricted => 'Contenuto limitato';

  @override
  String get parentalContentRestrictedDefault =>
      'Questo contenuto è bloccato dal controllo parentale di questo profilo.';

  @override
  String get parentalReasonTooYoung =>
      'Questo contenuto richiede un\'età superiore al limite di questo profilo.';

  @override
  String get parentalReasonUnknownRating =>
      'La classificazione per età di questo contenuto non è disponibile.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Questo contenuto non può essere valutato per il controllo parentale.';

  @override
  String get parentalUnlockButton => 'Sblocca';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Disconnetti';

  @override
  String get dialogSignOutBody => 'Vuoi davvero disconnetterti?';

  @override
  String get settingsUnableToOpenLink => 'Impossibile aprire il link';

  @override
  String get settingsSyncDisabled => 'Disattivato';

  @override
  String get settingsSyncEveryHour => 'Ogni ora';

  @override
  String get settingsSyncEvery2Hours => 'Ogni 2 ore';

  @override
  String get settingsSyncEvery4Hours => 'Ogni 4 ore';

  @override
  String get settingsSyncEvery6Hours => 'Ogni 6 ore';

  @override
  String get settingsSyncEveryDay => 'Ogni giorno';

  @override
  String get settingsSyncEvery2Days => 'Ogni 2 giorni';

  @override
  String get settingsColorCustom => 'Personalizzato';

  @override
  String get settingsColorBlue => 'Blu';

  @override
  String get settingsColorPink => 'Rosa';

  @override
  String get settingsColorGreen => 'Verde';

  @override
  String get settingsColorPurple => 'Viola';

  @override
  String get settingsColorOrange => 'Arancione';

  @override
  String get settingsColorTurquoise => 'Turchese';

  @override
  String get settingsColorYellow => 'Giallo';

  @override
  String get settingsColorIndigo => 'Indaco';

  @override
  String get settingsCloudAccountTitle => 'Account cloud';

  @override
  String get settingsAccountConnected => 'Connesso';

  @override
  String get settingsAccountLocalMode => 'Modalità locale';

  @override
  String get settingsAccountCloudUnavailable => 'Cloud non disponibile';

  @override
  String get settingsSubtitlesTitle => 'Sottotitoli';

  @override
  String get settingsSubtitlesSizeTitle => 'Dimensione testo';

  @override
  String get settingsSubtitlesColorTitle => 'Colore testo';

  @override
  String get settingsSubtitlesFontTitle => 'Carattere';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Sistema';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Impostazioni rapide';

  @override
  String get settingsSubtitlesPreviewTitle => 'Anteprima';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Questa è un\'anteprima dei sottotitoli.\nRegola la leggibilità in tempo reale.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Sfondo';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Opacità sfondo';

  @override
  String get settingsSubtitlesShadowTitle => 'Ombra';

  @override
  String get settingsSubtitlesShadowOff => 'Disattivata';

  @override
  String get settingsSubtitlesShadowSoft => 'Morbida';

  @override
  String get settingsSubtitlesShadowStrong => 'Forte';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Dimensione fine';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Scala';

  @override
  String get settingsSubtitlesResetDefaults => 'Ripristina predefiniti';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Stile sottotitoli avanzato (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Sfondo, opacità, preset ombra e dimensione fine sono disponibili con Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Sblocca con Premium';

  @override
  String get settingsSyncSectionTitle => 'Sincronizzazione audio/sottotitoli';

  @override
  String get settingsSubtitleOffsetTitle => 'Offset sottotitoli';

  @override
  String get settingsAudioOffsetTitle => 'Offset audio';

  @override
  String get settingsOffsetUnsupported =>
      'Non supportato da questo backend o da questa piattaforma.';

  @override
  String get settingsSyncResetOffsets => 'Reimposta offset di sincronizzazione';

  @override
  String get aboutTmdbDisclaimer =>
      'Questo prodotto utilizza l\'API di TMDB ma non è approvato né certificato da TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Crediti';

  @override
  String get actionSend => 'Invia';

  @override
  String get profilePinSetLabel => 'Imposta codice PIN';

  @override
  String get reportingProblemSentConfirmation =>
      'Segnalazione inviata. Grazie.';

  @override
  String get reportingProblemBody =>
      'Se questo contenuto non è appropriato ed è stato accessibile nonostante le restrizioni, descrivi brevemente il problema.';

  @override
  String get reportingProblemExampleHint =>
      'Esempio: film horror visibile nonostante PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automatico';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Qualità di riproduzione preferita';

  @override
  String settingsSignOutError(String error) {
    return 'Errore durante la disconnessione: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Condizioni d\'uso';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium è richiesto per la sincronizzazione cloud.';
}
