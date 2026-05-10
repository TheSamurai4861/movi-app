import 'package:movi/src/core/startup/domain/boot_contracts.dart';

/// Local IPTV catalog state for one resolved source.
///
/// This contract only describes already-read local data. It does not read
/// storage, start network refreshes, log, or decide navigation by itself.
final class CatalogSnapshot {
  const CatalogSnapshot({
    required this.sourceId,
    required this.exists,
    required this.hasPlaylists,
    required this.hasItems,
    required this.mode,
    this.age,
  }) : assert(sourceId != ''),
       assert(hasPlaylists || !hasItems),
       assert(exists || (!hasPlaylists && !hasItems)),
       assert(
         mode == CatalogMode.fresh ||
                 mode == CatalogMode.cached ||
                 mode == CatalogMode.stale
             ? exists && hasPlaylists && hasItems
             : true,
       );

  /// Selected IPTV source/account id. This must never be used as a reason code.
  final String sourceId;

  /// Whether any local catalog snapshot exists for the source.
  final bool exists;

  /// Whether local playlist/category rows exist for the source.
  final bool hasPlaylists;

  /// Whether at least one playable local catalog item exists for the source.
  final bool hasItems;

  /// Startup-level interpretation of the local catalog state.
  final CatalogMode mode;

  /// Optional snapshot age.
  ///
  /// This stays nullable until the storage reader exposes freshness
  /// consistently for all supported IPTV source kinds.
  final Duration? age;

  /// Whether this local snapshot is enough to enter Home.
  bool get canOpenHome => mode.canOpenHome;
}
