import 'package:flutter/material.dart';

import '../../../../core/utils/utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text('Préférences générales', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: true,
              title: const Text('Mode sombre'),
              subtitle: const Text('Active un thème adapté à la nuit.'),
              onChanged: (_) {},
            ),
            SwitchListTile(
              value: false,
              title: const Text('Notifications'),
              subtitle: const Text('Soyez averti des nouvelles sorties.'),
              onChanged: (_) {},
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text('Compte', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Informations du profil'),
              subtitle: Text('Nom, avatar, préférences'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.language),
              title: Text('Langue de l’application'),
              subtitle: Text('Français (France)'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text('À propos', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Mentions légales'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Politique de confidentialité'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
