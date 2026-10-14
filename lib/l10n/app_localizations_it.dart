// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Terminale';

  @override
  String windowTitle(String title, int columns, int rows) {
    return '$title — $columns×$rows';
  }

  @override
  String get newTab => 'Nuovo pannello';

  @override
  String get closeTab => 'Chiudi pannello';

  @override
  String get noPty =>
      'Il terminale ha bisogno della scrivania di Silica: qui il suo servizio di pseudo-terminale non c\'è.';

  @override
  String spawnFailed(String error) {
    return 'Impossibile avviare la shell: $error';
  }

  @override
  String processExited(int code) {
    return 'Il processo è terminato con il codice $code.';
  }

  @override
  String processKilled(int signal) {
    return 'Il processo è stato chiuso dal segnale $signal.';
  }

  @override
  String get find => 'Cerca';

  @override
  String findMatches(int current, int count) {
    return '$current di $count';
  }

  @override
  String get findNoMatches => 'Nessun risultato';
}
