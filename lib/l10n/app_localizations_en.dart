// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Terminal';

  @override
  String windowTitle(String title, int columns, int rows) {
    return '$title — $columns×$rows';
  }

  @override
  String get newTab => 'New Tab';

  @override
  String get closeTab => 'Close Tab';

  @override
  String get closeTabConfirmTitle =>
      'Do you want to terminate running processes in this tab?';

  @override
  String get closeTabConfirmMessage =>
      'Closing this tab will terminate the running processes in it.';

  @override
  String get closeWindowConfirmTitle =>
      'Do you want to terminate running processes in this window?';

  @override
  String get closeWindowConfirmMessage =>
      'Closing this window will terminate the running processes in it.';

  @override
  String get terminate => 'Terminate';

  @override
  String get cancel => 'Cancel';

  @override
  String get noPty =>
      'The terminal needs the Silica desktop: its pseudo-terminal service is not available here.';

  @override
  String spawnFailed(String error) {
    return 'Could not start the shell: $error';
  }

  @override
  String processExited(int code) {
    return 'The process exited with code $code.';
  }

  @override
  String processKilled(int signal) {
    return 'The process was ended by signal $signal.';
  }

  @override
  String get find => 'Find';

  @override
  String findMatches(int current, int count) {
    return '$current of $count';
  }

  @override
  String get findNoMatches => 'No matches';

  @override
  String get findPrevious => 'Previous match';

  @override
  String get findNext => 'Next match';

  @override
  String get findDone => 'Done';

  @override
  String get menuShell => 'Shell';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuHelp => 'Help';

  @override
  String get secureKeyboardEntry => 'Secure Keyboard Entry';

  @override
  String get newWindow => 'New Window';

  @override
  String newWindowWithProfile(String profile) {
    return 'New Window with Profile - $profile';
  }

  @override
  String get newWindowSameCommand => 'New Window with Same Command';

  @override
  String newTabWithProfile(String profile) {
    return 'New Tab with Profile - $profile';
  }

  @override
  String get newTabSameCommand => 'New Tab with Same Command';

  @override
  String get newCommand => 'New Command…';

  @override
  String get newRemoteConnection => 'New Remote Connection…';

  @override
  String get open => 'Open…';

  @override
  String get closeWindow => 'Close Window';

  @override
  String get closeAll => 'Close All';

  @override
  String get useSettingsAsDefault => 'Use Settings as Default';

  @override
  String get exportSettings => 'Export Settings…';

  @override
  String get exportText => 'Export Text As…';

  @override
  String get exportSelectedText => 'Export Selected Text As…';

  @override
  String get showInspector => 'Show Inspector';

  @override
  String get editTitle => 'Edit Title';

  @override
  String get editBackgroundColor => 'Edit Background Color';

  @override
  String get reset => 'Reset';

  @override
  String get hardReset => 'Hard Reset';

  @override
  String get printSelection => 'Print Selection…';

  @override
  String get print => 'Print…';

  @override
  String get copySpecial => 'Copy Special';

  @override
  String get copyWithoutBackground => 'Copy Without Background Color';

  @override
  String get copyTextOnly => 'Copy Text Only';

  @override
  String get copyStyle => 'Style for Copy Command';

  @override
  String get terminalSettingsDefault => 'Terminal Settings (default)';

  @override
  String get plainText => 'Text Only';

  @override
  String get pasteEscaped => 'Paste Escaped Text';

  @override
  String get pasteSelection => 'Paste Selection';

  @override
  String get pasteSelectionEscaped => 'Paste Selection Escaped';

  @override
  String get selectBetweenMarks => 'Select Between Marks';

  @override
  String get marks => 'Marks';

  @override
  String get autoMarkPrompts => 'Automatically Mark Prompt Lines';

  @override
  String get markLineAndNewline => 'Mark Line and Start New Line';

  @override
  String get newlineWithoutMark => 'Start New Line Without Marking';

  @override
  String get mark => 'Mark';

  @override
  String get markAsBookmark => 'Mark as Bookmark';

  @override
  String get removeMark => 'Remove Mark';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get insertBookmark => 'Insert Bookmark';

  @override
  String get insertNamedBookmark => 'Insert Bookmark with Name…';

  @override
  String get noBookmarks => 'No Bookmarks';

  @override
  String get navigate => 'Navigate';

  @override
  String get previousMark => 'Go to Previous Mark';

  @override
  String get selectToPreviousMark => 'Select to Previous Mark';

  @override
  String get nextMark => 'Go to Next Mark';

  @override
  String get selectToNextMark => 'Select to Next Mark';

  @override
  String get previousBookmark => 'Go to Previous Bookmark';

  @override
  String get selectToPreviousBookmark => 'Select to Previous Bookmark';

  @override
  String get nextBookmark => 'Go to Next Bookmark';

  @override
  String get selectToNextBookmark => 'Select to Next Bookmark';

  @override
  String get clearToPreviousMark => 'Clear to Previous Mark';

  @override
  String get clearToPreviousBookmark => 'Clear to Previous Bookmark';

  @override
  String get clearToStart => 'Clear to Start';

  @override
  String get removeExcessLines => 'Remove Excess Lines';

  @override
  String get clearScreen => 'Clear Screen';

  @override
  String get fillScreen => 'Fill Screen';

  @override
  String get findEllipsis => 'Find…';

  @override
  String get findNextItem => 'Find Next';

  @override
  String get findPreviousItem => 'Find Previous';

  @override
  String get findSelectAll => 'Select All';

  @override
  String get findSelectAllInSelection => 'Select All in Selection';

  @override
  String get hideFindBar => 'Hide Find Bar';

  @override
  String get useSelectionForFind => 'Use Selection for Find';

  @override
  String get jumpToSelection => 'Jump to Selection';

  @override
  String get showColors => 'Show Colors';

  @override
  String get optionAsMeta => 'Use Option as Meta Key';

  @override
  String get numLock => 'Num Lock';

  @override
  String get showAllTabs => 'Show All Tabs';

  @override
  String get showTabBar => 'Show Tab Bar';

  @override
  String get hideMarks => 'Hide Marks';

  @override
  String get showAlternateScreen => 'Show Alternate Screen';

  @override
  String get hideAlternateScreen => 'Hide Alternate Screen';

  @override
  String get allowMouseReporting => 'Allow Mouse Reporting';

  @override
  String get splitPane => 'Split Pane';

  @override
  String get closeSplitPane => 'Close Split Pane';

  @override
  String get defaultFontSize => 'Default Font Size';

  @override
  String get fontBigger => 'Bigger';

  @override
  String get fontSmaller => 'Smaller';

  @override
  String get scrollToTop => 'Scroll to Top';

  @override
  String get scrollToBottom => 'Scroll to Bottom';

  @override
  String get pageUp => 'Page Up';

  @override
  String get pageDown => 'Page Down';

  @override
  String get lineUp => 'Line Up';

  @override
  String get lineDown => 'Line Down';

  @override
  String get showPreviousTab => 'Show Previous Tab';

  @override
  String get showNextTab => 'Show Next Tab';

  @override
  String get moveTabToNewWindow => 'Move Tab to New Window';

  @override
  String get mergeAllWindows => 'Merge All Windows';

  @override
  String get openWindowGroup => 'Open Window Group';

  @override
  String get noWindowGroups => 'No Window Groups';

  @override
  String get saveWindowsAsGroup => 'Save Windows as Group…';

  @override
  String get openManPage => 'Open man Page for Selection';

  @override
  String get searchManIndex => 'Search man Page Index for Selection';
}
