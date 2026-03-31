// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcomeTitle => '¡Bienvenido!';

  @override
  String get welcomeSubtitle =>
      'Completa tus preferencias para personalizar Movi.';

  @override
  String get labelUsername => 'Apodo';

  @override
  String get labelPreferredLanguage => 'Idioma preferido';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get hintUsername => 'Tu apodo';

  @override
  String get errorFillFields => 'Por favor, rellena los campos correctamente.';

  @override
  String get homeWatchNow => 'Ver ahora';

  @override
  String get welcomeSourceTitle => '¡Bienvenido!';

  @override
  String get welcomeSourceSubtitle =>
      'Agrega una fuente para personalizar tu experiencia en Movi.';

  @override
  String get welcomeSourceAdd => 'Agregar una fuente';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Escribe tu búsqueda';

  @override
  String get clear => 'Borrar';

  @override
  String get moviesTitle => 'Películas';

  @override
  String get seriesTitle => 'Series';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyEmpty => 'Sin búsquedas recientes';

  @override
  String get delete => 'Eliminar';

  @override
  String resultsCount(int count) {
    return '($count resultados)';
  }

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String errorConnectionFailed(String error) {
    return 'Conexión fallida: $error';
  }

  @override
  String get errorConnectionGeneric => 'Conexión fallida';

  @override
  String get validationRequired => 'Obligatorio';

  @override
  String get validationInvalidUrl => 'URL inválida';

  @override
  String get snackbarSourceAddedBackground =>
      'Fuente IPTV agregada. Sincronización en segundo plano…';

  @override
  String get snackbarSourceAddedSynced => 'Fuente IPTV agregada y sincronizada';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Configuración';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsLanguageLabel => 'Idioma de la aplicación';

  @override
  String get settingsGeneralTitle => 'Preferencias generales';

  @override
  String get settingsDarkModeTitle => 'Modo oscuro';

  @override
  String get settingsDarkModeSubtitle => 'Activa un tema apto para la noche.';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsNotificationsSubtitle =>
      'Recibe avisos de nuevos estrenos.';

  @override
  String get settingsAccountTitle => 'Cuenta';

  @override
  String get settingsProfileInfoTitle => 'Información del perfil';

  @override
  String get settingsProfileInfoSubtitle => 'Nombre, avatar, preferencias';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsLegalMentionsTitle => 'Avisos legales';

  @override
  String get settingsPrivacyPolicyTitle => 'Política de privacidad';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get settingsHelpDiagnosticsSection => 'Ayuda y diagnósticos';

  @override
  String get settingsExportErrorLogs => 'Exportar registros de errores';

  @override
  String get diagnosticsExportTitle => 'Exportar registros de errores';

  @override
  String get diagnosticsExportDescription =>
      'El diagnóstico solo incluye registros WARN/ERROR recientes y los identificadores de cuenta/perfil con hash (si está activado). No debería aparecer ninguna clave/token.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Incluir identificadores de cuenta/perfil (hash)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Ayuda a correlacionar un bug sin exponer el ID original.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Diagnóstico copiado al portapapeles.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnóstico guardado: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Copiar';

  @override
  String get diagnosticsActionSave => 'Guardar';

  @override
  String get actionChangeVersion => 'Cambiar versión';

  @override
  String get semanticsBack => 'Atrás';

  @override
  String get semanticsMoreActions => 'Más acciones';

  @override
  String get snackbarLoadingPlaylists => 'Cargando listas…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'No hay ninguna lista disponible. Crea una.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Error al añadir a la lista: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Este contenido ya está en esta lista';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Error al cargar las listas de reproducción: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'El reporte no está disponible para este contenido.';

  @override
  String get snackbarLoadingEpisodes => 'Cargando episodios…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Episodio no disponible en la lista';

  @override
  String snackbarGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get snackbarLoading => 'Cargando…';

  @override
  String get snackbarNoVersionAvailable => 'No hay versión disponible';

  @override
  String get snackbarVersionSaved => 'Versión guardada';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Versión $index';
  }

  @override
  String get actionReadMore => 'Leer más';

  @override
  String get actionShowLess => 'Ver menos';

  @override
  String get actionViewPage => 'Ver página';

  @override
  String get semanticsSeeSagaPage => 'Ver la página de la saga';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'En curso';

  @override
  String get libraryTypeFavoriteMovies => 'Películas favoritas';

  @override
  String get libraryTypeFavoriteSeries => 'Series favoritas';

  @override
  String get libraryTypeHistory => 'Historial';

  @override
  String get libraryTypePlaylist => 'Lista';

  @override
  String get libraryTypeArtist => 'Artista';

  @override
  String libraryItemCount(int count) {
    return '$count elemento';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Lista renombrada a \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Lista eliminada';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Este contenido ya está en la lista';

  @override
  String get snackbarAddedToPlaylist => 'Añadido a la lista';

  @override
  String get addMediaTitle => 'Añadir medios';

  @override
  String get searchMinCharsHint => 'Escribe al menos 3 caracteres para buscar';

  @override
  String get badgeAdded => 'Añadido';

  @override
  String get snackbarNotAvailableOnSource => 'No disponible en esta fuente';

  @override
  String get errorLoadingTitle => 'Error de carga';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Quitar filtro';

  @override
  String get homeErrorSwipeToRetry =>
      'Se produjo un error. Desliza hacia abajo para reintentar.';

  @override
  String get homeContinueWatching => 'Continuar viendo';

  @override
  String get homeNoIptvSources =>
      'No hay fuente IPTV activa. Añade una fuente en Ajustes para ver tus categorías.';

  @override
  String get homeNoTrends => 'No hay contenido en tendencia disponible';

  @override
  String get actionRefreshMetadata => 'Actualizar metadatos';

  @override
  String get actionChangeMetadata => 'Cambiar metadatos';

  @override
  String get actionAddToList => 'Añadir a una lista';

  @override
  String get metadataRefreshed => 'Metadatos actualizados';

  @override
  String get errorRefreshingMetadata => 'Error al actualizar metadatos';

  @override
  String get actionMarkSeen => 'Marcar como visto';

  @override
  String get actionMarkUnseen => 'Marcar como no visto';

  @override
  String get actionReportProblem => 'Reportar un problema';

  @override
  String get featureComingSoon => 'Función próximamente';

  @override
  String get subtitlesMenuTitle => 'Subtítulos';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Modo de visualización';

  @override
  String get videoFitModeContain => 'Proporciones originales';

  @override
  String get videoFitModeCover => 'Llenar pantalla';

  @override
  String get actionDisable => 'Desactivar';

  @override
  String defaultTrackLabel(String id) {
    return 'Pista $id';
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
  String get actionNextEpisode => 'Siguiente episodio';

  @override
  String get actionRestart => 'Reiniciar';

  @override
  String get errorSeriesDataUnavailable =>
      'No se pueden cargar los datos de la serie';

  @override
  String get errorNextEpisodeFailed =>
      'No se puede determinar el siguiente episodio';

  @override
  String get actionLoadMore => 'Cargar más';

  @override
  String get iptvServerUrlLabel => 'URL del servidor';

  @override
  String get iptvServerUrlHint => 'URL del servidor Xtream';

  @override
  String get iptvPasswordLabel => 'Contraseña';

  @override
  String get iptvPasswordHint => 'Contraseña Xtream';

  @override
  String get actionConnect => 'Conectar';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Actualizar listas IPTV';

  @override
  String get activeSourceTitle => 'Fuente activa';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusNoActiveSource => 'Sin fuente activa';

  @override
  String get overlayPreparingHome => 'Preparando inicio…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Cargando películas y series…';

  @override
  String get overlayLoadingCategories => 'Cargando categorías…';

  @override
  String get bootstrapRefreshing => 'Actualizando listas IPTV…';

  @override
  String get bootstrapEnriching => 'Preparando metadatos…';

  @override
  String get errorPrepareHome => 'No se pudo preparar la página de inicio';

  @override
  String get overlayOpeningHome => 'Abriendo inicio…';

  @override
  String get overlayRefreshingIptvLists => 'Actualizando listas IPTV…';

  @override
  String get overlayPreparingMetadata => 'Preparando metadatos…';

  @override
  String get errorHomeLoadTimeout =>
      'Tiempo de espera de carga de inicio agotado';

  @override
  String get faqLabel => 'Preguntas frecuentes';

  @override
  String get iptvUsernameLabel => 'Nombre de usuario';

  @override
  String get iptvUsernameHint => 'Nombre de usuario Xtream';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionSeeAll => 'Ver todo';

  @override
  String get actionExpand => 'Expandir';

  @override
  String get actionCollapse => 'Contraer';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Buscar en $provider...';
  }

  @override
  String get actionClearHistory => 'Borrar historial';

  @override
  String get castTitle => 'Reparto';

  @override
  String get recommendationsTitle => 'Recomendaciones';

  @override
  String get libraryHeader => 'Tu videoteca';

  @override
  String get libraryDataInfo =>
      'Los datos se mostrarán cuando se implemente data/domain.';

  @override
  String get libraryEmpty =>
      'Dale like a películas, series o actores para verlos aparecer aquí.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Búsqueda';

  @override
  String get notYetAvailable => 'Aún no disponible';

  @override
  String get createPlaylistTitle => 'Crear lista';

  @override
  String get playlistName => 'Nombre de la lista';

  @override
  String get addMedia => 'Añadir medios';

  @override
  String get renamePlaylist => 'Renombrar';

  @override
  String get deletePlaylist => 'Eliminar';

  @override
  String get pinPlaylist => 'Fijar';

  @override
  String get unpinPlaylist => 'Desfijar';

  @override
  String get playlistPinned => 'Lista fijada';

  @override
  String get playlistUnpinned => 'Lista desfijada';

  @override
  String get playlistDeleted => 'Lista eliminada';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Lista \"$name\" creada';
  }

  @override
  String playlistCreateError(String error) {
    return 'Error al crear la lista: $error';
  }

  @override
  String get addedToPlaylist => 'Añadido';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'Recuperar código PIN';

  @override
  String get pinRecoveryDescription =>
      'Recupera el código PIN de tu perfil protegido.';

  @override
  String get pinRecoveryComingSoon => 'Esta función llegará pronto.';

  @override
  String get pinRecoveryCodeLabel => 'Código de recuperación';

  @override
  String get pinRecoveryCodeHint => '8 dígitos';

  @override
  String get pinRecoveryVerifyButton => 'Verificar';

  @override
  String get pinRecoveryCodeInvalid => 'Introduce el código de 8 dígitos';

  @override
  String get pinRecoveryCodeExpired => 'El código de recuperación ha expirado';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get pinRecoveryUnknownError => 'Ha ocurrido un error inesperado';

  @override
  String get pinRecoveryNewPinLabel => 'Nuevo PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 dígitos';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirmar PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Repite el PIN';

  @override
  String get pinRecoveryResetButton => 'Actualizar PIN';

  @override
  String get pinRecoveryPinInvalid => 'Introduce un PIN de 4 a 6 dígitos';

  @override
  String get pinRecoveryPinMismatch => 'Los PIN no coinciden';

  @override
  String get pinRecoveryResetSuccess => 'PIN actualizado';

  @override
  String get settingsAccountsSection => 'Cuentas';

  @override
  String get settingsIptvSection => 'Configuración IPTV';

  @override
  String get settingsSourcesManagement => 'Gestión de fuentes';

  @override
  String get settingsSyncFrequency => 'Frecuencia de actualización';

  @override
  String get settingsAppSection => 'Configuración de la aplicación';

  @override
  String get settingsAccentColor => 'Color de acento';

  @override
  String get settingsPlaybackSection => 'Configuración de reproducción';

  @override
  String get settingsPreferredAudioLanguage => 'Idioma preferido';

  @override
  String get settingsPreferredSubtitleLanguage => 'Subtítulos preferidos';

  @override
  String get libraryPlaylistsFilter => 'Listas de reproducción';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistas';

  @override
  String get librarySearchPlaceholder => 'Buscar en mi biblioteca...';

  @override
  String get libraryInProgress => 'En progreso';

  @override
  String get libraryFavoriteMovies => 'Películas favoritas';

  @override
  String get libraryFavoriteSeries => 'Series favoritas';

  @override
  String get libraryWatchHistory => 'Historial de visualización';

  @override
  String libraryItemCountPlural(int count) {
    return '$count elementos';
  }

  @override
  String get searchPeopleTitle => 'Personas';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'Por proveedores';

  @override
  String get searchByGenresTitle => 'Por géneros';

  @override
  String get personRoleActor => 'Actor';

  @override
  String get personRoleDirector => 'Director';

  @override
  String get personRoleCreator => 'Creador';

  @override
  String get tvDistribution => 'Reparto';

  @override
  String tvSeasonLabel(int number) {
    return 'Temporada $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'No hay episodios disponibles';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Continuar T$season E$episode';
  }

  @override
  String get sagaViewPage => 'Ver página';

  @override
  String get sagaStartNow => 'Comenzar ahora';

  @override
  String get sagaContinue => 'Continuar';

  @override
  String sagaMovieCount(int count) {
    return '$count películas';
  }

  @override
  String get sagaMoviesList => 'Lista de películas';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies películas - $shows series';
  }

  @override
  String get personPlayRandomly => 'Reproducir aleatoriamente';

  @override
  String get personMoviesList => 'Lista de películas';

  @override
  String get personSeriesList => 'Lista de series';

  @override
  String get playlistPlayRandomly => 'Reproducir aleatoriamente';

  @override
  String get playlistAddButton => 'Añadir';

  @override
  String get playlistSortButton => 'Ordenar';

  @override
  String get playlistSortByTitle => 'Ordenar por';

  @override
  String get playlistSortByTitleOption => 'Título';

  @override
  String get playlistSortRecentAdditions => 'Agregados recientes';

  @override
  String get playlistSortOldestFirst => 'Más antiguos primero';

  @override
  String get playlistSortNewestFirst => 'Más recientes primero';

  @override
  String get playlistEmptyMessage => 'No hay elementos en esta lista';

  @override
  String playlistItemCount(int count) {
    return '$count elemento';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count elementos';
  }

  @override
  String get playlistSeasonSingular => 'temporada';

  @override
  String get playlistSeasonPlural => 'temporadas';

  @override
  String get playlistRenameTitle => 'Renombrar lista';

  @override
  String get playlistNamePlaceholder => 'Nombre de la lista';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Lista renombrada a \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Eliminar';

  @override
  String playlistDeleteConfirm(String title) {
    return '¿Estás seguro de que quieres eliminar \"$title\"?';
  }

  @override
  String get playlistDeletedSuccess => 'Lista eliminada';

  @override
  String get playlistItemRemovedSuccess => 'Elemento eliminado';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '¿Eliminar \"$title\" de la lista?';
  }

  @override
  String get categoryLoadFailed => 'Error al cargar la categoría.';

  @override
  String get categoryEmpty => 'No hay elementos en esta categoría.';

  @override
  String get categoryLoadingMore => 'Cargando más…';

  @override
  String get movieNoPlaylistsAvailable =>
      'No hay listas de reproducción disponibles';

  @override
  String playlistAddedTo(String title) {
    return 'Añadido a \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Película no disponible en la lista de reproducción';

  @override
  String errorPlaybackFailed(String message) {
    return 'Error al reproducir la película: $message';
  }

  @override
  String get movieNoMedia => 'No hay contenido para mostrar';

  @override
  String get personNoData => 'No hay persona para mostrar.';

  @override
  String get personGenericError =>
      'Se produjo un error al cargar esta persona.';

  @override
  String get personBiographyTitle => 'Biografía';

  @override
  String get authOtpTitle => 'Iniciar sesión';

  @override
  String get authOtpSubtitle =>
      'Introduce tu correo y el código de 8 dígitos que te enviamos.';

  @override
  String get authOtpEmailLabel => 'Correo electrónico';

  @override
  String get authOtpEmailHint => 'tu@correo';

  @override
  String get authOtpEmailHelp =>
      'Te enviaremos un código de 8 dígitos. Revisa el spam si es necesario.';

  @override
  String get authOtpCodeLabel => 'Código de verificación';

  @override
  String get authOtpCodeHint => 'Código de 8 dígitos';

  @override
  String get authOtpCodeHelp =>
      'Introduce el código de 8 dígitos recibido por correo.';

  @override
  String get authOtpPrimarySend => 'Enviar código';

  @override
  String get authOtpPrimarySubmit => 'Iniciar sesión';

  @override
  String get authOtpResend => 'Reenviar código';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Cambiar correo';

  @override
  String get resumePlayback => 'Reanudar la reproducción';

  @override
  String get settingsCloudSyncSection => 'Sincronización en la nube';

  @override
  String get settingsCloudSyncAuto => 'Sincronización automática';

  @override
  String get settingsCloudSyncNow => 'Sincronizar ahora';

  @override
  String get settingsCloudSyncInProgress => 'Sincronizando…';

  @override
  String get settingsCloudSyncNever => 'Nunca';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Último error: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return 'No se encontró $entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return 'No se encontró $entity: $error';
  }

  @override
  String get entityProvider => 'Proveedor';

  @override
  String get entityGenre => 'Género';

  @override
  String get entityPlaylist => 'Lista de reproducción';

  @override
  String get entitySource => 'Fuente';

  @override
  String get entityMovie => 'Película';

  @override
  String get entitySeries => 'Serie';

  @override
  String get entityPerson => 'Persona';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Vídeo';

  @override
  String get entityRoute => 'Ruta';

  @override
  String get errorTimeoutLoading => 'Tiempo de espera agotado al cargar';

  @override
  String get parentalContentRestricted => 'Contenido restringido';

  @override
  String get parentalContentRestrictedDefault =>
      'Este contenido está bloqueado por el control parental de este perfil.';

  @override
  String get parentalReasonTooYoung =>
      'Este contenido requiere una edad superior al límite de este perfil.';

  @override
  String get parentalReasonUnknownRating =>
      'La clasificación por edades de este contenido no está disponible.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Este contenido no puede ser evaluado para el control parental.';

  @override
  String get parentalUnlockButton => 'Desbloquear';

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
  String get hc_chargement_episodes_en_cours_33fc4ace => 'Cargando episodios…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'No hay ninguna lista disponible. Crea una.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Error al cargar las listas: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa =>
      'No se puede abrir el enlace';

  @override
  String get hc_qualite_preferee_776dbeea => 'Calidad preferida';

  @override
  String get hc_annuler_49ba3292 => 'Cancel';

  @override
  String get hc_deconnexion_903dca17 => 'Cerrar sesión';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Error al cerrar sesión: \$e';

  @override
  String get hc_choisir_b030d590 => 'Choose';

  @override
  String get hc_avantages_08d7f47c => 'Benefits';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Informe enviado. Gracias.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Más tarde';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Reiniciar ahora';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => '¿Usar esta fuente?';

  @override
  String get hc_utiliser_fb5e43ce => 'Use';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Fuente añadida';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Ajustes bloqueados';

  @override
  String get hc_compte_cloud_2812b31e => 'Cuenta en la nube';

  @override
  String get hc_se_connecter_fedf2439 => 'Iniciar sesión';

  @override
  String get hc_propos_5345add5 => 'Acerca de';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'Política de privacidad';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Términos de uso';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Fuentes guardadas';

  @override
  String get hc_rafraichir_be30b7d1 => 'Actualizar';

  @override
  String get hc_activer_une_source_749ced38 => 'Activar una fuente';

  @override
  String get hc_nom_source_9a3e4156 => 'Nombre de la fuente';

  @override
  String get hc_mon_iptv_b239352c => 'Mi IPTV';

  @override
  String get hc_username_84c29015 => 'Usuario';

  @override
  String get hc_password_8be3c943 => 'Contraseña';

  @override
  String get hc_server_url_1d5d1eff => 'URL del servidor';

  @override
  String get hc_verification_pin_e17c8fe0 => 'Verificación de PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'Definir un PIN';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'Subscription offer not found: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'The subscription purchase was cancelled by the user.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'The store operation timed out: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 =>
      'HTTP error during handshake';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Non-JSON response from Xtream server';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'Invalid response from Xtream server';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      'No disponible en esta fuente';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Fuente eliminada';

  @override
  String get hc_source_modifiee_335ef502 => 'Fuente actualizada';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'Definir código PIN';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Marcar como no visto';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      '¿Seguro que quieres cerrar sesión?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Se requiere Movi Premium para la sincronización en la nube.';

  @override
  String get hc_auto_c614ba7c => 'Auto';

  @override
  String get hc_organiser_838a7e57 => 'Organizar';

  @override
  String get hc_modifier_f260e757 => 'Editar';

  @override
  String get hc_ajouter_87c57ed1 => 'Añadir';

  @override
  String get hc_source_active_e571305e => 'Fuente activa';

  @override
  String get hc_autres_sources_e32592a6 => 'Otras fuentes';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Los reportes no están disponibles para este contenido.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Protegiendo el contenido';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Comprobando clasificaciones de edad…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Ver todo';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Informar de un problema';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Si este contenido no es apropiado y fue accesible pese a las restricciones, describe brevemente el problema.';

  @override
  String get hc_envoyer_e9ce243b => 'Enviar';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Perfil infantil creado';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Se creó un perfil infantil. Para proteger la app y precargar las clasificaciones por edad, se recomienda reiniciar la app.';

  @override
  String get hc_pseudo_4cf966c0 => 'Apodo';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Perfil infantil';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Límite de edad';

  @override
  String get hc_code_pin_e79c48bd => 'Código PIN';

  @override
  String get hc_changer_code_pin_3b069731 => 'Cambiar código PIN';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'Eliminar código PIN';

  @override
  String get hc_supprimer_pin_51850c7b => 'Eliminar PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'Eliminar';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Requiere un PIN y activa el filtro PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      '¿Quieres activar esta fuente ahora?';

  @override
  String get hc_application_b291beb8 => 'Aplicación';

  @override
  String get hc_version_1_0_0_347e553c => 'Version 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Créditos';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Este producto utiliza la API de TMDB, pero no está respaldado ni certificado por TMDB.';

  @override
  String get hc_verification_targets_d51632f8 => 'Verification targets';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 => 'The fade must eat the frame';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 =>
      'Invalid Xtream streamId: ...';

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
  String get hc_url_invalide_aa227a66 => 'URL no válida';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Falta el IV heredado: no se puede descifrar el texto cifrado heredado.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Actualizar\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Menu\'';

  @override
  String get hc_retour_e5befb1f => 'Atrás';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Más acciones\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Más acciones';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c =>
      'semanticLabel: \'Buscar\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'Añadir\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Cerrar sesión';

  @override
  String get dialogSignOutBody => '¿Seguro que quieres cerrar sesión?';

  @override
  String get settingsUnableToOpenLink => 'No se pudo abrir el enlace';

  @override
  String get settingsSyncDisabled => 'Desactivado';

  @override
  String get settingsSyncEveryHour => 'Cada hora';

  @override
  String get settingsSyncEvery2Hours => 'Cada 2 horas';

  @override
  String get settingsSyncEvery4Hours => 'Cada 4 horas';

  @override
  String get settingsSyncEvery6Hours => 'Cada 6 horas';

  @override
  String get settingsSyncEveryDay => 'Cada día';

  @override
  String get settingsSyncEvery2Days => 'Cada 2 días';

  @override
  String get settingsColorCustom => 'Personalizado';

  @override
  String get settingsColorBlue => 'Azul';

  @override
  String get settingsColorPink => 'Rosa';

  @override
  String get settingsColorGreen => 'Verde';

  @override
  String get settingsColorPurple => 'Morado';

  @override
  String get settingsColorOrange => 'Naranja';

  @override
  String get settingsColorTurquoise => 'Turquesa';

  @override
  String get settingsColorYellow => 'Amarillo';

  @override
  String get settingsColorIndigo => 'Índigo';

  @override
  String get settingsCloudAccountTitle => 'Cuenta en la nube';

  @override
  String get settingsAccountConnected => 'Conectado';

  @override
  String get settingsAccountLocalMode => 'Modo local';

  @override
  String get settingsAccountCloudUnavailable => 'Nube no disponible';

  @override
  String get aboutTmdbDisclaimer =>
      'Este producto utiliza la API de TMDB, pero no está respaldado ni certificado por TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Créditos';
}
