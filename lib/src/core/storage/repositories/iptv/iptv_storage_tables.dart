/// Centralizes the SQLite table names used by the IPTV local persistence layer.
///
/// Keeping these identifiers in one place avoids string drift when the
/// repository is decomposed into smaller collaborators.
final class IptvStorageTables {
  const IptvStorageTables._();

  static const String accounts = 'iptv_accounts';
  static const String stalkerAccounts = 'stalker_accounts';
  static const String playlistsLegacy = 'iptv_playlists';
  static const String playlists = 'iptv_playlists_v2';
  static const String playlistItems = 'iptv_playlist_items_v2';
  static const String episodes = 'iptv_episodes';
  static const String playlistSettings = 'iptv_playlist_settings';
  static const String routeProfiles = 'iptv_route_profiles';
  static const String sourceConnectionPolicies =
      'iptv_source_connection_policies';
}
