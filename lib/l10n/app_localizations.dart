import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('fr', 'MM'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill your preferences to personalize Movi.'**
  String get welcomeSubtitle;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get labelUsername;

  /// No description provided for @labelPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get labelPreferredLanguage;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get hintUsername;

  /// No description provided for @errorFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill the fields correctly.'**
  String get errorFillFields;

  /// No description provided for @homeWatchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch now'**
  String get homeWatchNow;

  /// No description provided for @welcomeSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeSourceTitle;

  /// No description provided for @welcomeSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a source to personalize your experience in Movi.'**
  String get welcomeSourceSubtitle;

  /// No description provided for @welcomeSourceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a source'**
  String get welcomeSourceAdd;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Type your search'**
  String get searchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @moviesTitle.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get moviesTitle;

  /// No description provided for @seriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get seriesTitle;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent searches'**
  String get historyEmpty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} results)'**
  String resultsCount(int count);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String errorConnectionFailed(String error);

  /// No description provided for @errorConnectionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get errorConnectionGeneric;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get validationInvalidUrl;

  /// No description provided for @snackbarSourceAddedBackground.
  ///
  /// In en, this message translates to:
  /// **'IPTV source added. Sync in background…'**
  String get snackbarSourceAddedBackground;

  /// No description provided for @snackbarSourceAddedSynced.
  ///
  /// In en, this message translates to:
  /// **'IPTV source added and synchronized'**
  String get snackbarSourceAddedSynced;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkModeTitle;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable a night-friendly theme.'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be notified of new releases.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountTitle;

  /// No description provided for @settingsProfileInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get settingsProfileInfoTitle;

  /// No description provided for @settingsProfileInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, avatar, preferences'**
  String get settingsProfileInfoSubtitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsLegalMentionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal mentions'**
  String get settingsLegalMentionsTitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @homeErrorSwipeToRetry.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Swipe down to retry.'**
  String get homeErrorSwipeToRetry;

  /// No description provided for @homeContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get homeContinueWatching;

  /// No description provided for @homeNoIptvSources.
  ///
  /// In en, this message translates to:
  /// **'No IPTV source active. Add a source in Settings to see your categories.'**
  String get homeNoIptvSources;

  /// No description provided for @homeNoTrends.
  ///
  /// In en, this message translates to:
  /// **'No trending content available'**
  String get homeNoTrends;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get actionExpand;

  /// No description provided for @castTitle.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get castTitle;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @libraryHeader.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get libraryHeader;

  /// No description provided for @libraryDataInfo.
  ///
  /// In en, this message translates to:
  /// **'Data will be displayed when data/domain is implemented.'**
  String get libraryDataInfo;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No content available yet.'**
  String get libraryEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pl',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'MM':
            return AppLocalizationsFrMm();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
