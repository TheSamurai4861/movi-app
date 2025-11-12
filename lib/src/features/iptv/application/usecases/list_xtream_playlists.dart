import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class ListXtreamPlaylists {
  const ListXtreamPlaylists(this._repository);

  final IptvRepository _repository;

  Future<Result<List<XtreamPlaylist>, Failure>> call(String accountId) {
    return _repository
        .listPlaylists(accountId)
        .then<Result<List<XtreamPlaylist>, Failure>>((value) => Ok(value))
        .catchError(
          (error) => Err<List<XtreamPlaylist>, Failure>(error as Failure),
        );
  }
}
