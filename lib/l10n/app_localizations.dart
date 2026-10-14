import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('it'),
  ];

  /// Name of the app, in the window title and the Dock.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get appTitle;

  /// Window title: the running program or the title it set, then the size in character cells.
  ///
  /// In en, this message translates to:
  /// **'{title} — {columns}×{rows}'**
  String windowTitle(String title, int columns, int rows);

  /// Command and button that opens a new tab.
  ///
  /// In en, this message translates to:
  /// **'New Tab'**
  String get newTab;

  /// Command and button that closes the current tab.
  ///
  /// In en, this message translates to:
  /// **'Close Tab'**
  String get closeTab;

  /// Title of the alert shown when closing a tab whose shell runs another program.
  ///
  /// In en, this message translates to:
  /// **'Do you want to terminate running processes in this tab?'**
  String get closeTabConfirmTitle;

  /// Message of that alert.
  ///
  /// In en, this message translates to:
  /// **'Closing this tab will terminate the running processes in it.'**
  String get closeTabConfirmMessage;

  /// Destructive button of that alert.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminate;

  /// Button that dismisses an alert without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Shown in the terminal area when the app runs outside Silica, where the pseudo-terminal channel is missing.
  ///
  /// In en, this message translates to:
  /// **'The terminal needs the Silica desktop: its pseudo-terminal service is not available here.'**
  String get noPty;

  /// Shown when the shell process cannot be started.
  ///
  /// In en, this message translates to:
  /// **'Could not start the shell: {error}'**
  String spawnFailed(String error);

  /// Shown at the end of the output when the shell exits.
  ///
  /// In en, this message translates to:
  /// **'The process exited with code {code}.'**
  String processExited(int code);

  /// Shown when the shell is ended by a signal.
  ///
  /// In en, this message translates to:
  /// **'The process was ended by signal {signal}.'**
  String processKilled(int signal);

  /// Placeholder of the find field.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// Position of the current match among all matches of the find field.
  ///
  /// In en, this message translates to:
  /// **'{current} of {count}'**
  String findMatches(int current, int count);

  /// The find field found nothing.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get findNoMatches;

  /// Button of the find bar that selects the previous match.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPrevious;

  /// Button of the find bar that selects the next match.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNext;

  /// Button that closes the find bar.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get findDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
