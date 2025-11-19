import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/library/library_constants.dart';

void main() {
  group('LibrarySearchQueryController', () {
    test('initialise avec une chaîne vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = container.read(librarySearchQueryProvider);

      expect(query, '');
    });

    test('met à jour la requête de recherche', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(librarySearchQueryProvider.notifier).setQuery('test');

      final query = container.read(librarySearchQueryProvider);

      expect(query, 'test');
    });

    test('peut réinitialiser la requête à vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(librarySearchQueryProvider.notifier).setQuery('test');
      container.read(librarySearchQueryProvider.notifier).setQuery('');

      final query = container.read(librarySearchQueryProvider);

      expect(query, '');
    });
  });

  group('LibraryFilterController', () {
    test('initialise avec null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(libraryFilterProvider);

      expect(filter, isNull);
    });

    test('met à jour le filtre actif à "playlists"', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.playlists);

      final filter = container.read(libraryFilterProvider);

      expect(filter, LibraryFilterType.playlists);
    });

    test('met à jour le filtre actif à "sagas"', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.sagas);

      final filter = container.read(libraryFilterProvider);

      expect(filter, LibraryFilterType.sagas);
    });

    test('met à jour le filtre actif à "artistes"', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.artistes);

      final filter = container.read(libraryFilterProvider);

      expect(filter, LibraryFilterType.artistes);
    });

    test('peut remettre le filtre à null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.playlists);
      container.read(libraryFilterProvider.notifier).setFilter(null);

      final filter = container.read(libraryFilterProvider);

      expect(filter, isNull);
    });
  });

  group('filteredLibraryPlaylistsProvider - filtrage par type', () {
    test('filtre les playlists par type "playlists"', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: LibraryConstants.inProgressPlaylistId,
          title: 'En cours',
          itemCount: 1,
          type: LibraryPlaylistType.inProgress,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.actorPrefix}123',
          title: 'Tom Hanks',
          itemCount: 0,
          type: LibraryPlaylistType.actor,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.sagaPrefix}456',
          title: 'Star Wars',
          itemCount: 0,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Activer le filtre "playlists"
      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.playlists);

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 1);
          expect(filtered.first.id, LibraryConstants.inProgressPlaylistId);
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });

    test('filtre les playlists par type "sagas"', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: LibraryConstants.inProgressPlaylistId,
          title: 'En cours',
          itemCount: 1,
          type: LibraryPlaylistType.inProgress,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.sagaPrefix}456',
          title: 'Star Wars',
          itemCount: 0,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Activer le filtre "sagas"
      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.sagas);

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 1);
          expect(filtered.first.id, '${LibraryConstants.sagaPrefix}456');
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });

    test('filtre les playlists par type "artistes"', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: LibraryConstants.inProgressPlaylistId,
          title: 'En cours',
          itemCount: 1,
          type: LibraryPlaylistType.inProgress,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.actorPrefix}123',
          title: 'Tom Hanks',
          itemCount: 0,
          type: LibraryPlaylistType.actor,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Activer le filtre "artistes"
      container
          .read(libraryFilterProvider.notifier)
          .setFilter(LibraryFilterType.artistes);

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 1);
          expect(filtered.first.type, LibraryPlaylistType.actor);
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });

    test('retourne toutes les playlists quand aucun filtre n\'est actif', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: LibraryConstants.inProgressPlaylistId,
          title: 'En cours',
          itemCount: 1,
          type: LibraryPlaylistType.inProgress,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.actorPrefix}123',
          title: 'Tom Hanks',
          itemCount: 0,
          type: LibraryPlaylistType.actor,
        ),
        const LibraryPlaylistItem(
          id: '${LibraryConstants.sagaPrefix}456',
          title: 'Star Wars',
          itemCount: 0,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Aucun filtre actif (null par défaut)
      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 3);
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });
  });

  group('filteredLibraryPlaylistsProvider - recherche textuelle', () {
    test('filtre les playlists par recherche textuelle', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: '1',
          title: 'Action Films',
          itemCount: 5,
          type: LibraryPlaylistType.userPlaylist,
        ),
        const LibraryPlaylistItem(
          id: '2',
          title: 'Comédies',
          itemCount: 3,
          type: LibraryPlaylistType.userPlaylist,
        ),
        const LibraryPlaylistItem(
          id: '3',
          title: 'Documentaires',
          itemCount: 2,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Définir une recherche
      container.read(librarySearchQueryProvider.notifier).setQuery('com');

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 1);
          expect(filtered.first.title, 'Comédies');
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });

    test('recherche textuelle est insensible à la casse', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: '1',
          title: 'Action Films',
          itemCount: 5,
          type: LibraryPlaylistType.userPlaylist,
        ),
        const LibraryPlaylistItem(
          id: '2',
          title: 'Comédies',
          itemCount: 3,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Recherche en majuscules
      container.read(librarySearchQueryProvider.notifier).setQuery('ACTION');

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered.length, 1);
          expect(filtered.first.title, 'Action Films');
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });

    test('retourne liste vide si aucune correspondance textuelle', () {
      // Arrange
      final playlists = [
        const LibraryPlaylistItem(
          id: '1',
          title: 'Action Films',
          itemCount: 5,
          type: LibraryPlaylistType.userPlaylist,
        ),
        const LibraryPlaylistItem(
          id: '2',
          title: 'Comédies',
          itemCount: 3,
          type: LibraryPlaylistType.userPlaylist,
        ),
      ];

      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.data(playlists),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Recherche qui ne correspond à rien
      container.read(librarySearchQueryProvider.notifier).setQuery('xyz');

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      result.when(
        data: (filtered) {
          expect(filtered, isEmpty);
        },
        loading: () => fail('Should not be loading'),
        error: (_, __) => fail('Should not have error'),
      );
    });
  });

  group(
    'filteredLibraryPlaylistsProvider - combinaison filtre et recherche',
    () {
      test('combine filtre de type et recherche textuelle', () {
        // Arrange
        final playlists = [
          const LibraryPlaylistItem(
            id: LibraryConstants.inProgressPlaylistId,
            title: 'En cours',
            itemCount: 1,
            type: LibraryPlaylistType.inProgress,
          ),
          const LibraryPlaylistItem(
            id: '${LibraryConstants.actorPrefix}1',
            title: 'Tom Hanks',
            itemCount: 0,
            type: LibraryPlaylistType.actor,
          ),
          const LibraryPlaylistItem(
            id: '${LibraryConstants.actorPrefix}2',
            title: 'Tom Cruise',
            itemCount: 0,
            type: LibraryPlaylistType.actor,
          ),
          const LibraryPlaylistItem(
            id: '${LibraryConstants.actorPrefix}3',
            title: 'Brad Pitt',
            itemCount: 0,
            type: LibraryPlaylistType.actor,
          ),
        ];

        // Act
        final container = ProviderContainer(
          overrides: [
            libraryPlaylistsProvider.overrideWithValue(
              AsyncValue.data(playlists),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Activer le filtre "artistes" et recherche "hanks"
        container
            .read(libraryFilterProvider.notifier)
            .setFilter(LibraryFilterType.artistes);
        container.read(librarySearchQueryProvider.notifier).setQuery('hanks');

        final result = container.read(filteredLibraryPlaylistsProvider);

        // Assert
        result.when(
          data: (filtered) {
            expect(filtered.length, 1);
            expect(filtered.first.title, 'Tom Hanks');
          },
          loading: () => fail('Should not be loading'),
          error: (_, __) => fail('Should not have error'),
        );
      });

      test('recherche textuelle sans filtre de type', () {
        // Arrange
        final playlists = [
          const LibraryPlaylistItem(
            id: LibraryConstants.inProgressPlaylistId,
            title: 'Films en cours',
            itemCount: 1,
            type: LibraryPlaylistType.inProgress,
          ),
          const LibraryPlaylistItem(
            id: '${LibraryConstants.actorPrefix}1',
            title: 'Tom Hanks',
            itemCount: 0,
            type: LibraryPlaylistType.actor,
          ),
          const LibraryPlaylistItem(
            id: '1',
            title: 'Mes films préférés',
            itemCount: 5,
            type: LibraryPlaylistType.userPlaylist,
          ),
        ];

        // Act
        final container = ProviderContainer(
          overrides: [
            libraryPlaylistsProvider.overrideWithValue(
              AsyncValue.data(playlists),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Recherche "films" sans filtre de type
        container.read(librarySearchQueryProvider.notifier).setQuery('films');

        final result = container.read(filteredLibraryPlaylistsProvider);

        // Assert
        result.when(
          data: (filtered) {
            expect(filtered.length, 2);
            expect(filtered.any((p) => p.title == 'Films en cours'), isTrue);
            expect(
              filtered.any((p) => p.title == 'Mes films préférés'),
              isTrue,
            );
          },
          loading: () => fail('Should not be loading'),
          error: (_, __) => fail('Should not have error'),
        );
      });
    },
  );

  group('filteredLibraryPlaylistsProvider - états d\'erreur', () {
    test('propage l\'état de chargement', () {
      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            const AsyncValue.loading(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      expect(result.isLoading, isTrue);
    });

    test('propage l\'état d\'erreur', () {
      // Act
      final container = ProviderContainer(
        overrides: [
          libraryPlaylistsProvider.overrideWithValue(
            AsyncValue.error('Test error', StackTrace.empty),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(filteredLibraryPlaylistsProvider);

      // Assert
      expect(result.hasError, isTrue);
      result.when(
        data: (_) => fail('Should not have data'),
        loading: () => fail('Should not be loading'),
        error: (error, _) => expect(error, 'Test error'),
      );
    });
  });
}
