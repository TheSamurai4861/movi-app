import '../value_objects/first_name.dart';
import '../value_objects/language_code.dart';

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.languageCode,
  });

  final FirstName firstName;
  final LanguageCode languageCode;
}
