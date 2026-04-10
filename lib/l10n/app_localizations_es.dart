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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count resultados)',
      one: '(1 resultado)',
      zero: '(0 resultados)',
    );
    return '$_temp0';
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
  String get libraryTypeInProgress => 'Seguir viendo';

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
      'No hay ninguna fuente IPTV activa. Añade una en Ajustes para ver tus categorías.';

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
    return 'Buscar en $provider';
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
  String get pinRecoveryLink => 'Recuperar PIN';

  @override
  String get pinRecoveryTitle => 'Recuperar PIN';

  @override
  String get pinRecoveryDescription =>
      'Te enviaremos un código de 8 dígitos al correo de tu cuenta para que puedas restablecer el PIN de este perfil.';

  @override
  String get pinRecoveryRequestCodeButton => 'Enviar código';

  @override
  String get pinRecoveryCodeSentHint =>
      'Hemos enviado un código al correo de tu cuenta. Revisa tus mensajes e introdúcelo abajo.';

  @override
  String get pinRecoveryComingSoon => 'Esta función llegará pronto.';

  @override
  String get pinRecoveryNotAvailable =>
      'La recuperación del PIN por correo electrónico no está disponible actualmente.';

  @override
  String get pinRecoveryCodeLabel => 'Código de recuperación';

  @override
  String get pinRecoveryCodeHint => '8 dígitos';

  @override
  String get pinRecoveryVerifyButton => 'Verificar código';

  @override
  String get pinRecoveryCodeInvalid => 'Introduce el código de 8 dígitos.';

  @override
  String get pinRecoveryCodeExpired => 'El código de recuperación ha expirado';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get pinRecoveryUnknownError => 'Se produjo un error inesperado.';

  @override
  String get pinRecoveryNewPinLabel => 'Nuevo PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 dígitos';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirmar PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Repite el PIN';

  @override
  String get pinRecoveryResetButton => 'Restablecer PIN';

  @override
  String get pinRecoveryPinInvalid => 'Introduce un PIN de 4 a 6 dígitos';

  @override
  String get pinRecoveryPinMismatch => 'Los PIN no coinciden';

  @override
  String get pinRecoveryResetSuccess => 'PIN actualizado';

  @override
  String get profilePinSaved => 'PIN guardado.';

  @override
  String get profilePinEditLabel => 'Editar código PIN';

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
  String get settingsPreferredAudioLanguage => 'Idioma de audio preferido';

  @override
  String get settingsPreferredSubtitleLanguage =>
      'Idioma de subtítulos preferido';

  @override
  String get libraryPlaylistsFilter => 'Listas de reproducción';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistas';

  @override
  String get librarySearchPlaceholder => 'Buscar en mi biblioteca...';

  @override
  String get libraryInProgress => 'Seguir viendo';

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
    return 'Continuar T$season · E$episode';
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
  String get playlistSortRecentAdditions => 'Añadidos recientemente';

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
  String get authOtpEmailHint => 'nombre@ejemplo.com';

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
    return 'Reenviar código en $seconds s';
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
  String get settingsSubtitlesTitle => 'Subtítulos';

  @override
  String get settingsSubtitlesSizeTitle => 'Tamaño del texto';

  @override
  String get settingsSubtitlesColorTitle => 'Color del texto';

  @override
  String get settingsSubtitlesFontTitle => 'Fuente';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Sistema';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Ajustes rápidos';

  @override
  String get settingsSubtitlesPreviewTitle => 'Vista previa';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Esta es una vista previa de los subtítulos.\nAjusta la legibilidad en tiempo real.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Fondo';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Opacidad del fondo';

  @override
  String get settingsSubtitlesShadowTitle => 'Sombra';

  @override
  String get settingsSubtitlesShadowOff => 'Desactivada';

  @override
  String get settingsSubtitlesShadowSoft => 'Suave';

  @override
  String get settingsSubtitlesShadowStrong => 'Fuerte';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Tamaño fino';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Escala';

  @override
  String get settingsSubtitlesResetDefaults => 'Restablecer valores';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Estilo avanzado de subtítulos (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'El fondo, la opacidad, los presets de sombra y el tamaño fino están disponibles con Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Desbloquear con Premium';

  @override
  String get settingsSyncSectionTitle => 'Sincronización audio/subtítulos';

  @override
  String get settingsSubtitleOffsetTitle => 'Desfase de subtítulos';

  @override
  String get settingsAudioOffsetTitle => 'Desfase de audio';

  @override
  String get settingsOffsetUnsupported =>
      'No es compatible con este backend o esta plataforma.';

  @override
  String get settingsSyncResetOffsets => 'Restablecer desfases';

  @override
  String get aboutTmdbDisclaimer =>
      'Este producto utiliza la API de TMDB, pero no está respaldado ni certificado por TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Créditos';

  @override
  String get actionSend => 'Enviar';

  @override
  String get profilePinSetLabel => 'Configurar código PIN';

  @override
  String get reportingProblemSentConfirmation => 'Reporte enviado. Gracias.';

  @override
  String get reportingProblemBody =>
      'Si este contenido no es adecuado y fue accesible pese a las restricciones, describe brevemente el problema.';

  @override
  String get reportingProblemExampleHint =>
      'Ejemplo: película de terror visible a pesar de PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automático';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Calidad de reproducción preferida';

  @override
  String settingsSignOutError(String error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Condiciones de uso';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium es necesario para la sincronización en la nube.';
}
