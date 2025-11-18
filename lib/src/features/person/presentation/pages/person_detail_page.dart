import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/person/presentation/providers/person_detail_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'dart:math';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, this.personSummary});

  final PersonSummary? personSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person =
        personSummary ?? (GoRouterState.of(context).extra as PersonSummary?);
    if (person == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: Text(
            'Aucune personnalité à afficher.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final vmAsync = ref.watch(personDetailControllerProvider(person.id.value));

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            'Erreur: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (vm) => _PersonDetailContent(vm: vm, person: person),
    );
  }
}

class _PersonDetailContent extends StatefulWidget {
  const _PersonDetailContent({
    required this.vm,
    required this.person,
  });

  final PersonDetailViewModel vm;
  final PersonSummary person;

  @override
  State<_PersonDetailContent> createState() => _PersonDetailContentState();
}

class _PersonDetailContentState extends State<_PersonDetailContent> {
  final Map<String, bool> _biographyExpanded = {};
  bool _isTransitioningFromLoading = true;

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _isTransitioningFromLoading = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const heroHeight = 500.0;
    final cs = Theme.of(context).colorScheme;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: AnimatedOpacity(
            opacity: _isTransitioningFromLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroImage(context, widget.vm.photo),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 100,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF141414),
                                    Color(0x00000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 20,
                            right: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.pop(),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 35,
                                        height: 35,
                                        child: Image.asset(AppAssets.iconBack),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.actionBack,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 180,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0xFF141414),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                bottom: 24,
                                left: 20,
                                right: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.vm.name,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${widget.vm.moviesCount} films - ${widget.vm.showsCount} séries',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: MoviPrimaryButton(
                                  label: 'Lire aléatoirement',
                                  assetIcon: AppAssets.iconPlay,
                                  onPressed: () {
                                    // TODO: Implémenter la lecture aléatoire
                                    final allMedia = [
                                      ...widget.vm.movies.map(
                                        (m) => MoviMedia(
                                          id: m.id.value,
                                          title: m.title.display,
                                          poster: m.poster,
                                          year: m.releaseYear,
                                          type: MoviMediaType.movie,
                                        ),
                                      ),
                                      ...widget.vm.shows.map(
                                        (s) => MoviMedia(
                                          id: s.id.value,
                                          title: s.title.display,
                                          poster: s.poster,
                                          type: MoviMediaType.series,
                                        ),
                                      ),
                                    ];
                                    if (allMedia.isNotEmpty) {
                                      final random = Random();
                                      final randomMedia =
                                          allMedia[random.nextInt(
                                            allMedia.length,
                                          )];
                                      context.push(
                                        randomMedia.type == MoviMediaType.movie
                                            ? AppRouteNames.movie
                                            : AppRouteNames.tv,
                                        extra: randomMedia,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Consumer(
                                builder: (context, ref, _) {
                                  final personId = widget.person.id.value;
                                  final isFavoriteAsync = ref.watch(
                                    personIsFavoriteProvider(personId),
                                  );
                                  return isFavoriteAsync.when(
                                    data: (isFavorite) => MoviFavoriteButton(
                                      isFavorite: isFavorite,
                                      onPressed: () async {
                                        await ref.read(
                                          personToggleFavoriteProvider.notifier,
                                        ).toggle(personId);
                                      },
                                    ),
                                    loading: () => MoviFavoriteButton(
                                      isFavorite: false,
                                      onPressed: () {},
                                    ),
                                    error: (_, __) => MoviFavoriteButton(
                                      isFavorite: false,
                                      onPressed: () {},
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (widget.vm.biography != null &&
                              widget.vm.biography!.isNotEmpty) ...[
                            _buildBiography(context, widget.vm.biography!),
                            const SizedBox(height: 32),
                          ],
                          if (widget.vm.movies.isNotEmpty) ...[
                            MoviItemsList(
                              title: 'Liste des films',
                              estimatedItemWidth: 150,
                              estimatedItemHeight: 300,
                              titlePadding: 0,
                              horizontalPadding: EdgeInsets.zero,
                              items: widget.vm.movies
                                  .map(
                                    (m) => MoviMedia(
                                      id: m.id.value,
                                      title: m.title.display,
                                      poster: m.poster,
                                      year: m.releaseYear,
                                      type: MoviMediaType.movie,
                                    ),
                                  )
                                  .toList()
                                  .map(
                                    (media) => MoviMediaCard(
                                      media: media,
                                      onTap: (m) => context.push(
                                        AppRouteNames.movie,
                                        extra: m,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                          if (widget.vm.shows.isNotEmpty) ...[
                            MoviItemsList(
                              title: 'Liste des séries',
                              estimatedItemWidth: 150,
                              estimatedItemHeight: 300,
                              titlePadding: 0,
                              horizontalPadding: EdgeInsets.zero,
                              items: widget.vm.shows
                                  .map(
                                    (s) => MoviMedia(
                                      id: s.id.value,
                                      title: s.title.display,
                                      poster: s.poster,
                                      type: MoviMediaType.series,
                                    ),
                                  )
                                  .toList()
                                  .map(
                                    (media) => MoviMediaCard(
                                      media: media,
                                      onTap: (m) => context.push(
                                        AppRouteNames.tv,
                                        extra: m,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Uri? photo) {
    if (photo == null) {
      return Image.asset(
        AppAssets.placeholderPersonActor,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, 0.1),
      );
    }
    final mq = MediaQuery.of(context);
    final int rawPx = (mq.size.width * mq.devicePixelRatio).round();
    final int cacheWidth = rawPx.clamp(480, 1920);
    return Image.network(
      photo.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(0.0, 0.1),
      errorBuilder: (_, __, ___) => Image.asset(
        AppAssets.placeholderPersonActor,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, 0.1),
      ),
    );
  }

  Widget _buildBiography(BuildContext context, String biography) {
    final personId = widget.person.id.value;
    final isExpanded = _biographyExpanded[personId] ?? false;

    final screenWidth = MediaQuery.of(context).size.width;
    // Le parent Column a déjà un padding de 20px de chaque côté
    final horizontalPadding = 20.0 + 20.0;
    final maxWidth = screenWidth - horizontalPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool needsExpansion = _needsExpansion(biography, maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
                'Biographie',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Text(
                    biography,
                    maxLines: isExpanded ? null : 3,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (needsExpansion)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _biographyExpanded[personId] = !isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded
                                ? AppLocalizations.of(context)!.actionCollapse
                                : AppLocalizations.of(context)!.actionExpand,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
        );
      },
    );
  }

  bool _needsExpansion(String text, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
