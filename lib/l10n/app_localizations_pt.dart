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
    return '($count resultados)';
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
  String get libraryTypeInProgress => 'Em andamento';

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
    return 'Pesquisar em $provider...';
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
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'Recuperar código PIN';

  @override
  String get pinRecoveryDescription =>
      'Recupere o código PIN do seu perfil protegido.';

  @override
  String get pinRecoveryComingSoon =>
      'Este recurso estará disponível em breve.';

  @override
  String get pinRecoveryCodeLabel => 'Código de recuperação';

  @override
  String get pinRecoveryCodeHint => '8 dígitos';

  @override
  String get pinRecoveryVerifyButton => 'Verificar';

  @override
  String get pinRecoveryCodeInvalid => 'Insira o código de 8 dígitos';

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
  String get pinRecoveryConfirmPinHint => 'Repita o PIN';

  @override
  String get pinRecoveryResetButton => 'Atualizar PIN';

  @override
  String get pinRecoveryPinInvalid => 'Insira um PIN de 4 a 6 dígitos';

  @override
  String get pinRecoveryPinMismatch => 'Os PINs não coincidem';

  @override
  String get pinRecoveryResetSuccess => 'PIN atualizado';

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
  String get settingsPreferredAudioLanguage => 'Idioma preferido';

  @override
  String get settingsPreferredSubtitleLanguage => 'Legendas preferidas';

  @override
  String get libraryPlaylistsFilter => 'Listas de reprodução';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistas';

  @override
  String get librarySearchPlaceholder => 'Pesquisar na minha biblioteca...';

  @override
  String get libraryInProgress => 'Em andamento';

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
    return 'Retomar T$season E$episode';
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
  String get playlistAddButton => 'Adicionar';

  @override
  String get playlistSortButton => 'Ordenar';

  @override
  String get playlistSortByTitle => 'Ordenar por';

  @override
  String get playlistSortByTitleOption => 'Título';

  @override
  String get playlistSortRecentAdditions => 'Adições recentes';

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
  String get playlistRenameTitle => 'Renomear lista';

  @override
  String get playlistNamePlaceholder => 'Nome da lista';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Lista renomeada para \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Excluir';

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
      'Digite seu email e o código de 8 dígitos que enviamos.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'seu@email';

  @override
  String get authOtpEmailHelp =>
      'Enviaremos um código de 8 dígitos. Verifique o spam se necessário.';

  @override
  String get authOtpCodeLabel => 'Código de verificação';

  @override
  String get authOtpCodeHint => 'Código de 8 dígitos';

  @override
  String get authOtpCodeHelp =>
      'Digite o código de 8 dígitos recebido por email.';

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
  String get resumePlayback => 'Retomar a reprodução';

  @override
  String get settingsCloudSyncSection => 'Sincronização na nuvem';

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
  String get hc_chargement_episodes_en_cours_33fc4ace =>
      'A carregar episódios…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Nenhuma playlist disponível. Crie uma.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Erro ao carregar playlists: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa =>
      'Não foi possível abrir o link';

  @override
  String get hc_qualite_preferee_776dbeea => 'Qualidade preferida';

  @override
  String get hc_annuler_49ba3292 => 'Cancel';

  @override
  String get hc_deconnexion_903dca17 => 'Terminar sessão';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Erro ao terminar sessão: \$e';

  @override
  String get hc_choisir_b030d590 => 'Choose';

  @override
  String get hc_avantages_08d7f47c => 'Benefits';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Denúncia enviada. Obrigado.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Mais tarde';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Reiniciar agora';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Usar esta fonte?';

  @override
  String get hc_utiliser_fb5e43ce => 'Use';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Fonte adicionada';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Definições bloqueadas';

  @override
  String get hc_compte_cloud_2812b31e => 'Conta cloud';

  @override
  String get hc_se_connecter_fedf2439 => 'Iniciar sessão';

  @override
  String get hc_propos_5345add5 => 'Sobre';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'Política de privacidade';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Termos de utilização';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Fontes guardadas';

  @override
  String get hc_rafraichir_be30b7d1 => 'Atualizar';

  @override
  String get hc_activer_une_source_749ced38 => 'Ativar uma fonte';

  @override
  String get hc_nom_source_9a3e4156 => 'Nome da fonte';

  @override
  String get hc_mon_iptv_b239352c => 'A minha IPTV';

  @override
  String get hc_username_84c29015 => 'Nome de utilizador';

  @override
  String get hc_password_8be3c943 => 'Palavra-passe';

  @override
  String get hc_server_url_1d5d1eff => 'URL do servidor';

  @override
  String get hc_verification_pin_e17c8fe0 => 'Verificação de PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'Definir um PIN';

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
      'Não disponível nesta fonte';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Fonte removida';

  @override
  String get hc_source_modifiee_335ef502 => 'Fonte atualizada';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'Definir código PIN';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Marcar como não visto';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Tens a certeza de que queres terminar sessão?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'É necessário o Movi Premium para a sincronização na cloud.';

  @override
  String get hc_auto_c614ba7c => 'Auto';

  @override
  String get hc_organiser_838a7e57 => 'Organizar';

  @override
  String get hc_modifier_f260e757 => 'Editar';

  @override
  String get hc_ajouter_87c57ed1 => 'Adicionar';

  @override
  String get hc_source_active_e571305e => 'Fonte ativa';

  @override
  String get hc_autres_sources_e32592a6 => 'Outras fontes';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'A denúncia não está disponível para este conteúdo.';

  @override
  String get hc_securisation_contenu_e5195111 => 'A proteger o conteúdo';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'A verificar classificações etárias…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Ver tudo';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Reportar um problema';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Se este conteúdo não for apropriado e estiver acessível apesar das restrições, descreve brevemente o problema.';

  @override
  String get hc_envoyer_e9ce243b => 'Enviar';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Perfil infantil criado';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Foi criado um perfil infantil. Para proteger a app e pré-carregar as classificações etárias, recomenda-se reiniciar a app.';

  @override
  String get hc_pseudo_4cf966c0 => 'Alcunha';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Perfil infantil';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Limite de idade';

  @override
  String get hc_code_pin_e79c48bd => 'Código PIN';

  @override
  String get hc_changer_code_pin_3b069731 => 'Alterar código PIN';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'Remover código PIN';

  @override
  String get hc_supprimer_pin_51850c7b => 'Remover PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'Eliminar';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Requer um PIN e ativa o filtro PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Queres ativar esta fonte agora?';

  @override
  String get hc_application_b291beb8 => 'Aplicação';

  @override
  String get hc_version_1_0_0_347e553c => 'Version 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Créditos';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Este produto utiliza a API do TMDB, mas não é endossado nem certificado pelo TMDB.';

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
  String get hc_url_invalide_aa227a66 => 'URL inválido';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Atualizar\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Menu\'';

  @override
  String get hc_retour_e5befb1f => 'Voltar';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Mais ações\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Mais ações';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c =>
      'semanticLabel: \'Pesquisar\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 =>
      'semanticLabel: \'Adicionar\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

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
  String get aboutTmdbDisclaimer =>
      'Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Créditos';
}
