import 'package:flutter/material.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';

class _TrackSelectionSheetLayout {
  const _TrackSelectionSheetLayout({
    required this.maxSheetHeight,
    required this.maxListHeight,
  });

  final double maxSheetHeight;
  final double maxListHeight;

  static _TrackSelectionSheetLayout fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isMobile = size.shortestSide < 600;
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;
    final availableHeight = size.height - safeTop - safeBottom;

    // Keep a bounded sheet height to prevent vertical overflow on small screens.
    final maxSheetHeight = isMobile ? availableHeight * 0.82 : availableHeight;

    // Desktop: cap list height to ~4 visible items, then scroll.
    const tileHeight = 56.0; // Typical ListTile height (1 line).
    final maxListHeight = isMobile ? double.infinity : tileHeight * 4;

    return _TrackSelectionSheetLayout(
      maxSheetHeight: maxSheetHeight,
      maxListHeight: maxListHeight,
    );
  }
}

class _TrackSelectionSheetScaffold extends StatelessWidget {
  const _TrackSelectionSheetScaffold({required this.title, required this.list});

  final String title;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    final layout = _TrackSelectionSheetLayout.fromContext(context);
    final listSection = layout.maxListHeight.isFinite
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: layout.maxListHeight),
              child: list,
            ),
          )
        : list;

    return SizedBox(
      height: layout.maxSheetHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 1),
              Expanded(child: listSection),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu de sélection des pistes de sous-titres
class SubtitleTrackSelectionMenu extends StatelessWidget {
  const SubtitleTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.onDisable,
    required this.initialSubtitleAppearance,
    required this.subtitleAppearanceStream,
    required this.onSubtitleSizeChanged,
    required this.onSubtitleColorChanged,
    required this.onOpenSubtitleSettings,
    required this.supportsSubtitleOffset,
    required this.subtitleOffsetMs,
    required this.onSubtitleOffsetPresetSelected,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final Future<void> Function() onDisable;
  final SubtitleAppearancePrefs initialSubtitleAppearance;
  final Stream<SubtitleAppearancePrefs> subtitleAppearanceStream;
  final Future<void> Function(SubtitleSizePreset preset) onSubtitleSizeChanged;
  final Future<void> Function(String hexColor) onSubtitleColorChanged;
  final VoidCallback onOpenSubtitleSettings;
  final bool supportsSubtitleOffset;
  final int subtitleOffsetMs;
  final Future<void> Function(int offsetMs) onSubtitleOffsetPresetSelected;

