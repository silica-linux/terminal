// The Terminal window: the title band (the window buttons of Ossido sit in it, the empty band
// moves the window), the tab bar from two tabs, the find bar, and the character grid.
//
// Commands (docs/spec.md): terminal.new_tab ⌘T, terminal.close_tab ⌘W, terminal.next_tab ⌃⇥,
// terminal.previous_tab ⌃⇧⇥, terminal.find ⌘F, terminal.copy ⌘C, terminal.paste ⌘V,
// terminal.select_all ⌘A (⌘ is the Logo key; Ctrl+Shift+C/V copy and paste too).

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:xterm/xterm.dart';

import 'l10n.dart';
import 'pty.dart';
import 'search.dart';
import 'session.dart';
import 'style.dart';

class _NewTabIntent extends Intent {
  const _NewTabIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _StepTabIntent extends Intent {
  const _StepTabIntent(this.by);
  final int by;
}

class _FindIntent extends Intent {
  const _FindIntent();
}

/// The window commands, also inside the grid (which takes every other key for the program).
const Map<ShortcutActivator, Intent> windowShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyT, meta: true): _NewTabIntent(),
  SingleActivator(LogicalKeyboardKey.keyW, meta: true): _CloseTabIntent(),
  SingleActivator(LogicalKeyboardKey.tab, control: true): _StepTabIntent(1),
  SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
      _StepTabIntent(-1),
  SingleActivator(LogicalKeyboardKey.keyF, meta: true): _FindIntent(),
};

/// Copy, paste and select all inside the grid: with the Logo key, and with Ctrl+Shift for copy
/// and paste (plain Ctrl+C and Ctrl+V belong to the programs).
final Map<ShortcutActivator, Intent> gridShortcuts = {
  const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
      CopySelectionTextIntent.copy,
  const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
      CopySelectionTextIntent.copy,
  const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
      const PasteTextIntent(SelectionChangedCause.keyboard),
  const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
      const PasteTextIntent(SelectionChangedCause.keyboard),
  const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
      const SelectAllTextIntent(SelectionChangedCause.keyboard),
};

class TerminalWindow extends StatefulWidget {
  const TerminalWindow({
    super.key,
    required this.pty,
    this.command,
    this.cwd,
    this.shellName,
    this.onLastTabClosed,
  });

  final PtyBackend pty;

  /// The program of every tab; null: the user's login shell.
  final List<String>? command;
  final String? cwd;
  final String? shellName;

  /// The last tab was closed (the app closes its window).
  final VoidCallback? onLastTabClosed;

  @override
  State<TerminalWindow> createState() => TerminalWindowState();
}

class TerminalWindowState extends State<TerminalWindow> {
  final List<TerminalSession> _tabs = [];
  int _current = 0;

  bool _finding = false;
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  final FocusNode _gridFocus = FocusNode();
  List<SearchMatch> _matches = const [];
  int _match = 0;
  SearchHighlights? _highlights;

