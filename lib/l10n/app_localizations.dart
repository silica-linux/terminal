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

  /// Menu bar: the Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get menuShell;

  /// Menu bar: the Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// Menu bar: the View menu.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// Menu bar: the Window menu.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// Menu bar: the Help menu.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// App menu item.
  ///
  /// In en, this message translates to:
  /// **'Secure Keyboard Entry'**
  String get secureKeyboardEntry;

  /// Shell menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'New Window'**
  String get newWindow;

  /// Shell menu: new window with the default profile.
  ///
  /// In en, this message translates to:
  /// **'New Window with Profile - {profile}'**
  String newWindowWithProfile(String profile);

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'New Window with Same Command'**
  String get newWindowSameCommand;

  /// Shell menu: new tab with the default profile.
  ///
  /// In en, this message translates to:
  /// **'New Tab with Profile - {profile}'**
  String newTabWithProfile(String profile);

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'New Tab with Same Command'**
  String get newTabSameCommand;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'New Command…'**
  String get newCommand;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'New Remote Connection…'**
  String get newRemoteConnection;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Open…'**
  String get open;

  /// Shell menu: closes the window when it has one tab.
  ///
  /// In en, this message translates to:
  /// **'Close Window'**
  String get closeWindow;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Close All'**
  String get closeAll;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Use Settings as Default'**
  String get useSettingsAsDefault;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Export Settings…'**
  String get exportSettings;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Export Text As…'**
  String get exportText;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Export Selected Text As…'**
  String get exportSelectedText;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Show Inspector'**
  String get showInspector;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Edit Background Color'**
  String get editBackgroundColor;

  /// Shell menu: resets the terminal.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Hard Reset'**
  String get hardReset;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Print Selection…'**
  String get printSelection;

  /// Shell menu.
  ///
  /// In en, this message translates to:
  /// **'Print…'**
  String get print;

  /// Edit menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'Copy Special'**
  String get copySpecial;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Copy Without Background Color'**
  String get copyWithoutBackground;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Copy Text Only'**
  String get copyTextOnly;

  /// Edit menu: heading of the styles.
  ///
  /// In en, this message translates to:
  /// **'Style for Copy Command'**
  String get copyStyle;

  /// Edit menu: copy style that follows the profile.
  ///
  /// In en, this message translates to:
  /// **'Terminal Settings (default)'**
  String get terminalSettingsDefault;

  /// Edit menu: copy style.
  ///
  /// In en, this message translates to:
  /// **'Text Only'**
  String get plainText;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Paste Escaped Text'**
  String get pasteEscaped;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Paste Selection'**
  String get pasteSelection;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Paste Selection Escaped'**
  String get pasteSelectionEscaped;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Select Between Marks'**
  String get selectBetweenMarks;

  /// Edit menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marks;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Automatically Mark Prompt Lines'**
  String get autoMarkPrompts;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Mark Line and Start New Line'**
  String get markLineAndNewline;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Start New Line Without Marking'**
  String get newlineWithoutMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get mark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Mark as Bookmark'**
  String get markAsBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Remove Mark'**
  String get removeMark;

  /// Edit menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Insert Bookmark'**
  String get insertBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Insert Bookmark with Name…'**
  String get insertNamedBookmark;

  /// Edit menu: empty list of bookmarks.
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks'**
  String get noBookmarks;

  /// Edit menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Go to Previous Mark'**
  String get previousMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Select to Previous Mark'**
  String get selectToPreviousMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Go to Next Mark'**
  String get nextMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Select to Next Mark'**
  String get selectToNextMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Go to Previous Bookmark'**
  String get previousBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Select to Previous Bookmark'**
  String get selectToPreviousBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Go to Next Bookmark'**
  String get nextBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Select to Next Bookmark'**
  String get selectToNextBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Clear to Previous Mark'**
  String get clearToPreviousMark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Clear to Previous Bookmark'**
  String get clearToPreviousBookmark;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Clear to Start'**
  String get clearToStart;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Remove Excess Lines'**
  String get removeExcessLines;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Clear Screen'**
  String get clearScreen;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Fill Screen'**
  String get fillScreen;

  /// Edit menu, Find submenu: opens the find bar.
  ///
  /// In en, this message translates to:
  /// **'Find…'**
  String get findEllipsis;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Find Next'**
  String get findNextItem;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Find Previous'**
  String get findPreviousItem;

  /// Edit menu, Find submenu: selects all matches.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get findSelectAll;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Select All in Selection'**
  String get findSelectAllInSelection;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Hide Find Bar'**
  String get hideFindBar;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Use Selection for Find'**
  String get useSelectionForFind;

  /// Edit menu, Find submenu.
  ///
  /// In en, this message translates to:
  /// **'Jump to Selection'**
  String get jumpToSelection;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Show Colors'**
  String get showColors;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Use Option as Meta Key'**
  String get optionAsMeta;

  /// Edit menu.
  ///
  /// In en, this message translates to:
  /// **'Num Lock'**
  String get numLock;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Show All Tabs'**
  String get showAllTabs;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Show Tab Bar'**
  String get showTabBar;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Hide Marks'**
  String get hideMarks;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Show Alternate Screen'**
  String get showAlternateScreen;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Hide Alternate Screen'**
  String get hideAlternateScreen;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Allow Mouse Reporting'**
  String get allowMouseReporting;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Split Pane'**
  String get splitPane;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Close Split Pane'**
  String get closeSplitPane;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Default Font Size'**
  String get defaultFontSize;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Bigger'**
  String get fontBigger;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get fontSmaller;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Top'**
  String get scrollToTop;

  /// View menu.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Bottom'**
  String get scrollToBottom;

  /// View menu: scrolls one page up.
  ///
  /// In en, this message translates to:
  /// **'Page Up'**
  String get pageUp;

  /// View menu: scrolls one page down.
  ///
  /// In en, this message translates to:
  /// **'Page Down'**
  String get pageDown;

  /// View menu: scrolls one line up.
  ///
  /// In en, this message translates to:
  /// **'Line Up'**
  String get lineUp;

  /// View menu: scrolls one line down.
  ///
  /// In en, this message translates to:
  /// **'Line Down'**
  String get lineDown;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'Show Previous Tab'**
  String get showPreviousTab;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'Show Next Tab'**
  String get showNextTab;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'Move Tab to New Window'**
  String get moveTabToNewWindow;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'Merge All Windows'**
  String get mergeAllWindows;

  /// Window menu: submenu.
  ///
  /// In en, this message translates to:
  /// **'Open Window Group'**
  String get openWindowGroup;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'No Window Groups'**
  String get noWindowGroups;

  /// Window menu.
  ///
  /// In en, this message translates to:
  /// **'Save Windows as Group…'**
  String get saveWindowsAsGroup;

  /// Help menu.
  ///
  /// In en, this message translates to:
  /// **'Open man Page for Selection'**
  String get openManPage;

  /// Help menu.
  ///
  /// In en, this message translates to:
  /// **'Search man Page Index for Selection'**
  String get searchManIndex;
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
