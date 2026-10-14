// The Terminal window (TE-01, terminal.md): the 32 pt title band (the window buttons of Ossido
// sit in it, the empty band moves the window), the 28 pt tab bar always visible, the 32 pt find
// bar that grows the window, and the character grid with its scroller column.
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

/// A tab in the bar: its session and how far in it is (0 → 1 entering, 1 → 0 closing).
class _TabSlot {
  _TabSlot(this.session, this.presence);
  final TerminalSession session;
  final AnimationController presence;
  bool closing = false;
  bool hover = false;
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
  final FocusNode _queryFocus = FocusNode();
  final FocusNode _gridFocus = FocusNode();
  List<SearchMatch> _matches = const [];
  int _match = 0;

  /// The tab waiting for the answer of the "terminate running processes?" alert.
  TerminalSession? _confirming;
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
    newTab();
  }

  @override
  void dispose() {
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
    if (i < 0 || i >= _tabs.length || _confirming != null) return;
    final session = _tabs[i];
    if (await session.hasForegroundProcess()) {
      if (!mounted || !_tabs.contains(session)) return;
      setState(() => _confirming = session);
      return;
    }
    if (mounted && _tabs.contains(session)) closeTab(_tabs.indexOf(session));
  }

  void _answerClose(bool terminate) {
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
      color: const Color(0x33000000), // provisional
      child: Center(
        child: SilicaAlert(
          opaque: true,
          sideBySide: true,
          title: l10n.closeTabConfirmTitle,
          message: l10n.closeTabConfirmMessage,
          buttons: [
            AlertButton(
              l10n.cancel,
              role: AlertRole.cancel,
              onPressed: () => _answerClose(false),
            ),
            AlertButton(
              l10n.terminate,
              role: AlertRole.destructive,
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
    if (_tabs.isEmpty) {
      return ColoredBox(color: profile.grid.background);
    }
    final s = session;
    final content = Actions(
      actions: {
        _NewTabIntent: CallbackAction<_NewTabIntent>(onInvoke: (_) => newTab()),
        _CloseTabIntent: CallbackAction<_CloseTabIntent>(
          onInvoke: (_) => requestCloseTab(),
        ),
        _StepTabIntent: CallbackAction<_StepTabIntent>(
          onInvoke: (intent) => _step(intent.by),
        ),
        _FindIntent: CallbackAction<_FindIntent>(onInvoke: (_) => _startFind()),
      },
      child: Shortcuts(
        shortcuts: windowShortcuts,
        child: ColoredBox(
          color: profile.grid.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _titleBand(profile),
              _tabBar(profile),
              // Down to y 68, where the content starts under a 1 pt line.
              Container(
                height: chromeHeight - titleBarHeight - tabBarHeight,
                decoration: BoxDecoration(
                  color: profile.chrome,
                  border: Border(bottom: BorderSide(color: profile.separator)),
                ),
              ),
              if (_finding) _findBar(profile),
              Expanded(
                // The scroller column (19 pt, knob 11) sits in the right inset of the grid.
                child: RawScrollbar(
                  key: const ValueKey('scroller'),
                  controller: _scroll,
                  thumbVisibility: true,
                  trackVisibility: profile.scrollerTrack != null,
                  thickness: scrollerKnobWidth,
                  radius: const Radius.circular(scrollerKnobWidth / 2),
                  thumbColor: profile.scrollerKnob,
                  trackColor: profile.scrollerTrack,
                  trackBorderColor: const Color(0x00000000),
                  crossAxisMargin: (scrollerWidth - scrollerKnobWidth) / 2,
                  child: TerminalView(
                    s.terminal,
                    key: ObjectKey(s),
                    controller: s.controller,
                    scrollController: _scroll,
                    padding: gridPadding,
                    theme: profile.theme(active: _windowActive),
                    textStyle: terminalStyle,
                    focusNode: _gridFocus,
                    autofocus: true,
                    cursorType: TerminalCursorType.block,
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
    if (_confirming == null) return content;
    return Stack(fit: StackFit.expand, children: [content, _confirmOverlay()]);
  }

  Widget _titleBand(Profile profile) => WindowDragArea(
    child: Container(
      key: const ValueKey('title band'),
      height: titleBarHeight,
      color: profile.chrome,
      // The title starts after the window buttons and the proxy icon (AX x +100, y +8); bold
      // ~13 pt, `#595959` / `#a1a1a1`.
      padding: const EdgeInsets.only(left: 100, right: 16, top: 8),
      alignment: Alignment.topLeft,
      child: Text(
        _title,
        key: const ValueKey('title'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: uiText(
          size: 13,
          color: _windowActive ? profile.title : profile.titleInactive,
        ).copyWith(fontWeight: FontWeight.w600, height: 16 / 13),
      ),
    ),
  );

  /// The tab label: the path in grey, the process in bold ("~/src — vim").
  Widget _tabLabel(TerminalSession session, Profile profile, bool selected) {
    final title = session.title;
    final dash = title.lastIndexOf(' — ');
    final color = selected ? profile.tabText : profile.tabTextInactive;
    final base = uiText(size: 12, color: color);
    return Text.rich(
      dash < 0
          ? TextSpan(
              text: title,
              style: base.copyWith(fontWeight: FontWeight.w600),
            )
          : TextSpan(
              children: [
                TextSpan(
                  text: title.substring(0, dash + 3),
                  style: base.copyWith(color: profile.tabTextInactive),
                ),
                TextSpan(
                  text: title.substring(dash + 3),
                  style: base.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  /// The tab bar: always visible, 28 pt; capsule tabs 24 pt from x +10 sharing the width, the
  /// 30 pt "+" circle 7 pt from the right edge.
  Widget _tabBar(Profile profile) => Container(
    key: const ValueKey('tab bar'),
    height: tabBarHeight,
    color: profile.chrome,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: tabBarLeft,
          right: newTabRight + newTabSide + 5,
          top: tabTop,
          height: tabHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: profile.tabTrack,
              borderRadius: BorderRadius.circular(tabHeight / 2),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([for (final s in _slots) s.presence]),
              builder: (context, _) => LayoutBuilder(
                builder: (context, box) => _tabRow(profile, box.maxWidth),
              ),
            ),
          ),
        ),
        Positioned(
          right: newTabRight,
          top: newTabTop,
          width: newTabSide,
          height: newTabSide,
          child: GestureDetector(
            key: const ValueKey('new tab'),
            behavior: HitTestBehavior.opaque,
            onTap: newTab,
            child: Semantics(
              label: l10n.newTab,
              button: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: profile.tabTrack,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '+',
                    style: uiText(size: 18, color: profile.tabText),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabRow(Profile profile, double width) {
    const curve = Curves.easeOutCubic;
    final weights = [
      for (final slot in _slots) curve.transform(slot.presence.value),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < _slots.length; i++)
          SizedBox(
            width: width * weights[i] / total,
            child: _tab(profile, _slots[i]),
          ),
      ],
    );
  }

  Widget _tab(Profile profile, _TabSlot slot) {
    final index = _tabs.indexOf(slot.session);
    final selected = index == _current && !slot.closing;
    final canClose = index >= 0 && !slot.closing;
    return MouseRegion(
      onEnter: (_) => setState(() => slot.hover = true),
      onExit: (_) => setState(() => slot.hover = false),
      child: GestureDetector(
        key: index < 0 ? null : ValueKey('tab $index'),
        behavior: HitTestBehavior.opaque,
        onTap: index < 0 ? null : () => selectTab(index),
        child: ClipRect(
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: selected
                ? BoxDecoration(
                    color: profile.tabActive,
                    borderRadius: BorderRadius.circular((tabHeight - 2) / 2),
                  )
                : null,
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: _tabLabel(slot.session, profile, selected),
                  ),
                ),
                if (slot.hover && canClose)
                  Positioned(
                    left: tabCloseLeft - 1,
                    top: (tabHeight - 2 - tabCloseSide) / 2,
                    child: _TabCloseButton(
                      key: ValueKey('tab close $index'),
                      color: profile.tabText,
                      onPressed: () => requestCloseTab(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The find bar (32 pt): the field 482 × 22 at x +7 with a focus ring, the previous/next
  /// pair 45 × 22, the "Done" button 44 × 22, and the match count.
  Widget _findBar(Profile profile) {
    final status = _query.text.isEmpty
        ? ''
        : _matches.isEmpty
        ? l10n.findNoMatches
        : l10n.findMatches(_match + 1, _matches.length);
    Widget button(
      String key,
      String label,
      Widget child,
      VoidCallback onTap,
      double width,
    ) => GestureDetector(
      key: ValueKey(key),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        label: label,
        button: true,
        child: Container(
          width: width,
          height: findFieldSize.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: profile.tabTrack,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      ),
    );
    final glyph = uiText(size: 12, color: profile.title);
    return Container(
      key: const ValueKey('find bar'),
      height: findBarHeight,
      color: profile.chrome,
      padding: const EdgeInsets.only(left: findFieldLeft, right: 10),
      child: Row(
        children: [
          Flexible(
            child: Container(
              width: findFieldSize.width,
              height: findFieldSize.height,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: profile.grid.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: profile.findRing, width: 2),
              ),
              alignment: Alignment.centerLeft,
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
                      style: uiText(size: 12, color: profile.grid.foreground),
                      cursorColor: profile.grid.foreground,
                      backgroundCursorColor: profile.grid.foreground,
                      maxLines: 1,
                      onChanged: (_) => _runFind(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              key: const ValueKey('find status'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: uiText(size: 11, color: profile.titleInactive),
            ),
          ),
          button(
            'find previous',
            l10n.findPrevious,
            Text('‹', style: glyph),
            () => _runFind(step: -1),
            22,
          ),
          const SizedBox(width: 1),
          button(
            'find next',
            l10n.findNext,
            Text('›', style: glyph),
            () => _runFind(step: 1),
            22,
          ),
          const SizedBox(width: 8),
          button(
            'find done',
            l10n.findDone,
            Text(l10n.findDone, style: uiText(size: 11, color: profile.title)),
            _endFind,
            44,
          ),
        ],
      ),
    );
  }
}

/// The × at the leading edge of a hovered tab: 18 × 18, 4 pt from the tab edge; a round
/// highlight while pressed.
class _TabCloseButton extends StatefulWidget {
  const _TabCloseButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  State<_TabCloseButton> createState() => _TabCloseButtonState();
}

class _TabCloseButtonState extends State<_TabCloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label: l10n.closeTab,
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: Container(
        key: const ValueKey('tab close glyph'),
        width: tabCloseSide,
        height: tabCloseSide,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // provisional: highlight only while pressed
          color: _pressed ? widget.color.withValues(alpha: 0.2) : null,
        ),
        child: CustomPaint(painter: _CrossPainter(widget.color)),
      ),
    ),
  );
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth =
          1.3 // provisional
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    const arm = 3.0; // provisional
    canvas.drawLine(
      c + const Offset(-arm, -arm),
      c + const Offset(arm, arm),
      paint,
    );
    canvas.drawLine(
      c + const Offset(-arm, arm),
      c + const Offset(arm, -arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
