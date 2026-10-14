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
}
