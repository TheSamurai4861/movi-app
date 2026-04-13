import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';
import 'package:movi/src/core/playback/media_kit_subtitle_text_scale.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/widgets/subtitle_playback_layout.dart';
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
  final List<FocusNode> _fontFocusNodes = List<FocusNode>.generate(
    SubtitleAppearancePrefs.subtitleFontChoices.length,
    (index) => FocusNode(debugLabel: 'SettingsSubtitlesFont$index'),
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
    for (final node in _fontFocusNodes) {
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

  int _selectedFontIndex(SubtitleAppearancePrefs prefs) {
    final index = SubtitleAppearancePrefs.subtitleFontChoices.indexWhere(
      (choice) => choice.key == prefs.fontFamilyKey,
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final selectedFontIndex = _selectedFontIndex(prefs);
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
                padding: const EdgeInsets.only(bottom: 32),
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
                    const SizedBox(height: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesPreviewTitle,
                              child: _SubtitlePreview(prefs: previewPrefs),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesSizeTitle,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
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
                                              FocusDirectionalNavigation.handleHorizontalGroupKey(
                                                event,
                                                index: index,
                                                nodes: _sizePresetFocusNodes,
                                                up: _backFocusNode,
                                                down:
                                                    _textColorFocusNodes[selectedTextColorIndex],
                                              ),
                                          child: ChoiceChip(
                                            focusNode:
                                                _sizePresetFocusNodes[index],
                                            label: Text(
                                              _sizeLabel(l10n, preset),
                                            ),
                                            selected: selected,
                                            onSelected: (_) => controller
                                                .setSizePreset(preset),
                                            selectedColor: accentColor
                                                .withValues(alpha: 0.25),
                                            side: BorderSide(
                                              color: selected
                                                  ? accentColor
                                                  : Colors.white24,
                                            ),
                                            labelStyle: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesColorTitle,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
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
                                                up:
                                                    _sizePresetFocusNodes[selectedSizePresetIndex],
                                                down: _fontFocusNodes.first,
                                              ),
                                          child: MoviFocusableAction(
                                            focusNode:
                                                _textColorFocusNodes[index],
                                            onPressed: () => controller
                                                .setTextColorHex(choice.hex),
                                            semanticLabel: choice.hex,
                                            builder: (context, state) =>
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 160,
                                                  ),
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          selected ||
                                                              state.focused
                                                          ? accentColor
                                                          : Colors.white24,
                                                      width:
                                                          selected ||
                                                              state.focused
                                                          ? 3
                                                          : 1,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SectionCard(
                              title: l10n.settingsSubtitlesFontTitle,
                              child: Column(
                                children: SubtitleAppearancePrefs
                                    .subtitleFontChoices
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final choice = entry.value;
                                      final selected =
                                          prefs.fontFamilyKey == choice.key;
                                      return MoviEnsureVisibleOnFocus(
                                        verticalAlignment:
                                            _focusVerticalAlignment,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleVerticalListKey(
                                                event,
                                                index: index,
                                                nodes: _fontFocusNodes,
                                                up:
                                                    _textColorFocusNodes[selectedTextColorIndex],
                                                down:
                                                    _subtitleOffsetSliderFocusNode,
                                              ),
                                          child: MoviFocusableAction(
                                            focusNode: _fontFocusNodes[index],
                                            onPressed: () => controller
                                                .setFontFamilyKey(choice.key),
                                            semanticLabel: _fontLabel(
                                              l10n,
                                              choice.key,
                                            ),
                                            builder: (context, state) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: MoviFocusFrame(
                                                scale: state.focused ? 1.01 : 1,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                backgroundColor: state.focused
                                                    ? accentColor.withValues(
                                                        alpha: 0.18,
                                                      )
                                                    : Colors.transparent,
                                                borderColor: state.focused
                                                    ? accentColor
                                                    : Colors.transparent,
                                                borderWidth: 1.5,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _fontLabel(
                                                          l10n,
                                                          choice.key,
                                                        ),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              choice.fontFamily,
                                                          color: selected
                                                              ? Colors.white
                                                              : Colors.white70,
                                                          fontWeight: selected
                                                              ? FontWeight.w700
                                                              : FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                    if (selected)
                                                      Icon(
                                                        Icons.check,
                                                        color: accentColor,
                                                      ),
                                                  ],
                                                ),
                                              ),
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
                    const SizedBox(height: 16),
                    FocusRegionScope(
                      regionId: AppFocusRegionId.settingsSubtitlesOffsets,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () =>
                            _subtitleOffsetSliderFocusNode,
                        resolveFallbackEntryNode: () => _resetOffsetsFocusNode,
                      ),
                      handleDirectionalExits: false,
                      debugLabel: 'SettingsSubtitlesOffsetsRegion',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionCard(
                          title: l10n.settingsSyncSectionTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.settingsSubtitleOffsetTitle}: ${_formatOffsetLabel(subtitleOffsetMs)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) => FocusDirectionalNavigation.handleSliderKey(
                                  event,
                                  up: _fontFocusNodes[selectedFontIndex],
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
                                            source: 'settings_preset_subtitle',
                                          )
                                    : null,
                              ),
                              if (!subtitleOffsetSupported) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.settingsOffsetUnsupported,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                '${l10n.settingsAudioOffsetTitle}: ${_formatOffsetLabel(audioOffsetMs)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) => FocusDirectionalNavigation.handleSliderKey(
                                  event,
                                  up:
                                      _subtitleOffsetPresetFocusNodes[selectedSubtitlePresetIndex],
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
                                              () =>
                                                  _previewAudioOffsetMs = null,
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
                                const SizedBox(height: 6),
                                Text(
                                  l10n.settingsOffsetUnsupported,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up:
                                            _audioOffsetPresetFocusNodes[selectedAudioPresetIndex],
                                        down: hasAdvancedSubtitleStyling
                                            ? _backgroundColorFocusNodes[selectedBackgroundColorIndex]
                                            : _premiumLockedActionFocusNode,
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
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
                    const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                      spacing: 10,
                                      runSpacing: 10,
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
                                                onKeyEvent: (_, event) =>
                                                    FocusDirectionalNavigation.handleHorizontalGroupKey(
                                                      event,
                                                      index: index,
                                                      nodes:
                                                          _backgroundColorFocusNodes,
                                                      up:
                                                          _resetOffsetsFocusNode,
                                                      down:
                                                          _backgroundOpacitySliderFocusNode,
                                                    ),
                                                child: MoviFocusableAction(
                                                  focusNode:
                                                      _backgroundColorFocusNodes[index],
                                                  onPressed: () => controller
                                                      .setBackgroundColorHex(
                                                        choice.hex,
                                                      ),
                                                  semanticLabel: choice.hex,
                                                  builder: (context, state) =>
                                                      _ColorCircle(
                                                        color: _hexToColor(
                                                          choice.hex,
                                                        ),
                                                        selected:
                                                            selected ||
                                                            state.focused,
                                                        accentColor:
                                                            accentColor,
                                                        size: 26,
                                                      ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(growable: false),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '${l10n.settingsSubtitlesBackgroundOpacityLabel}: ${(previewPrefs.backgroundOpacity * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Focus(
                                      canRequestFocus: false,
                                      onKeyEvent: (_, event) => FocusDirectionalNavigation.handleSliderKey(
                                        event,
                                        up:
                                            _backgroundColorFocusNodes[selectedBackgroundColorIndex],
                                        down:
                                            _shadowPresetFocusNodes[selectedShadowPresetIndex],
                                      ),
                                      child: MoviEnsureVisibleOnFocus(
                                        verticalAlignment:
                                            _focusVerticalAlignment,
                                        child: Slider(
                                          focusNode:
                                              _backgroundOpacitySliderFocusNode,
                                          value: previewPrefs.backgroundOpacity,
                                          min: 0,
                                          max: 1,
                                          divisions: 10,
                                          onChanged: (value) {
                                            setState(
                                              () => _previewBackgroundOpacity =
                                                  value,
                                            );
                                          },
                                          onChangeEnd: (value) async {
                                            setState(
                                              () => _previewBackgroundOpacity =
                                                  null,
                                            );
                                            await controller
                                                .setBackgroundOpacity(value);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SectionCard(
                                title: l10n.settingsSubtitlesShadowTitle,
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: SubtitleShadowPreset.values
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final index = entry.key;
                                        final preset = entry.value;
                                        final selected =
                                            previewPrefs.shadowPreset == preset;
                                        return MoviEnsureVisibleOnFocus(
                                          verticalAlignment:
                                              _focusVerticalAlignment,
                                          child: Focus(
                                            canRequestFocus: false,
                                            onKeyEvent: (_, event) =>
                                                FocusDirectionalNavigation.handleHorizontalGroupKey(
                                                  event,
                                                  index: index,
                                                  nodes:
                                                      _shadowPresetFocusNodes,
                                                  up:
                                                      _backgroundOpacitySliderFocusNode,
                                                  down:
                                                      _fineSizeSliderFocusNode,
                                                ),
                                            child: ChoiceChip(
                                              focusNode:
                                                  _shadowPresetFocusNodes[index],
                                              label: Text(
                                                _shadowLabel(l10n, preset),
                                              ),
                                              selected: selected,
                                              onSelected: (_) => controller
                                                  .setShadowPreset(preset),
                                              selectedColor: accentColor
                                                  .withValues(alpha: 0.25),
                                              side: BorderSide(
                                                color: selected
                                                    ? accentColor
                                                    : Colors.white24,
                                              ),
                                              labelStyle: TextStyle(
                                                color: selected
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SectionCard(
                                title: l10n.settingsSubtitlesFineSizeTitle,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l10n.settingsSubtitlesFineSizeValueLabel}: ${previewPrefs.fontScale.toStringAsFixed(2)}x',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Focus(
                                      canRequestFocus: false,
                                      onKeyEvent: (_, event) => FocusDirectionalNavigation.handleSliderKey(
                                        event,
                                        up:
                                            _shadowPresetFocusNodes[selectedShadowPresetIndex],
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _fineSizeSliderFocusNode,
                                      ),
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment: _focusVerticalAlignment,
                                    child: OutlinedButton(
                                      focusNode: _resetDefaultsFocusNode,
                                      onPressed: controller.resetToDefaults,
                                      child: Text(
                                        l10n.settingsSubtitlesResetDefaults,
                                      ),
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
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _resetOffsetsFocusNode,
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
                                            originRegionId:
                                                AppFocusRegionId
                                                    .settingsSubtitlesPremium,
                                            fallbackRegionId:
                                                AppFocusRegionId
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

  static String _fontLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'roboto':
        return 'Roboto';
      case 'arial':
        return 'Arial';
      case 'system':
      default:
        return l10n.settingsSubtitlesFontSystem;
    }
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
      spacing: 8,
      runSpacing: 8,
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

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.selected,
    required this.accentColor,
    required this.size,
  });

  final Color color;
  final bool selected;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accentColor : Colors.white24,
          width: selected ? 3 : 1,
        ),
      ),
    );
  }
}

class _SubtitlePreview extends StatelessWidget {
  const _SubtitlePreview({required this.prefs});

  final SubtitleAppearancePrefs prefs;

  /// Padding du `Container` autour du cadre 16:9 (les tests reproduisent ce retrait).
  static const double _outerPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 320.0;
        final innerWidth = (parentWidth - 2 * _outerPadding).clamp(
          0.0,
          double.infinity,
        );
        final innerHeight = innerWidth * 9 / 16;
        final mediaKitScale = MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: innerWidth,
          layoutHeight: innerHeight,
        );
        final bottomPad = SubtitlePlaybackLayout.bottomPadding(
          context,
          showPlayerControls: true,
          includeDisplaySafeBottom: false,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_outerPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: bottomPad,
                      child: Text(
                        l10n.settingsSubtitlesPreviewSample,
                        textAlign: TextAlign.center,
                        style: prefs.toTextStyle(),
                        textScaler: TextScaler.linear(mediaKitScale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
