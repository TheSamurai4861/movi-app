import '../value_objects/first_name.dart';
import '../value_objects/language_code.dart';
import '../value_objects/metadata_preference.dart';

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.languageCode,
    required this.metadataPreference,
  });

  final FirstName firstName;
  final LanguageCode languageCode;
  final MetadataPreference metadataPreference;
}
