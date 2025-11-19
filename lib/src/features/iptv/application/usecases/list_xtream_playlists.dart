import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class ListXtreamPlaylists {
  const ListXtreamPlaylists(this._repository);

  final IptvRepository _repository;

  Future<Result<List<XtreamPlaylist>, Failure>> call(String accountId) async {
    try {
      final playlists = await _repository.listPlaylists(accountId);
      return Ok(playlists);
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error, stack) {
      return Err(
        Failure.fromException(
          error,
          stackTrace: stack,
          code: 'iptv_list_playlists',
          context: {'accountId': accountId},
        ),
      );
    }
  }
}
