import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';
import 'package:movi/src/features/player/presentation/providers/player_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/premium_feature_locked_sheet.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class SettingsSubtitlesPage extends ConsumerStatefulWidget {
  const SettingsSubtitlesPage({super.key});

  @override
  ConsumerState<SettingsSubtitlesPage> createState() =>
      _SettingsSubtitlesPageState();
}

class _SettingsSubtitlesPageState extends ConsumerState<SettingsSubtitlesPage> {
  static const double _focusVerticalAlignment = 0.22;
  static const double _colorSwatchSize = 42;
  final FocusNode _backFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesBack',
  );
  final List<FocusNode> _sizePresetFocusNodes = List<FocusNode>.generate(
    SubtitleSizePreset.values.length,
    (index) => FocusNode(debugLabel: 'SettingsSubtitlesSizePreset$index'),
  );
  final List<FocusNode> _textColorFocusNodes = List<FocusNode>.generate(
    SubtitleAppearancePrefs.subtitleColorChoices.length,
    (index) => FocusNode(debugLabel: 'SettingsSubtitlesTextColor$index'),
  );
  final FocusNode _subtitleOffsetSliderFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesSubtitleOffsetSlider',
  );
  final List<FocusNode> _subtitleOffsetPresetFocusNodes =
      List<FocusNode>.generate(
        _OffsetPresetButtons.presets.length,
        (index) => FocusNode(
          debugLabel: 'SettingsSubtitlesSubtitleOffsetPreset$index',
        ),
      );
  final FocusNode _audioOffsetSliderFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesAudioOffsetSlider',
  );
  final List<FocusNode> _audioOffsetPresetFocusNodes = List<FocusNode>.generate(
    _OffsetPresetButtons.presets.length,
    (index) =>
        FocusNode(debugLabel: 'SettingsSubtitlesAudioOffsetPreset$index'),
  );
  final FocusNode _resetOffsetsFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesResetOffsets',
  );
  final FocusNode _premiumLockedActionFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesPremiumLockedAction',
  );
  final List<FocusNode> _backgroundColorFocusNodes = List<FocusNode>.generate(
    SubtitleAppearancePrefs.subtitleBackgroundColorChoices.length,
    (index) => FocusNode(debugLabel: 'SettingsSubtitlesBackgroundColor$index'),
  );
  final FocusNode _backgroundOpacitySliderFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesBackgroundOpacitySlider',
  );
  final List<FocusNode> _shadowPresetFocusNodes = List<FocusNode>.generate(
    SubtitleShadowPreset.values.length,
    (index) => FocusNode(debugLabel: 'SettingsSubtitlesShadowPreset$index'),
  );
  final FocusNode _fineSizeSliderFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesFineSizeSlider',
  );
  final FocusNode _resetDefaultsFocusNode = FocusNode(
    debugLabel: 'SettingsSubtitlesResetDefaults',
  );

  double? _previewBackgroundOpacity;

  @override
  void dispose() {
    _backFocusNode.dispose();
    for (final node in _sizePresetFocusNodes) {
      node.dispose();
    }
    for (final node in _textColorFocusNodes) {
      node.dispose();
    }
    _subtitleOffsetSliderFocusNode.dispose();
    for (final node in _subtitleOffsetPresetFocusNodes) {
      node.dispose();
    }
    _audioOffsetSliderFocusNode.dispose();
    for (final node in _audioOffsetPresetFocusNodes) {
      node.dispose();
    }
    _resetOffsetsFocusNode.dispose();
    _premiumLockedActionFocusNode.dispose();
    for (final node in _backgroundColorFocusNodes) {
      node.dispose();
    }
    _backgroundOpacitySliderFocusNode.dispose();
    for (final node in _shadowPresetFocusNodes) {
      node.dispose();
    }
    _fineSizeSliderFocusNode.dispose();
    _resetDefaultsFocusNode.dispose();
    super.dispose();
  }

  double? _previewFontScale;
  int? _previewSubtitleOffsetMs;
  int? _previewAudioOffsetMs;

  int _selectedSizePresetIndex(SubtitleAppearancePrefs prefs) {
    return SubtitleSizePreset.values
        .indexOf(prefs.sizePreset)
        .clamp(0, SubtitleSizePreset.values.length - 1);
  }

  int _selectedTextColorIndex(SubtitleAppearancePrefs prefs) {
    final index = SubtitleAppearancePrefs.subtitleColorChoices.indexWhere(
      (choice) => choice.hex == prefs.textColorHex,
    );
    return index >= 0 ? index : 0;
  }

  int _nearestPresetIndex(int selectedOffsetMs) {
    final presets = _OffsetPresetButtons.presets;
    var bestIndex = 0;
    var bestDelta = (presets.first - selectedOffsetMs).abs();
    for (var i = 1; i < presets.length; i++) {
      final delta = (presets[i] - selectedOffsetMs).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int _selectedBackgroundColorIndex(SubtitleAppearancePrefs prefs) {
    final index = SubtitleAppearancePrefs.subtitleBackgroundColorChoices
        .indexWhere((choice) => choice.hex == prefs.backgroundColorHex);
    return index >= 0 ? index : 0;
  }

  int _selectedShadowPresetIndex(SubtitleAppearancePrefs prefs) {
    return SubtitleShadowPreset.values
        .indexOf(prefs.shadowPreset)
        .clamp(0, SubtitleShadowPreset.values.length - 1);
  }

  /// Masque les sections avancées uniquement sur un poste TV natif (Android TV).
  ///
  /// Ne pas utiliser [ScreenType.tv] ici : sur Windows, le resolver force `tv`
  /// pour l'UI type télécommande, mais ce n'est pas un téléviseur.
  bool _hideTvOnlySubtitleSections(BuildContext context) {
    return context.isTelevisionDevice;
  }

  FocusNode _focusNodeBelowTextColor({
    required bool hideTvOnlySections,
    required bool hasAdvancedSubtitleStyling,
    required int selectedBackgroundColorIndex,
  }) {
    if (!hideTvOnlySections) {
      return _subtitleOffsetSliderFocusNode;
    }
    if (hasAdvancedSubtitleStyling) {
      return _backgroundColorFocusNodes[selectedBackgroundColorIndex];
    }
    return _premiumLockedActionFocusNode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hideTvOnlySections = _hideTvOnlySubtitleSections(context);
    final prefs = ref.watch(asp.currentProfileSubtitleAppearanceProvider);
    final controller = ref.read(asp.subtitleAppearanceControllerProvider);
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final syncOffsets = ref.watch(
      asp.currentProfilePlaybackSyncOffsetsProvider,
    );
    final syncController = ref.read(asp.playbackSyncOffsetControllerProvider);
    final subtitleOffsetSupportedAsync = ref.watch(
      subtitleOffsetSupportProvider,
    );
    final audioOffsetSupportedAsync = ref.watch(audioOffsetSupportProvider);
    final subtitleOffsetSupported = subtitleOffsetSupportedAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    final audioOffsetSupported = audioOffsetSupportedAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    final hasAdvancedSubtitleStyling = ref
        .watch(
          canAccessPremiumFeatureProvider(
            PremiumFeature.advancedSubtitleStyling,
          ),
        )
        .maybeWhen(data: (value) => value, orElse: () => false);
    final subtitleOffsetMs =
        _previewSubtitleOffsetMs ?? syncOffsets.subtitleOffsetMs;
    final audioOffsetMs = _previewAudioOffsetMs ?? syncOffsets.audioOffsetMs;
    final previewPrefs = prefs.copyWith(
      backgroundOpacity: _previewBackgroundOpacity ?? prefs.backgroundOpacity,
      fontScale: _previewFontScale ?? prefs.fontScale,
    );
    final selectedSizePresetIndex = _selectedSizePresetIndex(prefs);
    final selectedTextColorIndex = _selectedTextColorIndex(prefs);
    final selectedSubtitlePresetIndex = _nearestPresetIndex(subtitleOffsetMs);
    final selectedAudioPresetIndex = _nearestPresetIndex(audioOffsetMs);
    final selectedBackgroundColorIndex = _selectedBackgroundColorIndex(
      previewPrefs,
    );
    final selectedShadowPresetIndex = _selectedShadowPresetIndex(previewPrefs);

    return FocusRegionScope(
      regionId: AppFocusRegionId.settingsSubtitlesPrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => _sizePresetFocusNodes.first,
        resolveFallbackEntryNode: () => _backFocusNode,
      ),
      requestFocusOnMount: true,
      handleDirectionalExits: false,
      debugLabel: 'SettingsSubtitlesPrimaryRegion',
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => FocusDirectionalNavigation.handleBackKey(
          event,
          onBack: () {
            context.pop();
            return true;
          },
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SettingsContentWidth(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: _SettingsSubtitlesLayout.scrollBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FocusRegionScope(
                      regionId: AppFocusRegionId.settingsSubtitlesHeader,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () => _backFocusNode,
                      ),
                      handleDirectionalExits: false,
                      debugLabel: 'SettingsSubtitlesHeaderRegion',
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) =>
                            FocusDirectionalNavigation.handleDirectionalKey(
                              event,
                              down: _sizePresetFocusNodes.first,
                            ),
                        child: MoviEnsureVisibleOnFocus(
                          verticalAlignment: _focusVerticalAlignment,
                          child: MoviSubpageBackTitleHeader(
                            title: l10n.settingsSubtitlesTitle,
                            focusNode: _backFocusNode,
                            onBack: () => context.pop(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: _SettingsSubtitlesLayout.headerToContentGap,
                    ),
                    FocusRegionScope(
                      regionId: AppFocusRegionId.settingsSubtitlesAppearance,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () =>
                            _sizePresetFocusNodes.first,
                      ),
                      handleDirectionalExits: false,
                      debugLabel: 'SettingsSubtitlesAppearanceRegion',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _SettingsSubtitlesLayout
                                  .pageHorizontalPadding,
                            ),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesSizeTitle,
                              child: Wrap(
                                spacing: _SettingsSubtitlesLayout.chipSpacing,
                                runSpacing:
                                    _SettingsSubtitlesLayout.chipSpacing,
                                children: SubtitleSizePreset.values
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final preset = entry.value;
                                      final selected =
                                          prefs.sizePreset == preset;
                                      return MoviEnsureVisibleOnFocus(
                                        verticalAlignment:
                                            _focusVerticalAlignment,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleVerticalListKey(
                                                event,
                                                index: index,
                                                nodes: _sizePresetFocusNodes,
                                                up: _backFocusNode,
                                                down:
                                                    _textColorFocusNodes[selectedTextColorIndex],
                                              ),
                                          child: _SubtitlePresetBadge(
                                            label: _sizeLabel(l10n, preset),
                                            selected: selected,
                                            accentColor: accentColor,
                                            focusNode:
                                                _sizePresetFocusNodes[index],
                                            onPressed: () => controller
                                                .setSizePreset(preset),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: _SettingsSubtitlesLayout.sectionGap,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _SettingsSubtitlesLayout
                                  .pageHorizontalPadding,
                            ),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesColorTitle,
                              child: Wrap(
                                spacing: _SettingsSubtitlesLayout.chipSpacing,
                                runSpacing:
                                    _SettingsSubtitlesLayout.chipSpacing,
                                children: SubtitleAppearancePrefs
                                    .subtitleColorChoices
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final choice = entry.value;
                                      final selected =
                                          prefs.textColorHex == choice.hex;
                                      final color = _hexToColor(choice.hex);
                                      return MoviEnsureVisibleOnFocus(
                                        verticalAlignment:
                                            _focusVerticalAlignment,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleHorizontalGroupKey(
                                                event,
                                                index: index,
                                                nodes: _textColorFocusNodes,
                                                up: _sizePresetFocusNodes[selectedSizePresetIndex],
                                                down: _focusNodeBelowTextColor(
                                                  hideTvOnlySections:
                                                      hideTvOnlySections,
                                                  hasAdvancedSubtitleStyling:
                                                      hasAdvancedSubtitleStyling,
                                                  selectedBackgroundColorIndex:
                                                      selectedBackgroundColorIndex,
                                                ),
                                              ),
                                          child: MoviFocusableAction(
                                            focusNode:
                                                _textColorFocusNodes[index],
                                            onPressed: () => controller
                                                .setTextColorHex(choice.hex),
                                            semanticLabel: choice.hex,
                                            builder: (context, state) =>
                                                _ColorCircle(
                                                  color: color,
                                                  selected:
                                                      selected || state.focused,
                                                  accentColor: accentColor,
                                                  size: _colorSwatchSize,
                                                ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // TV: section Synchronisation Audio/ST masquée (PC + mobile uniquement).
                    if (!hideTvOnlySections) ...[
                      const SizedBox(
                        height: _SettingsSubtitlesLayout.sectionGap,
                      ),
                      FocusRegionScope(
                        regionId: AppFocusRegionId.settingsSubtitlesOffsets,
                        binding: FocusRegionBinding(
                          resolvePrimaryEntryNode: () =>
                              _subtitleOffsetSliderFocusNode,
                          resolveFallbackEntryNode: () =>
                              _resetOffsetsFocusNode,
                        ),
                        handleDirectionalExits: false,
                        debugLabel: 'SettingsSubtitlesOffsetsRegion',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                _SettingsSubtitlesLayout.pageHorizontalPadding,
                          ),
                          child: _SectionCard(
                            title: l10n.settingsSyncSectionTitle,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.settingsSubtitleOffsetTitle}: ${_formatOffsetLabel(subtitleOffsetMs)}',
                                  style: _SettingsSubtitlesLayout.bodyStyle,
                                ),
                                Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleSliderKey(
                                        event,
                                        up: _textColorFocusNodes[selectedTextColorIndex],
                                        down:
                                            _subtitleOffsetPresetFocusNodes[selectedSubtitlePresetIndex],
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
                                    child: Slider(
                                      focusNode: _subtitleOffsetSliderFocusNode,
                                      value: subtitleOffsetMs.toDouble(),
                                      min: PlaybackSyncOffsets.minOffsetMs
                                          .toDouble(),
                                      max: PlaybackSyncOffsets.maxOffsetMs
                                          .toDouble(),
                                      divisions: 40,
                                      onChanged: subtitleOffsetSupported
                                          ? (value) {
                                              setState(
                                                () => _previewSubtitleOffsetMs =
                                                    value.round(),
                                              );
                                            }
                                          : null,
                                      onChangeEnd: subtitleOffsetSupported
                                          ? (value) async {
                                              final rounded = value.round();
                                              setState(
                                                () => _previewSubtitleOffsetMs =
                                                    null,
                                              );
                                              await syncController
                                                  .setSubtitleOffsetMs(
                                                    rounded,
                                                    source:
                                                        'settings_slider_subtitle',
                                                  );
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                                _OffsetPresetButtons(
                                  selectedOffsetMs: subtitleOffsetMs,
                                  focusNodes: _subtitleOffsetPresetFocusNodes,
                                  verticalAlignment: _focusVerticalAlignment,
                                  onKeyEvent: (index, event) =>
                                      FocusDirectionalNavigation.handleHorizontalGroupKey(
                                        event,
                                        index: index,
                                        nodes: _subtitleOffsetPresetFocusNodes,
                                        up: _subtitleOffsetSliderFocusNode,
                                        down: _audioOffsetSliderFocusNode,
                                      ),
                                  onPresetSelected: subtitleOffsetSupported
                                      ? (offsetMs) =>
                                            syncController.setSubtitleOffsetMs(
                                              offsetMs,
                                              source:
                                                  'settings_preset_subtitle',
                                            )
                                      : null,
                                ),
                                if (!subtitleOffsetSupported) ...[
                                  const SizedBox(
                                    height: _SettingsSubtitlesLayout
                                        .unsupportedHintTopGap,
                                  ),
                                  Text(
                                    l10n.settingsOffsetUnsupported,
                                    style:
                                        _SettingsSubtitlesLayout.captionStyle,
                                  ),
                                ],
                                const SizedBox(
                                  height: _SettingsSubtitlesLayout
                                      .syncSubtitleToAudioGap,
                                ),
                                Text(
                                  '${l10n.settingsAudioOffsetTitle}: ${_formatOffsetLabel(audioOffsetMs)}',
                                  style: _SettingsSubtitlesLayout.bodyStyle,
                                ),
                                Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleSliderKey(
                                        event,
                                        up: _subtitleOffsetPresetFocusNodes[selectedSubtitlePresetIndex],
                                        down:
                                            _audioOffsetPresetFocusNodes[selectedAudioPresetIndex],
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
                                    child: Slider(
                                      focusNode: _audioOffsetSliderFocusNode,
                                      value: audioOffsetMs.toDouble(),
                                      min: PlaybackSyncOffsets.minOffsetMs
                                          .toDouble(),
                                      max: PlaybackSyncOffsets.maxOffsetMs
                                          .toDouble(),
                                      divisions: 40,
                                      onChanged: audioOffsetSupported
                                          ? (value) {
                                              setState(
                                                () => _previewAudioOffsetMs =
                                                    value.round(),
                                              );
                                            }
                                          : null,
                                      onChangeEnd: audioOffsetSupported
                                          ? (value) async {
                                              final rounded = value.round();
                                              setState(
                                                () => _previewAudioOffsetMs =
                                                    null,
                                              );
                                              await syncController
                                                  .setAudioOffsetMs(
                                                    rounded,
                                                    source:
                                                        'settings_slider_audio',
                                                  );
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                                _OffsetPresetButtons(
                                  selectedOffsetMs: audioOffsetMs,
                                  focusNodes: _audioOffsetPresetFocusNodes,
                                  verticalAlignment: _focusVerticalAlignment,
                                  onKeyEvent: (index, event) =>
                                      FocusDirectionalNavigation.handleHorizontalGroupKey(
                                        event,
                                        index: index,
                                        nodes: _audioOffsetPresetFocusNodes,
                                        up: _audioOffsetSliderFocusNode,
                                        down: _resetOffsetsFocusNode,
                                      ),
                                  onPresetSelected: audioOffsetSupported
                                      ? (offsetMs) =>
                                            syncController.setAudioOffsetMs(
                                              offsetMs,
                                              source: 'settings_preset_audio',
                                            )
                                      : null,
                                ),
                                if (!audioOffsetSupported) ...[
                                  const SizedBox(
                                    height: _SettingsSubtitlesLayout
                                        .unsupportedHintTopGap,
                                  ),
                                  Text(
                                    l10n.settingsOffsetUnsupported,
                                    style:
                                        _SettingsSubtitlesLayout.captionStyle,
                                  ),
                                ],
                                const SizedBox(
                                  height: _SettingsSubtitlesLayout
                                      .syncResetButtonTopGap,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Focus(
                                    canRequestFocus: false,
                                    onKeyEvent: (_, event) =>
                                        FocusDirectionalNavigation.handleDirectionalKey(
                                          event,
                                          up: _audioOffsetPresetFocusNodes[selectedAudioPresetIndex],
                                          down: hasAdvancedSubtitleStyling
                                              ? _backgroundColorFocusNodes[selectedBackgroundColorIndex]
                                              : _premiumLockedActionFocusNode,
                                        ),
                                    child: MoviEnsureVisibleOnFocus(
                                      verticalAlignment:
                                          _focusVerticalAlignment,
                                      child: OutlinedButton(
                                        focusNode: _resetOffsetsFocusNode,
                                        onPressed: () async {
                                          setState(() {
                                            _previewSubtitleOffsetMs = null;
                                            _previewAudioOffsetMs = null;
                                          });
                                          await syncController.resetOffsets(
                                            source: 'settings_reset_button',
                                          );
                                        },
                                        child: Text(
                                          l10n.settingsSyncResetOffsets,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: _SettingsSubtitlesLayout.sectionGap),
                    FocusRegionScope(
                      regionId: AppFocusRegionId.settingsSubtitlesPremium,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () =>
                            hasAdvancedSubtitleStyling
                            ? _backgroundColorFocusNodes[selectedBackgroundColorIndex]
                            : _premiumLockedActionFocusNode,
                        resolveFallbackEntryNode: () =>
                            hasAdvancedSubtitleStyling
                            ? _resetDefaultsFocusNode
                            : _premiumLockedActionFocusNode,
                      ),
                      handleDirectionalExits: false,
                      debugLabel: 'SettingsSubtitlesPremiumRegion',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              _SettingsSubtitlesLayout.pageHorizontalPadding,
                        ),
                        child: PremiumFeatureGate(
                          feature: PremiumFeature.advancedSubtitleStyling,
                          unlockedBuilder: (_) => Column(
                            children: [
                              _SectionCard(
                                title: l10n.settingsSubtitlesBackgroundTitle,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing:
                                          _SettingsSubtitlesLayout.chipSpacing,
                                      runSpacing:
                                          _SettingsSubtitlesLayout.chipSpacing,
                                      children: SubtitleAppearancePrefs
                                          .subtitleBackgroundColorChoices
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final index = entry.key;
                                            final choice = entry.value;
                                            final selected =
                                                previewPrefs
                                                    .backgroundColorHex ==
                                                choice.hex;
                                            return MoviEnsureVisibleOnFocus(
                                              verticalAlignment:
                                                  _focusVerticalAlignment,
                                              child: Focus(
                                                canRequestFocus: false,
                                                onKeyEvent: (_, event) => FocusDirectionalNavigation.handleHorizontalGroupKey(
                                                  event,
                                                  index: index,
                                                  nodes:
                                                      _backgroundColorFocusNodes,
                                                  up: hideTvOnlySections
                                                      ? _textColorFocusNodes[selectedTextColorIndex]
                                                      : _resetOffsetsFocusNode,
                                                  // TV: pas de slider opacité du fond.
                                                  down: hideTvOnlySections
                                                      ? _shadowPresetFocusNodes.first
                                                      : _backgroundOpacitySliderFocusNode,
                                                ),
                                                child: MoviFocusableAction(
                                                  focusNode:
                                                      _backgroundColorFocusNodes[index],
                                                  onPressed: () => controller
                                                      .setBackgroundColorHex(
                                                        choice.hex,
                                                      ),
                                                  semanticLabel:
                                                      _backgroundColorSemanticLabel(
                                                        l10n,
                                                        choice,
                                                      ),
                                                  builder: (context, state) =>
                                                      _ColorCircle(
                                                        color: _hexToColor(
                                                          choice.hex,
                                                        ),
                                                        showNoBackgroundIndicator:
                                                            choice
                                                                .isTransparentBackground,
                                                        selected:
                                                            selected ||
                                                            state.focused,
                                                        accentColor:
                                                            accentColor,
                                                        size: _colorSwatchSize,
                                                      ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(growable: false),
                                    ),
                                    // TV: opacité du fond masquée (section Fond conservée).
                                    if (!hideTvOnlySections) ...[
                                      const SizedBox(
                                        height: _SettingsSubtitlesLayout
                                            .backgroundOpacityBlockTopGap,
                                      ),
                                      Text(
                                        '${l10n.settingsSubtitlesBackgroundOpacityLabel}: ${(previewPrefs.backgroundOpacity * 100).round()}%',
                                        style:
                                            _SettingsSubtitlesLayout.bodyStyle,
                                      ),
                                      Focus(
                                        canRequestFocus: false,
                                        onKeyEvent: (_, event) =>
                                            FocusDirectionalNavigation.handleSliderKey(
                                              event,
                                              up: _backgroundColorFocusNodes[selectedBackgroundColorIndex],
                                              down: _shadowPresetFocusNodes.first,
                                            ),
                                        child: MoviEnsureVisibleOnFocus(
                                          verticalAlignment:
                                              _focusVerticalAlignment,
                                          child: Slider(
                                            focusNode:
                                                _backgroundOpacitySliderFocusNode,
                                            value:
                                                previewPrefs.backgroundOpacity,
                                            min: 0,
                                            max: 1,
                                            divisions: 10,
                                            onChanged: (value) {
                                              setState(
                                                () =>
                                                    _previewBackgroundOpacity =
                                                        value,
                                              );
                                            },
                                            onChangeEnd: (value) async {
                                              setState(
                                                () =>
                                                    _previewBackgroundOpacity =
                                                        null,
                                              );
                                              await controller
                                                  .setBackgroundOpacity(value);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: _SettingsSubtitlesLayout.sectionGap,
                              ),
                              _SectionCard(
                                title: l10n.settingsSubtitlesShadowTitle,
                                child: Wrap(
                                  spacing:
                                      _SettingsSubtitlesLayout.chipSpacing,
                                  runSpacing:
                                      _SettingsSubtitlesLayout.chipSpacing,
                                  children: SubtitleShadowPreset.values
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final index = entry.key;
                                        final preset = entry.value;
                                        final selected =
                                            previewPrefs.shadowPreset ==
                                            preset;
                                        return MoviEnsureVisibleOnFocus(
                                          verticalAlignment:
                                              _focusVerticalAlignment,
                                          child: Focus(
                                            canRequestFocus: false,
                                            onKeyEvent: (_, event) =>
                                                FocusDirectionalNavigation.handleVerticalListKey(
                                                  event,
                                                  index: index,
                                                  nodes:
                                                      _shadowPresetFocusNodes,
                                                  up: hideTvOnlySections
                                                      ? _backgroundColorFocusNodes[selectedBackgroundColorIndex]
                                                      : _backgroundOpacitySliderFocusNode,
                                                  down: hideTvOnlySections
                                                      ? _resetDefaultsFocusNode
                                                      : _fineSizeSliderFocusNode,
                                                ),
                                            child: _SubtitlePresetBadge(
                                              label: _shadowLabel(
                                                l10n,
                                                preset,
                                              ),
                                              selected: selected,
                                              accentColor: accentColor,
                                              focusNode:
                                                  _shadowPresetFocusNodes[index],
                                              onPressed: () => controller
                                                  .setShadowPreset(preset),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              ),
                              // TV: section Taille fine masquée (PC + mobile uniquement).
                              if (!hideTvOnlySections) ...[
                                const SizedBox(
                                  height: _SettingsSubtitlesLayout.sectionGap,
                                ),
                                _SectionCard(
                                  title: l10n.settingsSubtitlesFineSizeTitle,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.settingsSubtitlesFineSizeValueLabel}: ${previewPrefs.fontScale.toStringAsFixed(2)}x',
                                        style:
                                            _SettingsSubtitlesLayout.bodyStyle,
                                      ),
                                      Focus(
                                        canRequestFocus: false,
                                        onKeyEvent: (_, event) =>
                                            FocusDirectionalNavigation.handleSliderKey(
                                              event,
                                              up: _shadowPresetFocusNodes[selectedShadowPresetIndex],
                                              down: _resetDefaultsFocusNode,
                                            ),
                                        child: MoviEnsureVisibleOnFocus(
                                          verticalAlignment:
                                              _focusVerticalAlignment,
                                          child: Slider(
                                            focusNode: _fineSizeSliderFocusNode,
                                            value: previewPrefs.fontScale,
                                            min: SubtitleAppearancePrefs
                                                .minFontScale,
                                            max: SubtitleAppearancePrefs
                                                .maxFontScale,
                                            divisions: 18,
                                            onChanged: (value) {
                                              setState(
                                                () => _previewFontScale = value,
                                              );
                                            },
                                            onChangeEnd: (value) async {
                                              setState(
                                                () => _previewFontScale = null,
                                              );
                                              await controller.setFontScale(
                                                value,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(
                                height: _SettingsSubtitlesLayout.sectionGap,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: hideTvOnlySections
                                            ? _shadowPresetFocusNodes[selectedShadowPresetIndex]
                                            : _fineSizeSliderFocusNode,
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
                                    child: MoviPrimaryButton(
                                      focusNode: _resetDefaultsFocusNode,
                                      label:
                                          l10n.settingsSubtitlesResetDefaults,
                                      onPressed: controller.resetToDefaults,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          lockedBuilder: (_) => _SectionCard(
                            title: l10n.settingsSubtitlesPremiumLockedTitle,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.settingsSubtitlesPremiumLockedBody,
                                  style: _SettingsSubtitlesLayout.bodyStyle,
                                ),
                                const SizedBox(
                                  height: _SettingsSubtitlesLayout
                                      .premiumLockedBodyToActionGap,
                                ),
                                Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: hideTvOnlySections
                                            ? _textColorFocusNodes[selectedTextColorIndex]
                                            : _resetOffsetsFocusNode,
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
                                    child: MoviPrimaryButton(
                                      focusNode: _premiumLockedActionFocusNode,
                                      label: l10n
                                          .settingsSubtitlesPremiumLockedAction,
                                      onPressed: () =>
                                          showPremiumFeatureLockedSheet(
                                            context,
                                            triggerFocusNode:
                                                _premiumLockedActionFocusNode,
                                            originRegionId: AppFocusRegionId
                                                .settingsSubtitlesPremium,
                                            fallbackRegionId: AppFocusRegionId
                                                .settingsSubtitlesPremium,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _sizeLabel(AppLocalizations l10n, SubtitleSizePreset preset) {
    switch (preset) {
      case SubtitleSizePreset.small:
        return l10n.settingsSubtitlesSizeSmall;
      case SubtitleSizePreset.medium:
        return l10n.settingsSubtitlesSizeMedium;
      case SubtitleSizePreset.large:
        return l10n.settingsSubtitlesSizeLarge;
    }
  }

  static String _shadowLabel(
    AppLocalizations l10n,
    SubtitleShadowPreset preset,
  ) {
    switch (preset) {
      case SubtitleShadowPreset.off:
        return l10n.settingsSubtitlesShadowOff;
      case SubtitleShadowPreset.soft:
        return l10n.settingsSubtitlesShadowSoft;
      case SubtitleShadowPreset.strong:
        return l10n.settingsSubtitlesShadowStrong;
    }
  }

  static String _formatOffsetLabel(int offsetMs) {
    if (offsetMs == 0) return '0 ms';
    final sign = offsetMs > 0 ? '+' : '';
    return '$sign$offsetMs ms';
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? Colors.white : Color(value);
  }
}

class _OffsetPresetButtons extends StatelessWidget {
  const _OffsetPresetButtons({
    required this.selectedOffsetMs,
    required this.onPresetSelected,
    this.focusNodes,
    this.verticalAlignment = 0.22,
    this.onKeyEvent,
  });

  final int selectedOffsetMs;
  final Future<void> Function(int offsetMs)? onPresetSelected;
  final List<FocusNode>? focusNodes;
  final double verticalAlignment;
  final KeyEventResult Function(int index, KeyEvent event)? onKeyEvent;

  static const List<int> presets = <int>[-500, -250, 0, 250, 500];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _SettingsSubtitlesLayout.offsetPresetChipSpacing,
      runSpacing: _SettingsSubtitlesLayout.offsetPresetChipSpacing,
      children: presets
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final offsetMs = entry.value;
            final selected = selectedOffsetMs == offsetMs;
            return MoviEnsureVisibleOnFocus(
              verticalAlignment: verticalAlignment,
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: onKeyEvent == null
                    ? null
                    : (_, event) => onKeyEvent!(index, event),
                child: ChoiceChip(
                  focusNode: focusNodes != null && index < focusNodes!.length
                      ? focusNodes![index]
                      : null,
                  label: Text(_label(offsetMs)),
                  selected: selected,
                  onSelected: onPresetSelected == null
                      ? null
                      : (_) => onPresetSelected!(offsetMs),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  static String _label(int value) {
    if (value == 0) return '0';
    final sign = value > 0 ? '+' : '';
    return '$sign$value';
  }
}

String _backgroundColorSemanticLabel(
  AppLocalizations l10n,
  SubtitleColorChoice choice,
) {
  if (choice.isTransparentBackground) {
    return l10n.settingsSubtitlesBackgroundNone;
  }
  return choice.hex;
}

/// Badge de preset (taille, ombre) avec fond accent atténué au focus.
class _SubtitlePresetBadge extends StatelessWidget {
  const _SubtitlePresetBadge({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onPressed,
    this.focusNode,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: label,
      toggled: selected,
      builder: (context, state) {
        final backgroundColor = selected
            ? accentColor.withValues(
                alpha: _SettingsSubtitlesLayout.chipSelectedBackgroundAlpha,
              )
            : state.focused
            ? accentColor.withValues(
                alpha: _SettingsSubtitlesLayout.chipFocusBackgroundAlpha,
              )
            : state.hovered
            ? accentColor.withValues(
                alpha: _SettingsSubtitlesLayout.chipHoverBackgroundAlpha,
              )
            : null;

        return MoviFocusFrame(
          borderRadius: BorderRadius.circular(
            _SettingsSubtitlesLayout.chipBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _SettingsSubtitlesLayout.chipPaddingH,
            vertical: _SettingsSubtitlesLayout.chipPaddingV,
          ),
          backgroundColor: backgroundColor,
          borderColor: selected ? accentColor : Colors.white24,
          borderWidth: 1,
          child: Text(
            label,
            style: _SettingsSubtitlesLayout.chipLabelStyle(
              selected: selected,
            ),
          ),
        );
      },
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.selected,
    required this.accentColor,
    required this.size,
    this.showNoBackgroundIndicator = false,
  });

  final Color color;
  final bool selected;
  final Color accentColor;
  final double size;
  final bool showNoBackgroundIndicator;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: showNoBackgroundIndicator ? const Color(0xFF2C2C2E) : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accentColor : Colors.white24,
          width: selected ? 3 : 1,
        ),
      ),
      child: showNoBackgroundIndicator
          ? Icon(
              Icons.close,
              size: size * 0.48,
              color: Colors.white.withValues(alpha: 0.72),
            )
          : null,
    );
  }
}

/// Espacements et typographie de la page Réglages → Sous-titres.
abstract final class _SettingsSubtitlesLayout {
  static const double pageHorizontalPadding = 20;
  static const double scrollBottomPadding = 32;

  /// Sous l'en-tête de page (retour + titre 24 px).
  static const double headerToContentGap = 8;

  /// Entre deux cartes de section ([_SectionCard]).
  static const double sectionGap = 16;

  static const double sectionCardPadding = 16;
  static const double sectionCardRadius = 16;

  /// Titre de section → contenu (badges, sliders, etc.).
  static const double sectionTitleToContentGap = 12;

  static const double chipSpacing = 12;
  static const double chipBorderRadius = 8;
  static const double chipPaddingH = 12;
  static const double chipPaddingV = 8;
  static const double chipSelectedBackgroundAlpha = 0.25;
  static const double chipFocusBackgroundAlpha = 0.18;
  static const double chipHoverBackgroundAlpha = 0.12;
  static const double offsetPresetChipSpacing = 8;

  static const double syncSubtitleToAudioGap = 14;
  static const double syncResetButtonTopGap = 12;
  static const double unsupportedHintTopGap = 6;
  static const double backgroundOpacityBlockTopGap = 14;
  static const double premiumLockedBodyToActionGap = 12;

  /// Titre de page : voir [MoviSubpageBackTitleHeader] (24 px, semibold).
  static const double sectionTitleFontSize = 16;
  static const double bodyFontSize = 14;
  static const double captionFontSize = 12;

  static const TextStyle sectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: sectionTitleFontSize,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: Colors.white70,
    fontSize: bodyFontSize,
  );

  static const TextStyle captionStyle = TextStyle(
    color: Colors.white54,
    fontSize: captionFontSize,
  );

  static TextStyle chipLabelStyle({required bool selected}) => TextStyle(
    color: selected ? Colors.white : Colors.white70,
    fontSize: bodyFontSize,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            _SettingsSubtitlesLayout.sectionCardRadius,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            _SettingsSubtitlesLayout.sectionCardPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _SettingsSubtitlesLayout.sectionTitleStyle),
              const SizedBox(
                height: _SettingsSubtitlesLayout.sectionTitleToContentGap,
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
