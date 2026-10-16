// The Terminal window on the Amalfi kit (`App · Terminal`): the 32 pt title band (the window
// controls sit in it, the empty band moves the window), the 36 pt tab bar always visible, the
// 32 pt find bar that grows the window, and the character grid in a 12 pt padding with an
// overlay scroll bar.
//
// Commands (docs/spec.md) are the items of the menus published to Silica's menu bar (menus()):
// terminal.new_tab ⌘T, terminal.close_tab ⌘W, terminal.next_tab ⌃⇥, terminal.previous_tab ⌃⇧⇥,
// terminal.find ⌘F, terminal.copy ⌘C, terminal.paste ⌘V, terminal.select_all ⌘A and the scroll
// and find commands (⌘ is the Logo key; Ctrl+Shift+C/V copy and paste too).

import 'dart:async';

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

class _StepTabIntent extends Intent {
  const _StepTabIntent(this.by);
  final int by;
}

/// The window commands that work inside the grid (which takes every other key for the
/// program) besides the menu bar's: switching tabs with Ctrl. The Logo-key shortcuts (⌘T, ⌘W,
/// ⌘F…) are the menu bar's (`SilicaMenuBar` binds them).
const Map<ShortcutActivator, Intent> windowShortcuts = {
  SingleActivator(LogicalKeyboardKey.tab, control: true): _StepTabIntent(1),
  SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
      _StepTabIntent(-1),
};

