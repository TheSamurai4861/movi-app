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
  String get actionMarkSeen => 'Mark as seen';

  @override
  String get actionMarkUnseen => 'Mark as unseen';

  @override
  String get actionReportProblem => 'Report a problem';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get actionLoadMore => 'Load more';

  @override
  String get iptvServerUrlLabel => 'Server URL';

  @override
  String get iptvServerUrlHint => 'Xtream server URL';

  @override
  String get iptvPasswordLabel => 'Password';

  @override
  String get iptvPasswordHint => 'Xtream password';

  @override
  String get actionConnect => 'Connect';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Refresh IPTV playlists';

  @override
  String get statusActive => 'Active';

  @override
  String get statusNoActiveSource => 'No active source';

  @override
  String get overlayPreparingHome => 'Preparing home…';

  @override
  String get errorPrepareHome => 'Unable to prepare the home page';

  @override
  String get overlayOpeningHome => 'Opening home…';

  @override
  String get overlayRefreshingIptvLists => 'Refreshing IPTV lists…';

  @override
  String get overlayPreparingMetadata => 'Preparing metadata…';

  @override
  String get errorHomeLoadTimeout => 'Home load timeout';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Username';

  @override
  String get iptvUsernameHint => 'Xtream username';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionExpand => 'Expandir';

  @override
  String get actionCollapse => 'Contraer';

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
  String get libraryEmpty => 'No hay contenido disponible por ahora.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Búsqueda';

  @override
  String get notYetAvailable => 'Aún no disponible';
}
