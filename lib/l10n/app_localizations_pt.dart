// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get welcomeTitle => 'Bem-vindo!';

  @override
  String get welcomeSubtitle =>
      'Complete suas preferências para personalizar o Movi.';

  @override
  String get labelUsername => 'Apelido';

  @override
  String get labelPreferredLanguage => 'Idioma preferido';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get hintUsername => 'Seu apelido';

  @override
  String get errorFillFields => 'Por favor, preencha os campos corretamente.';

  @override
  String get homeWatchNow => 'Assistir agora';

  @override
  String get welcomeSourceTitle => 'Bem-vindo!';

  @override
  String get welcomeSourceSubtitle =>
      'Adicione uma fonte para personalizar sua experiência no Movi.';

  @override
  String get welcomeSourceAdd => 'Adicionar uma fonte';

  @override
  String get searchTitle => 'Pesquisar';

  @override
  String get searchHint => 'Digite sua pesquisa';

  @override
  String get clear => 'Limpar';

  @override
  String get moviesTitle => 'Filmes';

  @override
  String get seriesTitle => 'Séries';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get historyEmpty => 'Sem pesquisas recentes';

  @override
  String get delete => 'Excluir';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Nenhum resultado',
    );
    return '$_temp0';
  }

  @override
  String get errorUnknown => 'Erro desconhecido';

  @override
  String errorConnectionFailed(String error) {
    return 'Falha na conexão: $error';
  }

  @override
  String get errorConnectionGeneric => 'Falha na conexão';

  @override
  String get validationRequired => 'Obrigatório';

  @override
  String get validationInvalidUrl => 'URL inválida';

  @override
  String get snackbarSourceAddedBackground =>
      'Fonte IPTV adicionada. Sincronização em segundo plano…';

  @override
  String get snackbarSourceAddedSynced =>
      'Fonte IPTV adicionada e sincronizada';

  @override
  String get navHome => 'Início';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Configurações';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguageLabel => 'Idioma do aplicativo';

  @override
  String get settingsGeneralTitle => 'Preferências gerais';

  @override
  String get settingsDarkModeTitle => 'Modo escuro';

  @override
  String get settingsDarkModeSubtitle => 'Ative um tema adequado para a noite.';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsNotificationsSubtitle =>
      'Seja notificado sobre novos lançamentos.';

  @override
  String get settingsAccountTitle => 'Conta';

  @override
  String get settingsProfileInfoTitle => 'Informações do perfil';

  @override
  String get settingsProfileInfoSubtitle => 'Nome, avatar, preferências';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsLegalMentionsTitle => 'Menções legais';

  @override
  String get settingsPrivacyPolicyTitle => 'Política de privacidade';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get settingsHelpDiagnosticsSection => 'Ajuda e diagnóstico';

  @override
  String get settingsExportErrorLogs => 'Exportar logs de erros';

  @override
  String get diagnosticsExportTitle => 'Exportar logs de erros';

  @override
  String get diagnosticsExportDescription =>
      'O diagnóstico inclui apenas logs WARN/ERROR recentes e identificadores de conta/perfil com hash (se ativado). Nenhuma chave/token deve aparecer.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Incluir identificadores de conta/perfil (hash)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Ajuda a correlacionar um bug sem expor o ID bruto.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Diagnóstico copiado para a área de transferência.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnóstico salvo: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Copiar';

  @override
  String get diagnosticsActionSave => 'Salvar';

  @override
  String get actionChangeVersion => 'Trocar versão';

  @override
  String get semanticsBack => 'Voltar';

  @override
  String get semanticsMoreActions => 'Mais ações';

  @override
  String get snackbarLoadingPlaylists => 'Carregando playlists…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Nenhuma playlist disponível. Crie uma.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Erro ao adicionar à playlist: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Este conteúdo já está nesta playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Erro ao carregar playlists: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'O envio do relatório não está disponível para este conteúdo.';

  @override
  String get snackbarLoadingEpisodes => 'Carregando episódios…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Episódio indisponível na playlist';

  @override
  String snackbarGenericError(String error) {
    return 'Erro: $error';
  }

  @override
  String get snackbarLoading => 'Carregando…';

  @override
  String get snackbarNoVersionAvailable => 'Nenhuma versão disponível';

  @override
  String get snackbarVersionSaved => 'Versão salva';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Versão $index';
  }

  @override
  String get actionReadMore => 'Ler mais';

  @override
  String get actionShowLess => 'Mostrar menos';

  @override
  String get actionViewPage => 'Ver página';

  @override
  String get semanticsSeeSagaPage => 'Ver página da saga';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'Continuar a ver';

  @override
  String get libraryTypeFavoriteMovies => 'Filmes favoritos';

  @override
  String get libraryTypeFavoriteSeries => 'Séries favoritas';

  @override
  String get libraryTypeHistory => 'Histórico';

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
    return 'Playlist renomeada para \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist excluída';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Nenhum resultado para \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Erro: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Este conteúdo já está na playlist';

  @override
  String get snackbarAddedToPlaylist => 'Adicionado à playlist';

  @override
  String get addMediaTitle => 'Adicionar mídia';

  @override
  String get searchMinCharsHint =>
      'Digite pelo menos 3 caracteres para pesquisar';

  @override
  String get badgeAdded => 'Adicionado';

  @override
  String get snackbarNotAvailableOnSource => 'Não disponível nesta fonte';

  @override
  String get errorLoadingTitle => 'Erro ao carregar';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Erro: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Erro ao carregar: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Remover filtro';

  @override
  String get homeErrorSwipeToRetry =>
      'Ocorreu um erro. Deslize para baixo para tentar novamente.';

  @override
  String get homeContinueWatching => 'Continuar assistindo';

  @override
  String get homeNoIptvSources =>
      'Nenhuma fonte IPTV ativa. Adicione uma fonte nas Configurações para ver suas categorias.';

  @override
  String get homeNoTrends => 'Nenhum conteúdo em tendência disponível';

  @override
  String get actionRefreshMetadata => 'Atualizar metadados';

  @override
  String get actionChangeMetadata => 'Alterar metadados';

  @override
  String get actionAddToList => 'Adicionar a uma lista';

  @override
  String get metadataRefreshed => 'Metadados atualizados';

  @override
  String get errorRefreshingMetadata => 'Erro ao atualizar metadados';

  @override
  String get actionMarkSeen => 'Marcar como assistido';

  @override
  String get actionMarkUnseen => 'Marcar como não assistido';

  @override
  String get actionReportProblem => 'Reportar um problema';

  @override
  String get featureComingSoon => 'Funcionalidade em breve';

  @override
  String get subtitlesMenuTitle => 'Legendas';

  @override
  String get audioMenuTitle => 'Áudio';

  @override
  String get videoFitModeMenuTitle => 'Modo de exibição';

  @override
  String get videoFitModeContain => 'Proporções originais';

  @override
  String get videoFitModeCover => 'Preencher tela';

  @override
  String get actionDisable => 'Desativar';

  @override
  String defaultTrackLabel(String id) {
    return 'Faixa $id';
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
  String get actionNextEpisode => 'Próximo episódio';

  @override
  String get actionRestart => 'Reiniciar';

  @override
  String get errorSeriesDataUnavailable =>
      'Não foi possível carregar os dados da série';

  @override
  String get errorNextEpisodeFailed =>
      'Não foi possível determinar o próximo episódio';

  @override
  String get actionLoadMore => 'Carregar mais';

  @override
  String get iptvServerUrlLabel => 'URL do servidor';

  @override
  String get iptvServerUrlHint => 'URL do servidor Xtream';

  @override
  String get iptvPasswordLabel => 'Senha';

  @override
  String get iptvPasswordHint => 'Senha Xtream';

  @override
  String get actionConnect => 'Conectar';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Atualizar playlists IPTV';

  @override
  String get activeSourceTitle => 'Fonte ativa';

  @override
  String get statusActive => 'Ativo';

  @override
  String get statusNoActiveSource => 'Nenhuma fonte ativa';

  @override
  String get overlayPreparingHome => 'Preparando início…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Carregando filmes e séries…';

  @override
  String get overlayLoadingCategories => 'Carregando categorias…';

  @override
  String get bootstrapRefreshing => 'Atualizando listas IPTV…';

  @override
  String get bootstrapEnriching => 'Preparando metadados…';

  @override
  String get errorPrepareHome => 'Não foi possível preparar a página inicial';

  @override
  String get overlayOpeningHome => 'Abrindo início…';

  @override
  String get overlayRefreshingIptvLists => 'Atualizando listas IPTV…';

  @override
  String get overlayPreparingMetadata => 'Preparando metadados…';

  @override
  String get errorHomeLoadTimeout =>
      'Tempo limite de carregamento da página inicial';

  @override
  String get faqLabel => 'Perguntas frequentes';

  @override
  String get iptvUsernameLabel => 'Nome de usuário';

  @override
  String get iptvUsernameHint => 'Nome de usuário Xtream';

  @override
  String get actionBack => 'Voltar';

  @override
  String get actionSeeAll => 'Ver tudo';

  @override
  String get actionExpand => 'Expandir';

  @override
  String get actionCollapse => 'Recolher';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Pesquisar em $provider';
  }

  @override
  String get actionClearHistory => 'Limpar histórico';

  @override
  String get castTitle => 'Elenco';

  @override
  String get recommendationsTitle => 'Recomendações';

  @override
  String get libraryHeader => 'Sua videoteca';

  @override
  String get libraryDataInfo =>
      'Os dados serão exibidos quando data/domain for implementado.';

  @override
  String get libraryEmpty =>
      'Curta filmes, séries ou atores para vê-los aparecer aqui.';

  @override
  String get serie => 'Série';

  @override
  String get recherche => 'Pesquisa';

  @override
  String get notYetAvailable => 'Ainda não disponível';

  @override
  String get createPlaylistTitle => 'Criar playlist';

  @override
  String get playlistName => 'Nome da playlist';

  @override
  String get addMedia => 'Adicionar mídias';

  @override
  String get renamePlaylist => 'Renomear';

  @override
  String get deletePlaylist => 'Excluir';

  @override
  String get pinPlaylist => 'Fixar';

  @override
  String get unpinPlaylist => 'Desafixar';

  @override
  String get playlistPinned => 'Playlist fixada';

  @override
  String get playlistUnpinned => 'Playlist desafixada';

  @override
  String get playlistDeleted => 'Playlist excluída';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" criada';
  }

  @override
  String playlistCreateError(String error) {
    return 'Erro ao criar playlist: $error';
  }

  @override
  String get addedToPlaylist => 'Adicionado';

  @override
  String get pinRecoveryLink => 'Recuperar PIN';

  @override
  String get pinRecoveryTitle => 'Recuperar PIN';

  @override
  String get pinRecoveryDescription =>
      'Vamos enviar um código de 8 dígitos para o e-mail da tua conta para repores o PIN deste perfil.';

  @override
  String get pinRecoveryRequestCodeButton => 'Enviar código';

  @override
  String get pinRecoveryCodeSentHint =>
      'O código foi enviado para o e-mail da sua conta. Verifique as suas mensagens e introduza-o abaixo.';

  @override
  String get pinRecoveryComingSoon =>
      'Este recurso estará disponível em breve.';

  @override
  String get pinRecoveryNotAvailable =>
      'A recuperação do PIN por e-mail não está disponível no momento.';

  @override
  String get pinRecoveryCodeLabel => 'Código de recuperação';

  @override
  String get pinRecoveryCodeHint => '8 dígitos';

  @override
  String get pinRecoveryVerifyButton => 'Verificar código';

  @override
  String get pinRecoveryCodeInvalid => 'Introduz o código de 8 dígitos.';

  @override
  String get pinRecoveryCodeExpired => 'O código de recuperação expirou';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Muitas tentativas. Tente novamente mais tarde.';

  @override
  String get pinRecoveryUnknownError => 'Ocorreu um erro inesperado';

  @override
  String get pinRecoveryNewPinLabel => 'Novo PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 dígitos';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirmar PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Confirmar PIN';

  @override
  String get pinRecoveryResetButton => 'Repor PIN';

  @override
  String get pinRecoveryPinInvalid => 'Introduz um PIN com 4 a 6 dígitos.';

  @override
  String get pinRecoveryPinMismatch => 'Os PINs não coincidem';

  @override
  String get pinRecoveryResetSuccess => 'PIN atualizado';

  @override
  String get profilePinSaved => 'PIN guardado.';

  @override
  String get profilePinEditLabel => 'Editar código PIN';

  @override
  String get settingsAccountsSection => 'Contas';

  @override
  String get settingsIptvSection => 'Configurações IPTV';

  @override
  String get settingsSourcesManagement => 'Gerenciamento de fontes';

  @override
  String get settingsSyncFrequency => 'Frequência de atualização';

  @override
  String get settingsAppSection => 'Configurações do aplicativo';

  @override
  String get settingsAccentColor => 'Cor de destaque';

  @override
  String get settingsPlaybackSection => 'Configurações de reprodução';

  @override
  String get settingsPreferredAudioLanguage => 'Idioma de áudio preferido';

  @override
  String get settingsPreferredSubtitleLanguage =>
      'Idioma das legendas preferido';

  @override
  String get libraryPlaylistsFilter => 'Listas de reprodução';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistas';

  @override
  String get librarySearchPlaceholder => 'Pesquisar na minha biblioteca...';

  @override
  String get libraryInProgress => 'Continuar a ver';

  @override
  String get libraryFavoriteMovies => 'Filmes favoritos';

  @override
  String get libraryFavoriteSeries => 'Séries favoritas';

  @override
  String get libraryWatchHistory => 'Histórico de visualização';

  @override
  String libraryItemCountPlural(int count) {
    return '$count elementos';
  }

  @override
  String get searchPeopleTitle => 'Pessoas';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'Por provedores';

  @override
  String get searchByGenresTitle => 'Por géneros';

  @override
  String get personRoleActor => 'Ator';

  @override
  String get personRoleDirector => 'Diretor';

  @override
  String get personRoleCreator => 'Criador';

  @override
  String get tvDistribution => 'Elenco';

  @override
  String tvSeasonLabel(int number) {
    return 'Temporada $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Nenhum episódio disponível';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Continuar S$season · E$episode';
  }

  @override
  String get sagaViewPage => 'Ver página';

  @override
  String get sagaStartNow => 'Começar agora';

  @override
  String get sagaContinue => 'Continuar';

  @override
  String sagaMovieCount(int count) {
    return '$count filmes';
  }

  @override
  String get sagaMoviesList => 'Lista de filmes';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies filmes - $shows séries';
  }

  @override
  String get personPlayRandomly => 'Reproduzir aleatoriamente';

  @override
  String get personMoviesList => 'Lista de filmes';

  @override
  String get personSeriesList => 'Lista de séries';

  @override
  String get playlistPlayRandomly => 'Reproduzir aleatoriamente';

  @override
  String get playlistAddButton => 'Adicionar à playlist';

  @override
  String get playlistSortButton => 'Ordenar';

  @override
  String get playlistSortByTitle => 'Ordenar por';

  @override
  String get playlistSortByTitleOption => 'Título';

  @override
  String get playlistSortRecentAdditions => 'Adicionados recentemente';

  @override
  String get playlistSortOldestFirst => 'Mais antigos primeiro';

  @override
  String get playlistSortNewestFirst => 'Mais recentes primeiro';

  @override
  String get playlistEmptyMessage => 'Nenhum item nesta lista';

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
  String get playlistRenameTitle => 'Mudar nome da playlist';

  @override
  String get playlistNamePlaceholder => 'Nome da lista';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Lista renomeada para \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Eliminar playlist';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get playlistDeletedSuccess => 'Lista excluída';

  @override
  String get playlistItemRemovedSuccess => 'Item removido';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Remover \"$title\" da lista?';
  }

  @override
  String get categoryLoadFailed => 'Falha ao carregar a categoria.';

  @override
  String get categoryEmpty => 'Nenhum item nesta categoria.';

  @override
  String get categoryLoadingMore => 'Carregando mais…';

  @override
  String get movieNoPlaylistsAvailable => 'Nenhuma playlist disponível';

  @override
  String playlistAddedTo(String title) {
    return 'Adicionado a \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'Filme não disponível na playlist';

  @override
  String errorPlaybackFailed(String message) {
    return 'Erro ao reproduzir o filme: $message';
  }

  @override
  String get movieNoMedia => 'Nenhum conteúdo para exibir';

  @override
  String get personNoData => 'Nenhuma pessoa para exibir.';

  @override
  String get personGenericError => 'Ocorreu um erro ao carregar esta pessoa.';

  @override
  String get personBiographyTitle => 'Biografia';

  @override
  String get authOtpTitle => 'Entrar';

  @override
  String get authOtpSubtitle =>
      'Introduz o teu e-mail e o código de 8 dígitos que te enviámos.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'nome@exemplo.com';

  @override
  String get authOtpEmailHelp =>
      'Enviaremos um código de 8 dígitos. Verifique o spam se necessário.';

  @override
  String get authOtpCodeLabel => 'Código de verificação';

  @override
  String get authOtpCodeHint => 'Código de 8 dígitos';

  @override
  String get authOtpCodeHelp =>
      'Introduz o código de 8 dígitos recebido por e-mail.';

  @override
  String get authOtpPrimarySend => 'Enviar código';

  @override
  String get authOtpPrimarySubmit => 'Entrar';

  @override
  String get authOtpResend => 'Reenviar código';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Reenviar código em ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Alterar email';

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
  String get authForgotPasswordTitle => 'Esqueci minha senha';

  @override
  String get authForgotPasswordSubtitle =>
      'Digite seu e-mail para receber um link de redefinição de senha.';

  @override
  String get authForgotPasswordInfoNeutral =>
      'Um e-mail de redefinição de senha será enviado para este endereço se a conta existir.';

  @override
  String get authForgotPasswordPrimarySubmit => 'Enviar link';

  @override
  String get authForgotPasswordBackToSignIn => 'Voltar para entrar';

  @override
  String get authPasswordUseOtp => 'Use email code instead';

  @override
  String get resumePlayback => 'Retomar a reprodução';

  @override
  String get settingsCloudSyncSection => 'Sincronização na cloud';

  @override
  String get settingsCloudSyncAuto => 'Sincronização automática';

  @override
  String get settingsCloudSyncNow => 'Sincronizar agora';

  @override
  String get settingsCloudSyncInProgress => 'A sincronizar…';

  @override
  String get settingsCloudSyncNever => 'Nunca';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Último erro: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return 'Não foi possível encontrar $entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return 'Não foi possível encontrar $entity: $error';
  }

  @override
  String get entityProvider => 'Fornecedor';

  @override
  String get entityGenre => 'Gênero';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Fonte';

  @override
  String get entityMovie => 'Filme';

  @override
  String get entitySeries => 'Série';

  @override
  String get entityPerson => 'Pessoa';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Vídeo';

  @override
  String get entityRoute => 'Rota';

  @override
  String get errorTimeoutLoading => 'Tempo limite ao carregar';

  @override
  String get parentalContentRestricted => 'Conteúdo restrito';

  @override
  String get parentalContentRestrictedDefault =>
      'Este conteúdo está bloqueado pelo controle parental deste perfil.';

  @override
  String get parentalReasonTooYoung =>
      'Este conteúdo requer uma idade superior ao limite deste perfil.';

  @override
  String get parentalReasonUnknownRating =>
      'A classificação etária deste conteúdo não está disponível.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Este conteúdo não pode ser avaliado para controle parental.';

  @override
  String get parentalUnlockButton => 'Desbloquear';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Sair';

  @override
  String get dialogSignOutBody => 'Tem certeza de que deseja sair?';

  @override
  String get settingsUnableToOpenLink => 'Não foi possível abrir o link';

  @override
  String get settingsSyncDisabled => 'Desativado';

  @override
  String get settingsSyncEveryHour => 'A cada hora';

  @override
  String get settingsSyncEvery2Hours => 'A cada 2 horas';

  @override
  String get settingsSyncEvery4Hours => 'A cada 4 horas';

  @override
  String get settingsSyncEvery6Hours => 'A cada 6 horas';

  @override
  String get settingsSyncEveryDay => 'Todos os dias';

  @override
  String get settingsSyncEvery2Days => 'A cada 2 dias';

  @override
  String get settingsColorCustom => 'Personalizado';

  @override
  String get settingsColorBlue => 'Azul';

  @override
  String get settingsColorPink => 'Rosa';

  @override
  String get settingsColorGreen => 'Verde';

  @override
  String get settingsColorPurple => 'Roxo';

  @override
  String get settingsColorOrange => 'Laranja';

  @override
  String get settingsColorTurquoise => 'Turquesa';

  @override
  String get settingsColorYellow => 'Amarelo';

  @override
  String get settingsColorIndigo => 'Índigo';

  @override
  String get settingsCloudAccountTitle => 'Conta na nuvem';

  @override
  String get settingsAccountConnected => 'Conectado';

  @override
  String get settingsAccountLocalMode => 'Modo local';

  @override
  String get settingsAccountCloudUnavailable => 'Nuvem indisponível';

  @override
  String get settingsSubtitlesTitle => 'Legendas';

  @override
  String get settingsSubtitlesSizeTitle => 'Tamanho do texto';

  @override
  String get settingsSubtitlesColorTitle => 'Cor do texto';

  @override
  String get settingsSubtitlesFontTitle => 'Fonte';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Sistema';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Configurações rápidas';

  @override
  String get settingsSubtitlesPreviewTitle => 'Pré-visualização';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Esta é uma prévia das legendas.\nAjuste a legibilidade em tempo real.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Fundo';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Opacidade do fundo';

  @override
  String get settingsSubtitlesShadowTitle => 'Sombra';

  @override
  String get settingsSubtitlesShadowOff => 'Desligada';

  @override
  String get settingsSubtitlesShadowSoft => 'Suave';

  @override
  String get settingsSubtitlesShadowStrong => 'Forte';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Tamanho fino';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Escala';

  @override
  String get settingsSubtitlesResetDefaults => 'Restaurar padrão';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Estilo avançado de legendas (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Fundo, opacidade, presets de sombra e tamanho fino estão disponíveis com Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Desbloquear com Premium';

  @override
  String get settingsSyncSectionTitle => 'Sincronização áudio/legendas';

  @override
  String get settingsSubtitleOffsetTitle => 'Deslocamento das legendas';

  @override
  String get settingsAudioOffsetTitle => 'Deslocamento de áudio';

  @override
  String get settingsOffsetUnsupported =>
      'Não suportado neste backend nem nesta plataforma.';

  @override
  String get settingsSyncResetOffsets => 'Repor deslocamentos de sincronização';

  @override
  String get aboutTmdbDisclaimer =>
      'Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Créditos';

  @override
  String get actionSend => 'Enviar';

  @override
  String get profilePinSetLabel => 'Definir código PIN';

  @override
  String get reportingProblemSentConfirmation =>
      'Sinalização enviada. Obrigado.';

  @override
  String get reportingProblemBody =>
      'Se este conteúdo for inadequado e tiver estado acessível apesar das restrições, descreva brevemente o problema.';

  @override
  String get reportingProblemExampleHint =>
      'Exemplo: filme de terror visível apesar de PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automático';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Qualidade de reprodução preferida';

  @override
  String settingsSignOutError(String error) {
    return 'Erro ao terminar sessão: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Termos de utilização';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'O Movi Premium é necessário para a sincronização na cloud.';
}
