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
  String get statusActive => 'Ativo';

  @override
  String get statusNoActiveSource => 'Nenhuma fonte ativa';

  @override
  String get overlayPreparingHome => 'Preparando início…';

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
  String libraryItemCount(int count) {
    return '$count elemento';
  }

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
}