  @override
  Widget build(BuildContext context) {
    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.subtitlesMenuTitle,
      list: Column(
        children: [
          StreamBuilder<SubtitleAppearancePrefs>(
            stream: subtitleAppearanceStream,
            initialData: initialSubtitleAppearance,
            builder: (context, snapshot) {
              final appearance =
                  snapshot.data ?? SubtitleAppearancePrefs.defaults;
              return _SubtitleQuickSettingsBar(
                subtitleAppearance: appearance,
                onSubtitleSizeChanged: onSubtitleSizeChanged,
                onSubtitleColorChanged: onSubtitleColorChanged,
                onOpenSubtitleSettings: onOpenSubtitleSettings,
                supportsSubtitleOffset: supportsSubtitleOffset,
                subtitleOffsetMs: subtitleOffsetMs,
                onSubtitleOffsetPresetSelected: onSubtitleOffsetPresetSelected,
              );
            },
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isDisabled = currentTrack == null;
                  return ListTile(
                    leading: Icon(
                      isDisabled
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isDisabled ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.actionDisable,
                      style: TextStyle(
                        color: isDisabled ? Colors.white : Colors.white70,
                        fontWeight: isDisabled
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isDisabled,
                    selectedTileColor: const Color(0xFF2A2A2A),
                    onTap: () async {
                      await onDisable();
                      if (!context.mounted) return;
                      Navigator.of(context).pop(null);
                    },
                  );
                }

                final track = tracks[index - 1];
                final isSelected = currentTrack?.id == track.id;
                final label = TrackLabelFormatter.formatTrackLabel(track);
                final trackTitle = label.isNotEmpty
                    ? label
                    : AppLocalizations.of(
                        context,
                      )!.defaultTrackLabel(track.id.toString());

                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    trackTitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: track.title != null && track.title!.isNotEmpty
                      ? Text(
                          track.title!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF2A2A2A),
                  onTap: () async {
                    await onTrackSelected(track);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(track);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleQuickSettingsBar extends StatelessWidget {
  const _SubtitleQuickSettingsBar({
    required this.subtitleAppearance,
    required this.onSubtitleSizeChanged,
    required this.onSubtitleColorChanged,
    required this.onOpenSubtitleSettings,
    required this.supportsSubtitleOffset,
    required this.subtitleOffsetMs,
    required this.onSubtitleOffsetPresetSelected,
  });

  final SubtitleAppearancePrefs subtitleAppearance;
  final Future<void> Function(SubtitleSizePreset preset) onSubtitleSizeChanged;
  final Future<void> Function(String hexColor) onSubtitleColorChanged;
  final VoidCallback onOpenSubtitleSettings;
  final bool supportsSubtitleOffset;
  final int subtitleOffsetMs;
  final Future<void> Function(int offsetMs) onSubtitleOffsetPresetSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.settingsSubtitlesQuickSettingsTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onOpenSubtitleSettings,
                icon: const MoviAssetIcon(
                  AppAssets.iconSettings,
                  color: Colors.white,
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final preset in SubtitleSizePreset.values) ...[
                _QuickToggleChip(
                  label: _sizeLabel(l10n, preset),
                  selected: subtitleAppearance.sizePreset == preset,
                  onTap: () => onSubtitleSizeChanged(preset),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: SubtitleAppearancePrefs.subtitleColorChoices
                .map((choice) {
                  final isSelected =
                      subtitleAppearance.textColorHex == choice.hex;
                  final color = _hexToColor(choice.hex);
                  return GestureDetector(
                    onTap: () => onSubtitleColorChanged(choice.hex),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white30,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _OffsetPresetRow(
            title: l10n.settingsSubtitleOffsetTitle,
            currentOffsetMs: subtitleOffsetMs,
            supportsOffset: supportsSubtitleOffset,
            unsupportedLabel: l10n.settingsOffsetUnsupported,
            onPresetSelected: onSubtitleOffsetPresetSelected,
          ),
        ],
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

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? Colors.white : Color(value);
  }
}

class _QuickToggleChip extends StatelessWidget {
  const _QuickToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Menu de sélection des pistes audio
class AudioTrackSelectionMenu extends StatelessWidget {
  const AudioTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.supportsAudioOffset,
    required this.audioOffsetMs,
    required this.onAudioOffsetPresetSelected,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final bool supportsAudioOffset;
  final int audioOffsetMs;
  final Future<void> Function(int offsetMs) onAudioOffsetPresetSelected;

  @override
  Widget build(BuildContext context) {
    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.audioMenuTitle,
      list: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _OffsetPresetRow(
              title: AppLocalizations.of(context)!.settingsAudioOffsetTitle,
              currentOffsetMs: audioOffsetMs,
              supportsOffset: supportsAudioOffset,
              unsupportedLabel: AppLocalizations.of(
                context,
              )!.settingsOffsetUnsupported,
              onPresetSelected: onAudioOffsetPresetSelected,
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isSelected = currentTrack?.id == track.id;
                final label = TrackLabelFormatter.formatTrackLabel(track);
                final trackTitle = label.isNotEmpty
                    ? label
                    : AppLocalizations.of(
                        context,
                      )!.defaultTrackLabel(track.id.toString());

                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    trackTitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: track.title != null && track.title!.isNotEmpty
                      ? Text(
                          track.title!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF2A2A2A),
                  onTap: () async {
                    await onTrackSelected(track);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(track);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OffsetPresetRow extends StatelessWidget {
  const _OffsetPresetRow({
    required this.title,
    required this.currentOffsetMs,
    required this.supportsOffset,
    required this.unsupportedLabel,
    required this.onPresetSelected,
  });

  final String title;
  final int currentOffsetMs;
  final bool supportsOffset;
  final String unsupportedLabel;
  final Future<void> Function(int offsetMs) onPresetSelected;

  static const List<int> _presets = <int>[-500, -250, 0, 250, 500];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        if (!supportsOffset)
          Text(
            unsupportedLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map((value) {
                  final selected = currentOffsetMs == value;
                  return _QuickToggleChip(
                    label: _labelFor(value),
                    selected: selected,
                    onTap: () => onPresetSelected(value),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }

  static String _labelFor(int value) {
    if (value == 0) return '0';
    final sign = value > 0 ? '+' : '';
    return '$sign$value';
  }
}
