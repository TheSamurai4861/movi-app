import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';

abstract class RouteProfileRepository {
  Future<List<RouteProfile>> listProfiles();
  Future<RouteProfile?> getProfileById(String id);
  Future<RouteProfile> saveProfile(RouteProfile profile);
  Future<void> deleteProfile(String id);
}
