import 'package:flutter/material.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';

class XtreamRoutePolicyFormSection extends StatelessWidget {
  const XtreamRoutePolicyFormSection({
    super.key,
    required this.profiles,
    required this.preferredRouteProfileId,
    required this.fallbackRouteProfileIds,
    required this.onPreferredChanged,
    required this.onEditFallbacks,
    required this.onOpenNetworkProfiles,
    required this.onTestSource,
    this.lastWorkingRouteProfileId,
    this.enabled = true,
  });

  final List<RouteProfile> profiles;
  final String preferredRouteProfileId;
  final List<String> fallbackRouteProfileIds;
  final ValueChanged<String?> onPreferredChanged;
  final VoidCallback onEditFallbacks;
  final VoidCallback onOpenNetworkProfiles;
  final VoidCallback onTestSource;
  final String? lastWorkingRouteProfileId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferredValue = profiles.any((p) => p.id == preferredRouteProfileId)
        ? preferredRouteProfileId
        : RouteProfile.defaultId;
    final fallbackLabels = fallbackRouteProfileIds
        .map((id) => _profileNameById(id))
        .toList(growable: false);
    final lastWorkingName = lastWorkingRouteProfileId == null
        ? null
        : _profileNameById(lastWorkingRouteProfileId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connexion reseau',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(preferredValue),
          initialValue: preferredValue,
          decoration: _decoration('Profil prefere'),
          dropdownColor: const Color(0xFF262626),
          style: const TextStyle(color: Colors.white),
          items: profiles
              .map(
                (profile) => DropdownMenuItem<String>(
                  value: profile.id,
                  child: Text(_profileLabel(profile)),
                ),
              )
              .toList(growable: false),
          onChanged: enabled ? onPreferredChanged : null,
        ),
        const SizedBox(height: 12),
        _ReadOnlyTile(
          title: 'Profils de secours',
          value: fallbackLabels.isEmpty ? 'Aucun' : fallbackLabels.join(', '),
          actionLabel: 'Choisir',
          enabled: enabled,
          onPressed: onEditFallbacks,
        ),
        if (lastWorkingName != null && lastWorkingName.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReadOnlyTile(
            title: 'Dernier profil valide',
            value: lastWorkingName,
            actionLabel: null,
            enabled: false,
            onPressed: null,
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: enabled ? onOpenNetworkProfiles : null,
              child: const Text('Profils reseau'),
            ),
            OutlinedButton(
              onPressed: enabled ? onTestSource : null,
              child: const Text('Tester la source'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF3D3D3D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }

  String _profileLabel(RouteProfile profile) {
    if (profile.kind == RouteProfileKind.defaultRoute) {
      return '${profile.name} (systeme)';
    }
    final host = profile.proxyHost?.trim() ?? '';
    final port = profile.proxyPort;
    if (host.isEmpty || port == null || port <= 0) {
      return profile.name;
    }
    return '${profile.name} ($host:$port)';
  }

  String _profileNameById(String id) {
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile.name;
      }
    }
    return id;
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String value;
  final String? actionLabel;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: enabled ? onPressed : null,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
