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
  String get closeTabConfirmTitle =>
      'Vuoi terminare i processi in esecuzione in questo pannello?';

  @override
  String get closeTabConfirmMessage =>
      'Chiudendo questo pannello verranno terminati i processi in esecuzione.';

  @override
  String get terminate => 'Termina';

  @override
  String get cancel => 'Annulla';

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

  @override
  String get findPrevious => 'Risultato precedente';

  @override
  String get findNext => 'Risultato successivo';

  @override
  String get findDone => 'Fine';

  @override
  String get menuShell => 'Shell';

  @override
  String get menuEdit => 'Modifica';

  @override
  String get menuView => 'Vista';

  @override
  String get menuWindow => 'Finestra';

  @override
  String get menuHelp => 'Aiuto';

  @override
  String get secureKeyboardEntry => 'Input da tastiera sicuro';

  @override
  String get newWindow => 'Nuova finestra';

  @override
  String newWindowWithProfile(String profile) {
    return 'Nuova finestra con profilo - $profile';
  }

  @override
  String get newWindowSameCommand => 'Nuova finestra con lo stesso comando';

  @override
  String newTabWithProfile(String profile) {
    return 'Nuovo pannello con profilo - $profile';
  }

  @override
  String get newTabSameCommand => 'Nuovo pannello con lo stesso comando';

  @override
  String get newCommand => 'Nuovo comando…';

  @override
  String get newRemoteConnection => 'Nuova connessione remota…';

  @override
  String get open => 'Apri…';

  @override
  String get closeWindow => 'Chiudi finestra';

  @override
  String get closeAll => 'Chiudi tutto';

  @override
  String get useSettingsAsDefault => 'Utilizza impostazioni come default';

  @override
  String get exportSettings => 'Esporta impostazioni…';

  @override
  String get exportText => 'Esporta testo con il nome…';

  @override
  String get exportSelectedText => 'Esporta testo selezionato con il nome…';

  @override
  String get showInspector => 'Mostra inspector';

  @override
  String get editTitle => 'Modifica titolo';

  @override
  String get editBackgroundColor => 'Modifica colore di sfondo';

  @override
  String get reset => 'Ripristina';

  @override
  String get hardReset => 'Ripristino forzato';

  @override
  String get printSelection => 'Stampa selezione…';

  @override
  String get print => 'Stampa…';

  @override
  String get copySpecial => 'Copia speciale';

  @override
  String get copyWithoutBackground => 'Copia senza colore di sfondo';

  @override
  String get copyTextOnly => 'Copia solo testo';

  @override
  String get copyStyle => 'Stile per il comando Copia';

  @override
  String get terminalSettingsDefault => 'Impostazioni Terminale (default)';

  @override
  String get plainText => 'Solo testo';

  @override
  String get pasteEscaped => 'Incolla testo con caratteri di escape';

  @override
  String get pasteSelection => 'Incolla selezione';

  @override
  String get pasteSelectionEscaped =>
      'Incolla selezione con caratteri di escape';

  @override
  String get selectBetweenMarks => 'Seleziona tra i contrassegni';

  @override
  String get marks => 'Contrassegni';

  @override
  String get autoMarkPrompts => 'Contrassegna automaticamente righe di prompt';

  @override
  String get markLineAndNewline => 'Contrassegna linea e vai a capo';

  @override
  String get newlineWithoutMark => 'Vai a capo senza contrassegnare';

  @override
  String get mark => 'Contrassegna';

  @override
  String get markAsBookmark => 'Contrassegna come segnalibro';

  @override
  String get removeMark => 'Rimuovi contrassegno';

  @override
  String get bookmarks => 'Segnalibri';

  @override
  String get insertBookmark => 'Inserisci segnalibro';

  @override
  String get insertNamedBookmark => 'Inserisci segnalibro con nome…';

  @override
  String get noBookmarks => 'Nessun segnalibro';

  @override
  String get navigate => 'Naviga';

  @override
  String get previousMark => 'Vai al contrassegno precedente';

  @override
  String get selectToPreviousMark =>
      'Seleziona fino al contrassegno precedente';

  @override
  String get nextMark => 'Vai al contrassegno successivo';

  @override
  String get selectToNextMark => 'Seleziona fino al contrassegno successivo';

  @override
  String get previousBookmark => 'Vai al segnalibro precedente';

  @override
  String get selectToPreviousBookmark =>
      'Seleziona fino al segnalibro precedente';

  @override
  String get nextBookmark => 'Vai al segnalibro successivo';

  @override
  String get selectToNextBookmark => 'Seleziona fino al segnalibro successivo';

  @override
  String get clearToPreviousMark => 'Cancella fino al contrassegno precedente';

  @override
  String get clearToPreviousBookmark =>
      'Cancella fino al segnalibro precedente';

  @override
  String get clearToStart => 'Cancella fino all’inizio';

  @override
  String get removeExcessLines => 'Elimina linee in eccesso';

  @override
  String get clearScreen => 'Cancella schermata';

  @override
  String get fillScreen => 'Riempi schermo';

  @override
  String get findEllipsis => 'Trova…';

  @override
  String get findNextItem => 'Trova successivo';

  @override
  String get findPreviousItem => 'Trova precedente';

  @override
  String get findSelectAll => 'Seleziona tutto';

  @override
  String get findSelectAllInSelection => 'Seleziona tutto nella selezione';

  @override
  String get hideFindBar => 'Nascondi barra di ricerca';

  @override
  String get useSelectionForFind => 'Usa selezione per trovare';

  @override
  String get jumpToSelection => 'Vai alla selezione';

  @override
  String get showColors => 'Mostra colori';

  @override
  String get optionAsMeta => 'Usa il tasto Opzione come tasto Meta';

  @override
  String get numLock => 'Bloc Num';

  @override
  String get showAllTabs => 'Mostra tutti i pannelli';

  @override
  String get showTabBar => 'Mostra barra dei pannelli';

  @override
  String get hideMarks => 'Nascondi contrassegni';

  @override
  String get showAlternateScreen => 'Mostra schermo alternativo';

  @override
  String get hideAlternateScreen => 'Nascondi schermo alternativo';

  @override
  String get allowMouseReporting => 'Consenti resoconto mouse';

  @override
  String get splitPane => 'Dividi pannello';

  @override
  String get closeSplitPane => 'Chiudi Dividi pannello';

  @override
  String get defaultFontSize => 'Dimensioni font di default';

  @override
  String get fontBigger => 'Aumenta';

  @override
  String get fontSmaller => 'Riduci';

  @override
  String get scrollToTop => 'Scorri fino in cima';

  @override
  String get scrollToBottom => 'Scorri fino in fondo';

  @override
  String get pageUp => 'Inizio pagina';

  @override
  String get pageDown => 'Fine pagina';

  @override
  String get lineUp => 'Linea superiore';

  @override
  String get lineDown => 'Linea inferiore';

  @override
  String get showPreviousTab => 'Mostra pannello precedente';

  @override
  String get showNextTab => 'Mostra pannello successivo';

  @override
  String get moveTabToNewWindow => 'Sposta pannello in una nuova finestra';

  @override
  String get mergeAllWindows => 'Unisci tutte le finestre';

  @override
  String get openWindowGroup => 'Apri gruppo finestre';

  @override
  String get noWindowGroups => 'Nessun gruppo di finestre';

  @override
  String get saveWindowsAsGroup => 'Salva finestre come gruppo…';

  @override
  String get openManPage => 'Apri la pagina man per la selezione';

  @override
  String get searchManIndex => 'Cerca indice pagina man per selezione';
}
