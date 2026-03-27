import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/features/settings/presentation/pages/iptv_source_add_page.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

/// Dev-only visual preview for the IPTV source add page.
///
/// This screen is intentionally disconnected from the real connection flow so
/// the UI can be reviewed and iterated without going through app bootstrap.
class IptvSourceAddPreviewPage extends StatefulWidget {
  const IptvSourceAddPreviewPage({super.key});

  @override
  State<IptvSourceAddPreviewPage> createState() =>
      _IptvSourceAddPreviewPageState();
}

class _IptvSourceAddPreviewPageState extends State<IptvSourceAddPreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Mon IPTV');
  final _serverCtrl = TextEditingController(text: 'http://server-demo.com:80/');
  final _userCtrl = TextEditingController(text: 'demo_user');
  final _passCtrl = TextEditingController(text: 'secret123');
  final _nameFocusNode = FocusNode(debugLabel: 'PreviewAddSourceName');
  final _serverFocusNode = FocusNode(debugLabel: 'PreviewAddSourceServer');
  final _userFocusNode = FocusNode(debugLabel: 'PreviewAddSourceUser');
  final _passFocusNode = FocusNode(debugLabel: 'PreviewAddSourcePassword');
  final _submitFocusNode = FocusNode(debugLabel: 'PreviewAddSourceSubmit');

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _nameFocusNode.dispose();
    _serverFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview UI: cette page ne connecte aucune source.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                IptvSourceAddHeader(onBack: () => context.pop()),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Apercu UI',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    IptvSourceAddFieldBlock(
                                      label: 'Nom de la source',
                                      controller: _nameCtrl,
                                      focusNode: _nameFocusNode,
                                      enabled: true,
                                      hintText: 'Mon IPTV',
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: () =>
                                          _serverFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 20),
                                    IptvSourceAddFieldBlock(
                                      label: 'URL du serveur',
                                      controller: _serverCtrl,
                                      focusNode: _serverFocusNode,
                                      enabled: true,
                                      keyboardType: TextInputType.url,
                                      hintText: 'http://server.com:80/',
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: () =>
                                          _userFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 20),
                                    IptvSourceAddFieldBlock(
                                      label: 'Nom d\'utilisateur',
                                      controller: _userCtrl,
                                      focusNode: _userFocusNode,
                                      enabled: true,
                                      hintText: 'Nom d\'utilisateur',
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: () =>
                                          _passFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 20),
                                    IptvSourceAddFieldBlock(
                                      label: 'Mot de passe',
                                      controller: _passCtrl,
                                      focusNode: _passFocusNode,
                                      enabled: true,
                                      hintText: 'Mot de passe',
                                      obscureText: _obscurePassword,
                                      onToggleObscure: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: () =>
                                          _submitFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: MoviPrimaryButton(
                                        label: 'Ajouter la source',
                                        focusNode: _submitFocusNode,
                                        onPressed: _showPreviewNotice,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
