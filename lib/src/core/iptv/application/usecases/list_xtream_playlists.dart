import '../../domain/entities/xtream_playlist.dart';
import '../../domain/repositories/iptv_repository.dart';

class ListXtreamPlaylists {
  const ListXtreamPlaylists(this._repository);

  final IptvRepository _repository;

  Future<List<XtreamPlaylist>> call(String accountId) {
    return _repository.listPlaylists(accountId);
  }
}
