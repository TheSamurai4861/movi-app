import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _refreshingIptv = false;

  Future<void> _refreshIptv() async {
    if (_refreshingIptv) return;
    var active = ref.read(appStateControllerProvider).activeIptvSourceIds;
    if (active.isEmpty) {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final accounts = await iptvLocal.getAccounts();
      if (accounts.isNotEmpty) {
        final ids = accounts.map((a) => a.id).toSet();
        ref.read(appStateControllerProvider).setActiveIptvSources(ids);
        active = ids;
      }
      if (active.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.homeNoIptvSources),
            ),
          );
        }
        return;
      }
    }
    setState(() => _refreshingIptv = true);
    final refresh = ref.read(refreshXtreamCatalogProvider);
    final logger = ref.read(slProvider)<AppLogger>();
    int ok = 0;
    int ko = 0;
    final errors = <String>[];
    for (final id in active) {
      final res = await refresh(id);
      res.fold(
        ok: (_) => ok += 1,
        err: (f) {
          ko += 1;
          errors.add(f.message);
          logger.error('IPTV refresh failed for $id: ${f.message}');
        },
      );
    }
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Playlists IPTV rafraîchies ($ok/${active.length})${ko > 0 ? ' | erreurs: $ko' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      if (ko > 0 && errors.isNotEmpty) {
        final detail = errors.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (mounted) setState(() => _refreshingIptv = false);
  }


  Widget _buildSettingItem({
    required String title,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevronDown = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing != null)
              trailing
            else if (showChevronDown)
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF007AFF),
                size: 20,
              )
            else if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCircle({
    required String name,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Titre
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 32),
            // Section Comptes
            Text(
              'Comptes',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildProfileCircle(
                  name: 'Matt',
                  color: const Color(0xFF007AFF),
                  icon: Icons.account_circle,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Manu',
                  color: const Color(0xFFFF6B9D),
                  icon: Icons.wb_sunny,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Ber',
                  color: const Color(0xFF34C759),
                  icon: Icons.music_note,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Ajouter',
                  color: const Color(0xFF8E8E93),
                  icon: Icons.add,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Section Paramètres IPTV
            Text(
              'Paramètres IPTV',
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
            _buildSettingItem(
              title: 'Réglages des sources',
              onTap: () {
                // TODO: Implémenter la navigation
              },
            ),
            _buildSettingItem(
              title: 'Fréquence màj',
              value: 'Tous les jours',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur
              },
            ),
            _buildSettingItem(
              title: AppLocalizations.of(context)!.settingsRefreshIptvPlaylistsTitle,
              trailing: _refreshingIptv
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF007AFF),
                      ),
                    )
                  : null,
              onTap: _refreshingIptv ? null : _refreshIptv,
            ),
            const SizedBox(height: 32),
            // Section Paramètres de l'application
            Text(
              'Paramètres de l\'application',
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
            _buildSettingItem(
              title: 'Langue',
              value: 'Français',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur de langue
              },
            ),
            _buildSettingItem(
              title: 'Thème',
              value: 'Sombre',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur de thème
              },
            ),
            const SizedBox(height: 32),
            // Section Paramètres de lecture
            Text(
              'Paramètres de lecture',
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
            _buildSettingItem(
              title: 'Qualité préférée',
              value: '4K',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur
              },
            ),
            _buildSettingItem(
              title: 'Langue préférée',
              value: 'Anglais',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur
              },
            ),
            _buildSettingItem(
              title: 'Sous-titres préférés',
              value: 'Français',
              showChevronDown: true,
              onTap: () {
                // TODO: Implémenter le sélecteur
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
