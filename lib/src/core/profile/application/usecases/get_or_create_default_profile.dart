import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// Use case: rÃƒÆ’Ã‚Â©cupÃƒÆ’Ã‚Â©rer le profil par dÃƒÆ’Ã‚Â©faut si prÃƒÆ’Ã‚Â©sent, sinon le crÃƒÆ’Ã‚Â©er.
///
/// Typiquement utilisÃƒÆ’Ã‚Â© au bootstrap/onboarding (Netflix-like).
class GetOrCreateDefaultProfileUseCase {
  const GetOrCreateDefaultProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Profile> call({
    String? accountId,
    bool? diagnostics,
  }) {
    return _repo.getOrCreateDefaultProfile(
      accountId: accountId,
      diagnostics: diagnostics,
    );
  }
}