/// Copy and paste with Ctrl+Shift inside the grid (plain Ctrl+C and Ctrl+V belong to the
/// programs); with the Logo key they are the menu bar's.
final Map<ShortcutActivator, Intent> gridShortcuts = {
  const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
      CopySelectionTextIntent.copy,
  const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
      const PasteTextIntent(SelectionChangedCause.keyboard),
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

/// A tab in the bar: its session and how far in it is (0 → 1 entering, 1 → 0 closing).
class _TabSlot {
  _TabSlot(this.session, this.presence);
  final TerminalSession session;
  final AnimationController presence;
  bool closing = false;
}

class TerminalWindowState extends State<TerminalWindow>
    with TickerProviderStateMixin {
  final List<TerminalSession> _tabs = [];
  int _current = 0;

  /// The tabs drawn in the bar, closing ones included until they have shrunk away.
  final List<_TabSlot> _slots = [];
  final ScrollController _scroll = ScrollController();

  bool _finding = false;
  final TextEditingController _query = TextEditingController();
  late final FocusNode _queryFocus = FocusNode(onKeyEvent: _findKey);
  final FocusNode _gridFocus = FocusNode();
  List<SearchMatch> _matches = const [];
  int _match = 0;

  /// The tab waiting for the answer of the "terminate running processes?" alert.
  TerminalSession? _confirming;

  /// The answer to the same alert asked for the whole window (its close button, Logo+W).
  Completer<bool>? _confirmingWindow;
  SearchHighlights? _highlights;

  bool _windowActive = _isActive(WidgetsBinding.instance.lifecycleState);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final active = _isActive(state);
      if (active == _windowActive) return;
      setState(() => _windowActive = active);
      // An inactive window shows a hollow cursor (the grid without focus) and a grey selection.
      if (!active) {
        _gridFocus.unfocus();
      } else if (!_finding) {
        _gridFocus.requestFocus();
      }
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
    SilicaWindows.onMainCloseRequested = requestCloseWindow;
    newTab();
  }

  @override
  void dispose() {
    if (SilicaWindows.onMainCloseRequested == requestCloseWindow) {
      SilicaWindows.onMainCloseRequested = null;
    }
    _lifecycle.dispose();
    _highlights?.clear();
    for (final tab in _tabs) {
      tab.dispose();
    }
    for (final slot in _slots) {
      slot.presence.dispose();
    }
    _scroll.dispose();
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
    session.controller.addListener(_selectionChanged);
    // The new tab slides in from the right and settles in ~550 ms.
    final presence = AnimationController(
      vsync: this,
      duration: tabEnter,
      reverseDuration: tabExit,
    );
    setState(() {
      final at = _tabs.isEmpty ? 0 : _current + 1;
      final after = _tabs.isEmpty ? null : _tabs[_current];
      _tabs.insert(at, session);
      _current = at;
      final slotAt = after == null
          ? _slots.length
          : _slots.indexWhere((s) => s.session == after) + 1;
      _slots.insert(
        slotAt.clamp(0, _slots.length),
        _TabSlot(session, presence),
      );
    });
    if (_slots.length == 1) {
      presence.value = 1;
    } else {
      presence.forward();
    }
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
    session.controller.removeListener(_selectionChanged);
    session.dispose();
    // The closed tab shrinks away in ~500 ms while the others grow.
    for (final slot in _slots.where((s) => s.session == session).toList()) {
      slot.closing = true;
      slot.presence.reverse().whenCompleteOrCancel(() {
        if (!mounted) return;
        setState(() => _slots.remove(slot));
        slot.presence.dispose();
      });
    }
    if (_tabs.isEmpty) {
      widget.onLastTabClosed?.call();
      setState(() {});
      return;
    }
    setState(() => _current = _current.clamp(0, _tabs.length - 1));
    _endFind();
  }

  /// Closes a tab like the × and ⌘W do: when a program other than the shell runs in it, asks
  /// first ("Do you want to terminate running processes in this tab?").
  Future<void> requestCloseTab([int? index]) async {
    final i = index ?? _current;
    if (i < 0 || i >= _tabs.length) return;
    if (_confirming != null || _confirmingWindow != null) return;
    final session = _tabs[i];
    if (await session.hasForegroundProcess()) {
      if (!mounted || !_tabs.contains(session)) return;
      setState(() => _confirming = session);
      return;
    }
    if (mounted && _tabs.contains(session)) closeTab(_tabs.indexOf(session));
  }

  /// The window is closing (the close button, Logo+W): true to let it close. When a program
  /// other than the shell runs in any tab, asks first ("Do you want to terminate running
  /// processes in this window?") and keeps the window open if the answer is no.
  Future<bool> requestCloseWindow() async {
    if (_confirming != null || _confirmingWindow != null) return false;
    var running = false;
    for (final tab in List.of(_tabs)) {
      if (await tab.hasForegroundProcess()) {
        running = true;
        break;
      }
    }
    if (!running || !mounted) return true;
    final answer = Completer<bool>();
    setState(() => _confirmingWindow = answer);
    return answer.future;
  }

  void _answerClose(bool terminate) {
    final window = _confirmingWindow;
    if (window != null) {
      setState(() => _confirmingWindow = null);
      window.complete(terminate);
      if (!terminate && !_finding) _gridFocus.requestFocus();
      return;
    }
    final session = _confirming;
    setState(() => _confirming = null);
    if (terminate && session != null && _tabs.contains(session)) {
      closeTab(_tabs.indexOf(session));
    }
    if (!_finding) _gridFocus.requestFocus();
  }

  Widget _confirmOverlay() => Positioned.fill(
    key: const ValueKey('close confirmation'),
    child: ColoredBox(
      // Assumption: not measured (the kit draws no scrim behind an app's alert).
      color: const Color(0x33000000),
      child: Center(
        child: AmalfiAlert(
          title: _confirmingWindow != null
              ? l10n.closeWindowConfirmTitle
              : l10n.closeTabConfirmTitle,
          message: _confirmingWindow != null
              ? l10n.closeWindowConfirmMessage
              : l10n.closeTabConfirmMessage,
          actions: [
            AmalfiPushButton(
              label: l10n.cancel,
              onPressed: () => _answerClose(false),
            ),
            AmalfiPushButton(
              label: l10n.terminate,
              variant: AmalfiPushButtonVariant.destructive,
              onPressed: () => _answerClose(true),
            ),
          ],
        ),
      ),
    ),
  );

  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _current = index);
    _hadSelection = session.controller.selection != null;
    _endFind();
    _gridFocus.requestFocus();
  }

  void _step(int by) {
    if (_tabs.length < 2) return;
    selectTab((_current + by) % _tabs.length);
  }

  bool _hadSelection = false;

  /// The selection of the current tab came or went: Copy and the find items follow it.
  void _selectionChanged() {
    if (!mounted || _tabs.isEmpty) return;
    final has = session.controller.selection != null;
    if (has == _hadSelection) return;
    _hadSelection = has;
    _changed();
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

  /// The find bar adds 32 pt to the window, the grid keeps its size (terminal.md › Find bar).
  void _growForFind(bool grow) {
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null) return;
    final by = grow ? findBarHeight : -findBarHeight;
    SilicaWindow.setSize(Size(size.width, size.height + by)).ignore();
  }

  void _startFind() {
    if (!_finding) _growForFind(true);
    setState(() => _finding = true);
    _queryFocus.requestFocus();
    _runFind();
  }

  void _endFind() {
    _highlights?.clear();
    _highlights = null;
    if (!_finding) return;
    _growForFind(false);
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
      ..show(matches, _match, profileOf(context).theme(active: _windowActive));
  }

  @override
  Widget build(BuildContext context) {
    final profile = profileOf(context);
    final colors = AmalfiTheme.of(context).colors;
    if (_tabs.isEmpty) {
      return ColoredBox(color: colors.surfaceWindow);
    }
    final s = session;
    final content = Actions(
      actions: {
        _StepTabIntent: CallbackAction<_StepTabIntent>(
          onInvoke: (intent) => _step(intent.by),
        ),
      },
      child: Shortcuts(
        shortcuts: windowShortcuts,
        child: AmalfiWindow(
          // The compositor draws the window shadow.
          shadow: false,
          active: _windowActive,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titleBand(colors),
              _tabBar(colors),
              if (_finding) _findBar(colors, profile),
              Expanded(
                child: AmalfiScrollbar(
                  key: const ValueKey('scroller'),
                  child: TerminalView(
                    s.terminal,
                    key: ObjectKey(s),
                    controller: s.controller,
                    scrollController: _scroll,
                    padding: gridPadding,
                    theme: profile.theme(active: _windowActive),
                    textStyle: terminalStyle,
                    focusNode: _gridFocus,
                    onKeyEvent: _logoKey,
                    autofocus: true,
                    cursorType: TerminalCursorType.block,
                    shortcuts: {...gridShortcuts, ...windowShortcuts},
                    hardwareKeyboardOnly: true,
                    keyboardAppearance: AmalfiTheme.of(context).brightness,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return SilicaMenuBar(
      menus: menus(AppLocalizations.of(context)),
      child: _confirming == null && _confirmingWindow == null
          ? content
          : Stack(fit: StackFit.expand, children: [content, _confirmOverlay()]),
    );
  }

  /// ⌘ belongs to the app, never to the program: the grid takes the key first, so the menu
  /// bar's shortcuts are run here (the bar binds them for the rest of the window).
  KeyEventResult _logoKey(FocusNode node, KeyEvent event) {
    if (!HardwareKeyboard.instance.isMetaPressed) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      final bindings = silicaMenuShortcuts(menus(AppLocalizations.of(context)));
      for (final entry in bindings.entries) {
        if (entry.key.accepts(event, HardwareKeyboard.instance)) {
          entry.value();
          break;
        }
      }
    }
    return KeyEventResult.handled;
  }

  /// Runs a text editing intent (copy, paste, select all) on the grid, as its own shortcut.
  void _inGrid(Intent intent) {
    final context = _gridFocus.context;
    if (context != null) Actions.maybeInvoke(context, intent);
  }

  void _scrollBy(double by) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    _scroll.jumpTo((p.pixels + by).clamp(p.minScrollExtent, p.maxScrollExtent));
  }

  void _scrollToEdge({required bool top}) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    _scroll.jumpTo(top ? p.minScrollExtent : p.maxScrollExtent);
  }

  /// Find › Use Selection for Find: the selected text becomes the query.
  void _useSelectionForFind() {
    final selection = session.controller.selection;
    if (selection == null) return;
    _query.text = session.terminal.buffer.getText(selection);
    _startFind();
  }

  /// The profile the menus offer: Terminal has the one (light and dark follow the appearance).
  static const String _profile = 'Basic';

  /// The menus in Silica's menu bar (silica-desktop#25; terminal.md › Menus): the app menu,
  /// Shell, Edit, View, Window and Help. What the app cannot do yet is shown disabled, as the
  /// reference does for unavailable items; see docs/spec.md › Menus.
  List<PlatformMenuItem> menus(AppLocalizations l) {
    SingleActivator cmd(
      LogicalKeyboardKey key, {
      bool shift = false,
      bool alt = false,
      bool ctrl = false,
    }) =>
        SingleActivator(key, meta: true, shift: shift, alt: alt, control: ctrl);
    // An item without an action is drawn disabled.
    SilicaMenuItem off(String label, [MenuSerializableShortcut? shortcut]) =>
        SilicaMenuItem(label: label, shortcut: shortcut);
    PlatformMenuItemGroup group(List<PlatformMenuItem> members) =>
        PlatformMenuItemGroup(members: members);
    PlatformMenuItemGroup profiles(String sub, String same, VoidCallback run) =>
        group([
          SilicaMenuItem(
            label: sub,
            shortcut: cmd(LogicalKeyboardKey.keyT),
            onSelected: run,
          ),
          SilicaMenuItem(
            label: same,
            shortcut: cmd(LogicalKeyboardKey.keyT, ctrl: true),
            onSelected: run,
          ),
        ]);

    final hasSelection =
        _tabs.isNotEmpty && session.controller.selection != null;
    final tabs = _tabs.length;
    final canFind = _finding && _matches.isNotEmpty;
    final home = LogicalKeyboardKey.home;
    final end = LogicalKeyboardKey.end;
    final pageUp = LogicalKeyboardKey.pageUp;
    final pageDown = LogicalKeyboardKey.pageDown;

    return [
      SilicaMenus.app(l.appTitle, items: [off(l.secureKeyboardEntry)]),
      SilicaMenu(
        label: l.menuShell,
        menus: [
          group([
            SilicaMenu(
              label: l.newWindow,
              enabled: false,
              menus: [
                group([
                  off(
                    l.newWindowWithProfile(_profile),
                    cmd(LogicalKeyboardKey.keyN),
                  ),
                  off(
                    l.newWindowSameCommand,
                    cmd(LogicalKeyboardKey.keyN, ctrl: true),
                  ),
                ]),
                group([off(_profile)]),
              ],
            ),
            SilicaMenu(
              label: l.newTab,
              menus: [
                profiles(
                  l.newTabWithProfile(_profile),
                  l.newTabSameCommand,
                  newTab,
                ),
                group([SilicaMenuItem(label: _profile, onSelected: newTab)]),
              ],
            ),
            off(l.newCommand, cmd(LogicalKeyboardKey.keyN, shift: true)),
            off(
              l.newRemoteConnection,
              cmd(LogicalKeyboardKey.keyK, shift: true),
            ),
            off(l.open, cmd(LogicalKeyboardKey.keyO)),
          ]),
          group([
            // ⌘W closes the tab, and the window with the last one (as asked about running
            // programs); a system Close item would end the window without asking.
            SilicaMenuItem(
              label: tabs > 1 ? l.closeTab : l.closeWindow,
              shortcut: cmd(LogicalKeyboardKey.keyW),
              onSelected: () => unawaited(requestCloseTab()),
            ),
            off(l.closeAll, cmd(LogicalKeyboardKey.keyW, alt: true)),
          ]),
          group([off(l.useSettingsAsDefault), off(l.exportSettings)]),
          group([
            off(l.exportText, cmd(LogicalKeyboardKey.keyS)),
            off(
              l.exportSelectedText,
              cmd(LogicalKeyboardKey.keyS, shift: true),
            ),
          ]),
          group([
            off(l.showInspector, cmd(LogicalKeyboardKey.keyI)),
            off(l.editTitle, cmd(LogicalKeyboardKey.keyI, shift: true)),
            off(l.editBackgroundColor, cmd(LogicalKeyboardKey.keyI, alt: true)),
          ]),
          group([
            off(l.reset, cmd(LogicalKeyboardKey.keyR, alt: true)),
            off(
              l.hardReset,
              cmd(LogicalKeyboardKey.keyR, alt: true, ctrl: true),
            ),
          ]),
          group([
            off(l.printSelection, cmd(LogicalKeyboardKey.keyP, alt: true)),
          ]),
          group([off(l.print, cmd(LogicalKeyboardKey.keyP))]),
        ],
      ),
      SilicaMenu(
        label: l.menuEdit,
        menus: [
          group([
            const SilicaMenuItem(role: SilicaMenuItemRole.undo, enabled: false),
            const SilicaMenuItem(role: SilicaMenuItemRole.redo, enabled: false),
          ]),
          group([
            const SilicaMenuItem(role: SilicaMenuItemRole.cut, enabled: false),
            SilicaMenuItem(
              role: SilicaMenuItemRole.copy,
              shortcut: cmd(LogicalKeyboardKey.keyC),
              enabled: hasSelection,
              onSelected: () => _inGrid(CopySelectionTextIntent.copy),
            ),
            SilicaMenu(
              label: l.copySpecial,
              menus: [
                group([
                  off(
                    l.copyWithoutBackground,
                    cmd(LogicalKeyboardKey.keyC, ctrl: true, shift: true),
                  ),
                  off(
                    l.copyTextOnly,
                    cmd(LogicalKeyboardKey.keyC, alt: true, shift: true),
                  ),
                ]),
                group([
                  off(l.copyStyle),
                  SilicaMenuItem(
                    label: l.terminalSettingsDefault,
                    checked: true,
                  ),
                  off(l.plainText),
                  off(_profile),
                ]),
              ],
            ),
            SilicaMenuItem(
              role: SilicaMenuItemRole.paste,
              shortcut: cmd(LogicalKeyboardKey.keyV),
              onSelected: () => _inGrid(
                const PasteTextIntent(SelectionChangedCause.keyboard),
              ),
            ),
            off(l.pasteEscaped, cmd(LogicalKeyboardKey.keyV, ctrl: true)),
            off(l.pasteSelection, cmd(LogicalKeyboardKey.keyV, shift: true)),
            off(
              l.pasteSelectionEscaped,
              cmd(LogicalKeyboardKey.keyV, ctrl: true, shift: true),
            ),
            SilicaMenuItem(
              role: SilicaMenuItemRole.selectAll,
              shortcut: cmd(LogicalKeyboardKey.keyA),
              onSelected: () => _inGrid(
                const SelectAllTextIntent(SelectionChangedCause.keyboard),
              ),
            ),
            off(
              l.selectBetweenMarks,
              cmd(LogicalKeyboardKey.keyA, shift: true),
            ),
          ]),
          group([
            SilicaMenu(
              label: l.marks,
              menus: [
                group([
                  SilicaMenuItem(label: l.autoMarkPrompts, checked: true),
                ]),
                group([off(l.markLineAndNewline), off(l.newlineWithoutMark)]),
                group([
                  off(l.mark, cmd(LogicalKeyboardKey.keyU)),
                  off(
                    l.markAsBookmark,
                    cmd(LogicalKeyboardKey.keyU, alt: true),
                  ),
                  off(l.removeMark, cmd(LogicalKeyboardKey.keyU, shift: true)),
                ]),
              ],
            ),
            SilicaMenu(
              label: l.bookmarks,
              menus: [
                group([
                  off(
                    l.insertBookmark,
                    cmd(LogicalKeyboardKey.keyM, shift: true),
                  ),
                  off(
                    l.insertNamedBookmark,
                    cmd(LogicalKeyboardKey.keyM, shift: true, alt: true),
                  ),
                ]),
                group([off(l.noBookmarks)]),
              ],
            ),
            SilicaMenu(
              label: l.navigate,
              menus: [
                off(l.previousMark, cmd(LogicalKeyboardKey.arrowUp)),
                off(
                  l.selectToPreviousMark,
                  cmd(LogicalKeyboardKey.arrowUp, shift: true),
                ),
                off(l.nextMark, cmd(LogicalKeyboardKey.arrowDown)),
                off(
                  l.selectToNextMark,
                  cmd(LogicalKeyboardKey.arrowDown, shift: true),
                ),
                off(
                  l.previousBookmark,
                  cmd(LogicalKeyboardKey.arrowUp, alt: true),
                ),
                off(
                  l.selectToPreviousBookmark,
                  cmd(LogicalKeyboardKey.arrowUp, alt: true, shift: true),
                ),
                off(
                  l.nextBookmark,
                  cmd(LogicalKeyboardKey.arrowDown, alt: true),
                ),
                off(
                  l.selectToNextBookmark,
                  cmd(LogicalKeyboardKey.arrowDown, alt: true, shift: true),
                ),
              ],
            ),
          ]),
          group([
            off(l.clearToPreviousMark, cmd(LogicalKeyboardKey.keyL)),
            off(
              l.clearToPreviousBookmark,
              cmd(LogicalKeyboardKey.keyL, alt: true),
            ),
            off(l.clearToStart, cmd(LogicalKeyboardKey.keyK)),
          ]),
          group([
            off(l.removeExcessLines, cmd(LogicalKeyboardKey.keyK, alt: true)),
            off(l.clearScreen, cmd(LogicalKeyboardKey.keyL, ctrl: true)),
            off(
              l.fillScreen,
              cmd(LogicalKeyboardKey.keyL, ctrl: true, alt: true),
            ),
          ]),
          group([
            SilicaMenu(
              label: l.find,
              menus: [
                group([
                  SilicaMenuItem(
                    label: l.findEllipsis,
                    shortcut: cmd(LogicalKeyboardKey.keyF),
                    onSelected: _startFind,
                  ),
                  SilicaMenuItem(
                    label: l.findNextItem,
                    shortcut: cmd(LogicalKeyboardKey.keyG),
                    enabled: canFind,
                    onSelected: () => _runFind(step: 1),
                  ),
                  SilicaMenuItem(
                    label: l.findPreviousItem,
                    shortcut: cmd(LogicalKeyboardKey.keyG, shift: true),
                    enabled: canFind,
                    onSelected: () => _runFind(step: -1),
                  ),
                ]),
                group([off(l.findSelectAll), off(l.findSelectAllInSelection)]),
                group([
                  SilicaMenuItem(
                    label: l.hideFindBar,
                    shortcut: cmd(LogicalKeyboardKey.keyF, shift: true),
                    enabled: _finding,
                    onSelected: _endFind,
                  ),
                ]),
                group([
                  SilicaMenuItem(
                    label: l.useSelectionForFind,
                    shortcut: cmd(LogicalKeyboardKey.keyE),
                    enabled: hasSelection,
                    onSelected: _useSelectionForFind,
                  ),
                  off(l.jumpToSelection, cmd(LogicalKeyboardKey.keyJ)),
                ]),
              ],
            ),
          ]),
          group([off(l.showColors, cmd(LogicalKeyboardKey.keyC, shift: true))]),
          group([
            off(l.optionAsMeta, cmd(LogicalKeyboardKey.keyO, alt: true)),
            off(l.numLock),
          ]),
        ],
      ),
      SilicaMenu(
        label: l.menuView,
        menus: [
          group([
            off(l.showAllTabs),
            off(l.showTabBar, cmd(LogicalKeyboardKey.keyT, shift: true)),
            off(l.hideMarks),
          ]),
          group([
            off(l.showAlternateScreen, cmd(pageDown, shift: true)),
            off(l.hideAlternateScreen, cmd(pageUp, shift: true)),
          ]),
          group([
            SilicaMenuItem(
              label: l.allowMouseReporting,
              shortcut: cmd(LogicalKeyboardKey.keyR),
              checked: true,
            ),
          ]),
          group([
            off(l.splitPane, cmd(LogicalKeyboardKey.keyD)),
            off(l.closeSplitPane, cmd(LogicalKeyboardKey.keyD, shift: true)),
          ]),
          group([
            off(l.defaultFontSize, cmd(LogicalKeyboardKey.digit0)),
            SilicaMenuItem(
              label: l.fontBigger,
              shortcut: const CharacterActivator('+', meta: true),
            ),
            SilicaMenuItem(
              label: l.fontSmaller,
              shortcut: const CharacterActivator('-', meta: true),
            ),
          ]),
          group([
            SilicaMenuItem(
              label: l.scrollToTop,
              shortcut: cmd(home),
              onSelected: () => _scrollToEdge(top: true),
            ),
            SilicaMenuItem(
              label: l.scrollToBottom,
              shortcut: cmd(end),
              onSelected: () => _scrollToEdge(top: false),
            ),
          ]),
          group([
            SilicaMenuItem(
              label: l.pageUp,
              shortcut: cmd(pageUp),
              onSelected: () => _scrollBy(
                _scroll.hasClients ? -_scroll.position.viewportDimension : 0,
              ),
            ),
            SilicaMenuItem(
              label: l.pageDown,
              shortcut: cmd(pageDown),
              onSelected: () => _scrollBy(
                _scroll.hasClients ? _scroll.position.viewportDimension : 0,
              ),
            ),
          ]),
          group([
            SilicaMenuItem(
              label: l.lineUp,
              shortcut: cmd(pageUp, alt: true),
              onSelected: () => _scrollBy(-cellSize.height),
            ),
            SilicaMenuItem(
              label: l.lineDown,
              shortcut: cmd(pageDown, alt: true),
              onSelected: () => _scrollBy(cellSize.height),
            ),
          ]),
          group([SilicaMenuItem.system(SilicaMenuItemRole.fullScreen)]),
        ],
      ),
      SilicaMenus.window(
        l.menuWindow,
        items: [
          group([
            SilicaMenuItem(
              label: l.showPreviousTab,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.tab,
                control: true,
                shift: true,
              ),
              enabled: tabs > 1,
              onSelected: () => _step(-1),
            ),
            SilicaMenuItem(
              label: l.showNextTab,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.tab,
                control: true,
              ),
              enabled: tabs > 1,
              onSelected: () => _step(1),
            ),
            off(l.moveTabToNewWindow),
            off(l.mergeAllWindows),
          ]),
          group([
            SilicaMenu(
              label: l.openWindowGroup,
              menus: [off(l.noWindowGroups)],
            ),
            off(l.saveWindowsAsGroup),
          ]),
        ],
      ),
      SilicaMenus.help(
        l.menuHelp,
        items: [
          group([
            off(
              l.openManPage,
              const CharacterActivator('?', meta: true, control: true),
            ),
            off(
              l.searchManIndex,
              const CharacterActivator(
                "'",
                meta: true,
                control: true,
                alt: true,
              ),
            ),
          ]),
        ],
      ),
    ];
  }

  /// The title band: the centred title (headline); the window controls are the compositor's.
  Widget _titleBand(AmalfiColors colors) => WindowDragArea(
    child: SizedBox(
      key: const ValueKey('title band'),
      height: titleBarHeight,
      child: Stack(
        children: [
          Positioned(
            left: titleInset,
            right: titleInset,
            top:
                (titleBarHeight - (AmalfiType.headlineToken.lineHeight ?? 18)) /
                2,
            child: Text(
              _title,
              key: const ValueKey('title'),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AmalfiType.headline(
                color: _windowActive ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// The tab bar (kit `Apps/Terminal/Tab Bar *`): 36 pt, tabs 28 pt from x +8 sharing the
  /// width, the round 28 pt "+" 8 pt from the right edge, the separator on the last point.
  Widget _tabBar(AmalfiColors colors) => SizedBox(
    key: const ValueKey('tab bar'),
    height: tabBarHeight,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: tabBarLeft,
          right: newTabRight + newTabSide + tabsToNewTab - tabGap,
          top: tabTop,
          height: tabHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([for (final s in _slots) s.presence]),
            builder: (context, _) =>
                LayoutBuilder(builder: (context, box) => _tabRow(box.maxWidth)),
          ),
        ),
        Positioned(
          right: newTabRight,
          top: newTabTop,
          width: newTabSide,
          height: newTabSide,
          child: AmalfiIconButton(
            key: const ValueKey('new tab'),
            icon: const AmalfiGlyph(AmalfiGlyphs.plus),
            onPressed: newTab,
            semanticLabel: l10n.newTab,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1,
          child: ColoredBox(color: colors.lineSeparator),
        ),
      ],
    ),
  );

  Widget _tabRow(double width) {
    const curve = Curves.easeOutCubic;
    final weights = [
      for (final slot in _slots) curve.transform(slot.presence.value),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();
    final widths = tabWidths(
      width: width,
      weights: weights,
      selected: [
        for (final slot in _slots)
          _tabs.indexOf(slot.session) == _current && !slot.closing,
      ].indexOf(true),
    );
    return Row(
      children: [
        for (var i = 0; i < _slots.length; i++)
          SizedBox(width: widths[i], child: _tab(_slots[i])),
      ],
    );
  }

  /// One tab (`AmalfiTab`: the selected one raised, the × on the selected and the hovered
  /// one), [tabGap] kept at its trailing side.
  Widget _tab(_TabSlot slot) {
    final index = _tabs.indexOf(slot.session);
    final selected = index == _current && !slot.closing;
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: tabGap),
        child: AmalfiTab(
          key: index < 0 ? null : ValueKey('tab $index'),
          label: slot.session.title,
          selected: selected,
          width: null,
          closeLabel: l10n.closeTab,
          onSelect: index < 0 ? null : () => selectTab(index),
          onClose: index < 0 || slot.closing
              ? null
              : () => requestCloseTab(index),
        ),
      ),
    );
  }

  /// Esc closes the find bar, Enter and Shift+Enter step through the matches.
  KeyEventResult _findKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _endFind();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _runFind(step: HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The find bar (kit `Apps/Terminal/Find Bar`, 32 pt): the search field (small, 480 in a
  /// 640 window) at x +8, the previous/next segments 56 x 24 and "Done" 56 x 24, the match
  /// count before the segments, the separator on the last point.
  Widget _findBar(AmalfiColors colors, Profile profile) {
    final status = _query.text.isEmpty
        ? ''
        : _matches.isEmpty
        ? l10n.findNoMatches
        : l10n.findMatches(_match + 1, _matches.length);
    return SizedBox(
      key: const ValueKey('find bar'),
      height: findBarHeight,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              // 16 between the field and the segments, 20 before "Done", 4 at the edge.
              const fixed =
                  findFieldLeft +
                  16 +
                  findSegmentsWidth +
                  20 +
                  findDoneWidth +
                  findRight;
              final room = box.maxWidth - fixed - (status.isEmpty ? 0 : 96);
              final field = room.clamp(80.0, findFieldWidth).toDouble();
              return Padding(
                padding: const EdgeInsets.only(left: findFieldLeft, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AmalfiSearchField(
                      key: const ValueKey('find field'),
                      controller: _query,
                      focusNode: _queryFocus,
                      placeholder: l10n.find,
                      size: AmalfiFieldSize.small,
                      width: field,
                      onChanged: (_) => _runFind(),
                      semanticLabel: l10n.find,
                    ),
                    const SizedBox(width: 16),
                    if (status.isNotEmpty)
                      SizedBox(
                        width: 96,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            status,
                            key: const ValueKey('find status'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmalfiType.caption(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: findSegmentsWidth,
                      height: findControlHeight,
                      child: AmalfiActionSegments(
                        size: AmalfiControlSize.small,
                        segments: [
                          AmalfiSegment.icon(
                            const AmalfiGlyph(AmalfiGlyphs.chevronLeft),
                            semanticLabel: l10n.findPrevious,
                          ),
                          AmalfiSegment.icon(
                            const AmalfiGlyph(AmalfiGlyphs.chevronRight),
                            semanticLabel: l10n.findNext,
                          ),
                        ],
                        onPressed: (i) => _runFind(step: i == 0 ? -1 : 1),
                      ),
                    ),
                    const SizedBox(width: 20),
                    AmalfiPushButton(
                      key: const ValueKey('find done'),
                      label: l10n.findDone,
                      size: AmalfiControlSize.small,
                      onPressed: _endFind,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 1,
            child: ColoredBox(color: colors.lineSeparator),
          ),
        ],
      ),
    );
  }
}