  bool _windowActive = _isActive(WidgetsBinding.instance.lifecycleState);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final active = _isActive(state);
      if (active != _windowActive) setState(() => _windowActive = active);
    },
  );

  static bool _isActive(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;

  /// The tabs, in order (tests).
  List<TerminalSession> get tabs => List.unmodifiable(_tabs);
  int get current => _current;
  TerminalSession get session => _tabs[_current];

  @override
  void initState() {
    super.initState();
    _lifecycle;
    newTab();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _highlights?.clear();
    for (final tab in _tabs) {
      tab.dispose();
    }
    _query.dispose();
    _queryFocus.dispose();
    _gridFocus.dispose();
    super.dispose();
  }

  /// Opens a new tab after the current one and makes it current.
  void newTab() {
    final session = TerminalSession(
      pty: widget.pty,
      command: widget.command,
      cwd: widget.cwd,
      shellName: widget.shellName,
    )..addListener(_changed);
    setState(() {
      final at = _tabs.isEmpty ? 0 : _current + 1;
      _tabs.insert(at, session);
      _current = at;
    });
    // Starts once the grid has its size (the view resizes the emulator on layout).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) session.start();
    });
    _endFind();
  }

  /// Closes the current tab (and its process); the last one closes the window.
  void closeTab([int? index]) {
    final i = index ?? _current;
    if (i < 0 || i >= _tabs.length) return;
    final session = _tabs.removeAt(i)..removeListener(_changed);
    session.dispose();
    if (_tabs.isEmpty) {
      widget.onLastTabClosed?.call();
      setState(() {});
      return;
    }
    setState(() => _current = _current.clamp(0, _tabs.length - 1));
    _endFind();
  }

  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _current = index);
    _endFind();
    _gridFocus.requestFocus();
  }

  void _step(int by) {
    if (_tabs.length < 2) return;
    selectTab((_current + by) % _tabs.length);
  }

  void _changed() {
    if (!mounted) return;
    // A resize arrives during layout (the view measures the grid): rebuild after the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _changed());
      return;
    }
    setState(() {});
    if (_tabs.isNotEmpty) {
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: _title),
      ).ignore();
    }
  }

  String get _title {
    final t = session.terminal;
    return l10n.windowTitle(session.title, t.viewWidth, t.viewHeight);
  }

  void _startFind() {
    setState(() => _finding = true);
    _queryFocus.requestFocus();
    _runFind();
  }

  void _endFind() {
    _highlights?.clear();
    _highlights = null;
    if (!_finding) return;
    setState(() {
      _finding = false;
      _matches = const [];
    });
    _gridFocus.requestFocus();
  }

  void _runFind({int step = 0}) {
    if (_tabs.isEmpty) return;
    final s = session;
    final matches = findAll(s.terminal.buffer, _query.text);
    setState(() {
      _matches = matches;
      _match = matches.isEmpty
          ? 0
          : (step == 0 ? matches.length - 1 : (_match + step)) % matches.length;
    });
    _highlights?.clear();
    _highlights = SearchHighlights(s.terminal, s.controller)
      ..show(matches, _match, profileOf(context).theme);
  }

  @override
  Widget build(BuildContext context) {
    final profile = profileOf(context);
    if (_tabs.isEmpty) {
      return ColoredBox(color: profile.theme.background);
    }
    final s = session;
    return Actions(
      actions: {
        _NewTabIntent: CallbackAction<_NewTabIntent>(onInvoke: (_) => newTab()),
        _CloseTabIntent: CallbackAction<_CloseTabIntent>(
          onInvoke: (_) => closeTab(),
        ),
        _StepTabIntent: CallbackAction<_StepTabIntent>(
          onInvoke: (intent) => _step(intent.by),
        ),
        _FindIntent: CallbackAction<_FindIntent>(onInvoke: (_) => _startFind()),
      },
      child: Shortcuts(
        shortcuts: windowShortcuts,
        child: ColoredBox(
          color: profile.theme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titleBand(profile),
              if (_tabs.length > 1) _tabBar(profile),
              if (_finding) _findBar(profile),
              Expanded(
                child: Padding(
                  padding: gridPadding,
                  child: TerminalView(
                    s.terminal,
                    key: ObjectKey(s),
                    controller: s.controller,
                    theme: profile.theme,
                    textStyle: terminalStyle,
                    focusNode: _gridFocus,
                    autofocus: true,
                    shortcuts: {...gridShortcuts, ...windowShortcuts},
                    hardwareKeyboardOnly: true,
                    keyboardAppearance:
                        MediaQuery.maybePlatformBrightnessOf(context) ??
                        Brightness.light,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBand(Profile profile) => WindowDragArea(
    child: Container(
      key: const ValueKey('title band'),
      height: titleBarHeight,
      color: profile.chrome,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 84),
      child: Text(
        _title,
        key: const ValueKey('title'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: uiText(
          size: 13,
          color: _windowActive ? profile.title : profile.titleInactive,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _tabBar(Profile profile) => Container(
    key: const ValueKey('tab bar'),
    height: tabBarHeight,
    color: profile.tab,
    child: Row(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: GestureDetector(
              key: ValueKey('tab $i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => selectTab(i),
              child: Container(
                color: i == _current ? profile.tabActive : null,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _tabs[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: uiText(size: 11, color: profile.tabText),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _findBar(Profile profile) {
    final status = _query.text.isEmpty
        ? ''
        : _matches.isEmpty
        ? l10n.findNoMatches
        : l10n.findMatches(_match + 1, _matches.length);
    return Container(
      key: const ValueKey('find bar'),
      height: 30,
      color: profile.chrome,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  _endFind();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  _runFind(
                    step: HardwareKeyboard.instance.isShiftPressed ? -1 : 1,
                  );
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (_query.text.isEmpty)
                    IgnorePointer(
                      child: Text(
                        l10n.find,
                        style: uiText(size: 12, color: profile.titleInactive),
                      ),
                    ),
                  EditableText(
                    key: const ValueKey('find field'),
                    controller: _query,
                    focusNode: _queryFocus,
                    style: uiText(size: 12, color: profile.title),
                    cursorColor: profile.title,
                    backgroundCursorColor: profile.title,
                    maxLines: 1,
                    onChanged: (_) => _runFind(),
                  ),
                ],
              ),
            ),
          ),
          Text(
            status,
            key: const ValueKey('find status'),
            style: uiText(size: 11, color: profile.titleInactive),
          ),
        ],
      ),
    );
  }
}
