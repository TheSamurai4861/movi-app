import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/profile/presentation/controllers/selected_profile_controller.dart';

/// Provider principal (state) : ID du profil sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â©.
final selectedProfileControllerProvider =
    NotifierProvider<SelectedProfileController, String?>(
  SelectedProfileController.new,
);

/// Alias pratique : l'ID sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â©.
final selectedProfileIdProvider = Provider<String?>((ref) {
  return ref.watch(selectedProfileControllerProvider);
});
