import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_source_organize_providers.dart';

class IptvSourceOrganizePage extends ConsumerStatefulWidget {
  const IptvSourceOrganizePage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<IptvSourceOrganizePage> createState() =>
      _IptvSourceOrganizePageState();
}

class _IptvSourceOrganizePageState extends ConsumerState<IptvSourceOrganizePage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvSourceOrganizeControllerProvider(widget.accountId));
    final controller = ref.read(
      iptvSourceOrganizeControllerProvider(widget.accountId).notifier,
    );
    final accent = ref.watch(asp.currentAccentColorProvider);

    final items = state.items;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _Header(onBack: () => context.pop()),
                  const SizedBox(height: 32),
                  if (state.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.error != null)
                    Expanded(
                      child: Center(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 140),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) =>
                            controller.reorder(
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final typeLabel = item.type == XtreamPlaylistType.movies
                              ? 'Films'
                              : 'Séries';
                          return _PlaylistRow(
                            key: ValueKey(item.playlistId),
                            title: '${item.title} ($typeLabel)',
                            isVisible: item.isVisible,
                            accentColor: accent,
                            onVisibleChanged: (v) =>
                                controller.toggleVisibility(
                              playlistId: item.playlistId,
                              isVisible: v,
                            ),
                            dragHandle: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_handle,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomActions(
                  onShowAll: () => controller.setAllVisibleAll(isVisible: true),
                  onHideAll: () => controller.setAllVisibleAll(isVisible: false),
                  showAllLabel: 'Tout afficher',
                  hideAllLabel: 'Tout masquer',
                  disabled: state.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 35,
                height: 35,
                child: Image(image: AssetImage(AppAssets.iconBack)),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Organiser',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    super.key,
    required this.title,
    required this.isVisible,
    required this.accentColor,
    required this.onVisibleChanged,
    required this.dragHandle,
  });

  final String title;
  final bool isVisible;
  final Color accentColor;
  final ValueChanged<bool> onVisibleChanged;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch.adaptive(
                  value: isVisible,
                  activeThumbColor: accentColor,
                  onChanged: onVisibleChanged,
                ),
                const SizedBox(width: 16),
                dragHandle,
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: const Color(0xFF262626)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onShowAll,
    required this.onHideAll,
    required this.showAllLabel,
    required this.hideAllLabel,
    required this.disabled,
  });

  final VoidCallback onShowAll;
  final VoidCallback onHideAll;
  final String showAllLabel;
  final String hideAllLabel;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: MoviPrimaryButton(
                label: showAllLabel,
                onPressed: disabled ? null : onShowAll,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MoviPrimaryButton(
                label: hideAllLabel,
                onPressed: disabled ? null : onHideAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
