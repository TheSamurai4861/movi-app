import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/person/presentation/providers/person_detail_providers.dart';
import 'package:movi/src/features/person/presentation/models/person_detail_view_model.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_hero_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_actions_row.dart';
import 'package:movi/src/features/person/presentation/widgets/person_biography_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_filmography_section.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  const PersonDetailPage({super.key, this.personSummary, this.personId});

  final PersonSummary? personSummary;
  final String? personId;

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  Timer? _autoRefreshTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(_loadingTimeout, () {
      final personId = _resolvePersonId(context);
      if (mounted && personId != null && _retryCount < _maxRetries) {
        final vmAsync = ref.read(
          personDetailControllerProvider(personId),
        );
        // Si toujours en chargement après le timeout, relancer
        if (vmAsync.isLoading) {
          _retryCount++;
          ref.invalidate(personDetailControllerProvider(personId));
          _startAutoRefreshTimer();
        }
      }
    });
  }

  String? _resolvePersonId(BuildContext context) {
    if (widget.personSummary != null) return widget.personSummary!.id.value;
    if (widget.personId != null && widget.personId!.trim().isNotEmpty) {
      return widget.personId!.trim();
    }
    final extra = GoRouterState.of(context).extra;
    if (extra is PersonSummary) return extra.id.value;
    if (extra is String) return extra.trim().isEmpty ? null : extra.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final personId = _resolvePersonId(context);
    if (personId == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            l10n.personNoData,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final vmAsync = ref.watch(personDetailControllerProvider(personId));

    // Détecter les erreurs et relancer automatiquement
    vmAsync.whenOrNull(
      error: (e, st) {
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retryCount++;
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(
                    personDetailControllerProvider(personId),
                  );
                  _startAutoRefreshTimer();
                }
              });
            }
          });
        }
      },
      data: (_) {
        // Le chargement a réussi, annuler le timer et réinitialiser
        _autoRefreshTimer?.cancel();
        _retryCount = 0;
      },
    );

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.personGenericError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              MoviPrimaryButton(
                label: AppLocalizations.of(context)!.actionRetry,
                onPressed: () {
                  final personId = _resolvePersonId(context);
                  if (personId == null) return;
                  ref.invalidate(
                    personDetailControllerProvider(personId),
                  );
                  _startAutoRefreshTimer();
                },
              ),
            ],
          ),
        ),
      ),
      data: (vm) => _PersonDetailContent(vm: vm, personId: personId),
    );
  }
}

class _PersonDetailContent extends StatefulWidget {
  const _PersonDetailContent({required this.vm, required this.personId});

  final PersonDetailViewModel vm;
  final String personId;

  @override
  State<_PersonDetailContent> createState() => _PersonDetailContentState();
}

class _PersonDetailContentState extends State<_PersonDetailContent> {
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
                        PersonDetailHeroSection(
                          photo: widget.vm.photo,
                          name: widget.vm.name,
                          moviesCount: widget.vm.moviesCount,
                          showsCount: widget.vm.showsCount,
                          height: heroHeight,
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
                              PersonDetailActionsRow(
                                personId: widget.personId,
                                movies: widget.vm.movies
                                    .map(
                                      (m) => MoviMedia(
                                        id: m.id.value,
                                        title: m.title.display,
                                        poster: m.poster,
                                        year: m.releaseYear,
                                        type: MoviMediaType.movie,
                                      ),
                                    )
                                    .toList(growable: false),
                                shows: widget.vm.shows
                                    .map(
                                      (s) => MoviMedia(
                                        id: s.id.value,
                                        title: s.title.display,
                                        poster: s.poster,
                                        type: MoviMediaType.series,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 32),
                              if (widget.vm.biography != null &&
                                  widget.vm.biography!.isNotEmpty) ...[
                                PersonBiographySection(
                                  biography: widget.vm.biography!,
                                ),
                                const SizedBox(height: 32),
                              ],
                              PersonFilmographySection(
                                movies: widget.vm.movies
                                    .map(
                                      (m) => MoviMedia(
                                        id: m.id.value,
                                        title: m.title.display,
                                        poster: m.poster,
                                        year: m.releaseYear,
                                        type: MoviMediaType.movie,
                                      ),
                                    )
                                    .toList(growable: false),
                                shows: widget.vm.shows
                                    .map(
                                      (s) => MoviMedia(
                                        id: s.id.value,
                                        title: s.title.display,
                                        poster: s.poster,
                                        type: MoviMediaType.series,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
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

  // Biography and hero image are now handled by dedicated widgets:
  // - PersonDetailHeroSection
  // - PersonBiographySection
}
