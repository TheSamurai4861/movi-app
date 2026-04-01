import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';
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
  double? _previewBackgroundOpacity;
  double? _previewFontScale;
  int? _previewSubtitleOffsetMs;
  int? _previewAudioOffsetMs;

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
    final subtitleOffsetMs =
        _previewSubtitleOffsetMs ?? syncOffsets.subtitleOffsetMs;
    final audioOffsetMs = _previewAudioOffsetMs ?? syncOffsets.audioOffsetMs;
    final previewPrefs = prefs.copyWith(
      backgroundOpacity: _previewBackgroundOpacity ?? prefs.backgroundOpacity,
      fontScale: _previewFontScale ?? prefs.fontScale,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              MoviSubpageBackTitleHeader(
                title: l10n.settingsSubtitlesTitle,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionCard(
                  title: l10n.settingsSubtitlesSizeTitle,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: SubtitleSizePreset.values
                        .map((preset) {
                          final selected = prefs.sizePreset == preset;
                          return ChoiceChip(
                            label: Text(_sizeLabel(l10n, preset)),
                            selected: selected,
                            onSelected: (_) => controller.setSizePreset(preset),
                            selectedColor: accentColor.withValues(alpha: 0.25),
                            side: BorderSide(
                              color: selected ? accentColor : Colors.white24,
                            ),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
                  title: l10n.settingsSyncSectionTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.settingsSubtitleOffsetTitle}: ${_formatOffsetLabel(subtitleOffsetMs)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Slider(
                        value: subtitleOffsetMs.toDouble(),
                        min: PlaybackSyncOffsets.minOffsetMs.toDouble(),
                        max: PlaybackSyncOffsets.maxOffsetMs.toDouble(),
                        divisions: 40,
                        onChanged: subtitleOffsetSupported
                            ? (value) {
                                setState(
                                  () =>
                                      _previewSubtitleOffsetMs = value.round(),
                                );
                              }
                            : null,
                        onChangeEnd: subtitleOffsetSupported
                            ? (value) async {
                                final rounded = value.round();
                                setState(() => _previewSubtitleOffsetMs = null);
                                await syncController.setSubtitleOffsetMs(
                                  rounded,
                                  source: 'settings_slider_subtitle',
                                );
                              }
                            : null,
                      ),
                      _OffsetPresetButtons(
                        selectedOffsetMs: subtitleOffsetMs,
                        onPresetSelected: subtitleOffsetSupported
                            ? (offsetMs) => syncController.setSubtitleOffsetMs(
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
                      Slider(
                        value: audioOffsetMs.toDouble(),
                        min: PlaybackSyncOffsets.minOffsetMs.toDouble(),
                        max: PlaybackSyncOffsets.maxOffsetMs.toDouble(),
                        divisions: 40,
                        onChanged: audioOffsetSupported
                            ? (value) {
                                setState(
                                  () => _previewAudioOffsetMs = value.round(),
                                );
                              }
                            : null,
                        onChangeEnd: audioOffsetSupported
                            ? (value) async {
                                final rounded = value.round();
                                setState(() => _previewAudioOffsetMs = null);
                                await syncController.setAudioOffsetMs(
                                  rounded,
                                  source: 'settings_slider_audio',
                                );
                              }
                            : null,
                      ),
                      _OffsetPresetButtons(
                        selectedOffsetMs: audioOffsetMs,
                        onPresetSelected: audioOffsetSupported
                            ? (offsetMs) => syncController.setAudioOffsetMs(
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
                        child: OutlinedButton(
                          onPressed: () async {
                            setState(() {
                              _previewSubtitleOffsetMs = null;
                              _previewAudioOffsetMs = null;
                            });
                            await syncController.resetOffsets(
                              source: 'settings_reset_button',
                            );
                          },
                          child: Text(l10n.settingsSyncResetOffsets),
                        ),
                      ),
                    ],
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
                    children: SubtitleAppearancePrefs.subtitleColorChoices
                        .map((choice) {
                          final selected = prefs.textColorHex == choice.hex;
                          final color = _hexToColor(choice.hex);
                          return GestureDetector(
                            onTap: () => controller.setTextColorHex(choice.hex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? accentColor
                                      : Colors.white24,
                                  width: selected ? 3 : 1,
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
                    children: SubtitleAppearancePrefs.subtitleFontChoices
                        .map((choice) {
                          final selected = prefs.fontFamilyKey == choice.key;
                          return ListTile(
                            onTap: () =>
                                controller.setFontFamilyKey(choice.key),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _fontLabel(l10n, choice.key),
                              style: TextStyle(
                                fontFamily: choice.fontFamily,
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            trailing: selected
                                ? Icon(Icons.check, color: accentColor)
                                : null,
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PremiumFeatureGate(
                  feature: PremiumFeature.advancedSubtitleStyling,
                  unlockedBuilder: (_) => Column(
                    children: [
                      _SectionCard(
                        title: l10n.settingsSubtitlesPreviewTitle,
                        child: _SubtitlePreview(prefs: previewPrefs),
                      ),
                      const SizedBox(height: 16),
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
                                  .map((choice) {
                                    final selected =
                                        previewPrefs.backgroundColorHex ==
                                        choice.hex;
                                    return GestureDetector(
                                      onTap: () => controller
                                          .setBackgroundColorHex(choice.hex),
                                      child: _ColorCircle(
                                        color: _hexToColor(choice.hex),
                                        selected: selected,
                                        accentColor: accentColor,
                                        size: 26,
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${l10n.settingsSubtitlesBackgroundOpacityLabel}: ${(previewPrefs.backgroundOpacity * 100).round()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: previewPrefs.backgroundOpacity,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              onChanged: (value) {
                                setState(
                                  () => _previewBackgroundOpacity = value,
                                );
                              },
                              onChangeEnd: (value) async {
                                setState(
                                  () => _previewBackgroundOpacity = null,
                                );
                                await controller.setBackgroundOpacity(value);
                              },
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
                              .map((preset) {
                                final selected =
                                    previewPrefs.shadowPreset == preset;
                                return ChoiceChip(
                                  label: Text(_shadowLabel(l10n, preset)),
                                  selected: selected,
                                  onSelected: (_) =>
                                      controller.setShadowPreset(preset),
                                  selectedColor: accentColor.withValues(
                                    alpha: 0.25,
                                  ),
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
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: previewPrefs.fontScale,
                              min: SubtitleAppearancePrefs.minFontScale,
                              max: SubtitleAppearancePrefs.maxFontScale,
                              divisions: 18,
                              onChanged: (value) {
                                setState(() => _previewFontScale = value);
                              },
                              onChangeEnd: (value) async {
                                setState(() => _previewFontScale = null);
                                await controller.setFontScale(value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: controller.resetToDefaults,
                          child: Text(l10n.settingsSubtitlesResetDefaults),
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
                        MoviPrimaryButton(
                          label: l10n.settingsSubtitlesPremiumLockedAction,
                          onPressed: () =>
                              showPremiumFeatureLockedSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
  });

  final int selectedOffsetMs;
  final Future<void> Function(int offsetMs)? onPresetSelected;

  static const List<int> _presets = <int>[-500, -250, 0, 250, 500];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets
          .map((offsetMs) {
            final selected = selectedOffsetMs == offsetMs;
            return ChoiceChip(
              label: Text(_label(offsetMs)),
              selected: selected,
              onSelected: onPresetSelected == null
                  ? null
                  : (_) => onPresetSelected!(offsetMs),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          l10n.settingsSubtitlesPreviewSample,
          textAlign: TextAlign.center,
          style: prefs.toTextStyle(),
        ),
      ),
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
