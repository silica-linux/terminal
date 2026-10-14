// The terminal emulated by the embedder (`spawn(grid: true)`): the app keeps only the visible
// rows as runs of text and paints them with one CustomPainter. Parsing escape sequences happens
// in Rust (alacritty_terminal) off the UI thread, and only changed rows arrive, once per frame;
// each row's Paragraph is cached until the row changes, so a frame costs the changed rows.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'keys.dart';
import 'pty.dart';

/// One run of cells with the same attributes. Colours are 0xRRGGBB, -1 for the default.
@immutable
class GridRun {
  const GridRun(this.text, this.fg, this.bg, this.flags);
  final String text;
  final int fg;
  final int bg;
  final int flags;

  bool get bold => flags & 1 != 0;
  bool get italic => flags & 2 != 0;
  bool get underline => flags & 4 != 0;
  bool get inverse => flags & 8 != 0;
  bool get dim => flags & 16 != 0;
  bool get strikeout => flags & 32 != 0;
  bool get curly => flags & 64 != 0;
  bool get hidden => flags & 128 != 0;
}

/// A visible row: its runs.
class GridRow {
  GridRow(this.runs);
  final List<GridRun> runs;
  static final GridRow empty = GridRow(const []);

  /// The content as a key: a row that scrolls to another line keeps its painted paragraph.
  late final String key = [
    for (final r in runs) '${r.fg},${r.bg},${r.flags}\u0001${r.text}',
  ].join('\u0000');
}

/// The state of the emulated terminal as the embedder reports it.
class GridState extends ChangeNotifier {
  int cols = 80;
  int rows = 24;
  List<GridRow> lines = List.filled(24, GridRow.empty);
  int cursorX = 0;
  int cursorY = 0;
  bool cursorVisible = true;
  String cursorShape = 'block';
  TerminalModes modes = TerminalModes.none;
  String? title;

  /// Applies one `grid` message.
  void apply(Map<Object?, Object?> frame) {
    final c = frame['cols'];
    final r = frame['rows'];
    if (c is int &&
        r is int &&
        (c != cols || r != rows || frame['full'] == true)) {
      cols = c;
      rows = r;
      lines = List.filled(r, GridRow.empty, growable: false);
    }
    final changed = frame['lines'];
    if (changed is List) {
      for (final line in changed) {
        if (line is! Map) continue;
        final y = line['y'];
        final runs = line['runs'];
        if (y is! int || y < 0 || y >= lines.length || runs is! List) continue;
        lines[y] = GridRow([
          for (final run in runs)
            if (run is List && run.length == 4)
              GridRun(
                run[0] is String ? run[0] as String : '',
                run[1] is int ? run[1] as int : -1,
                run[2] is int ? run[2] as int : -1,
                run[3] is int ? run[3] as int : 0,
              ),
        ]);
      }
    }
    final cursor = frame['cursor'];
    if (cursor is Map) {
      cursorX = cursor['x'] is int ? cursor['x'] as int : cursorX;
      cursorY = cursor['y'] is int ? cursor['y'] as int : cursorY;
      cursorVisible = cursor['visible'] != false;
      cursorShape = cursor['shape'] is String
          ? cursor['shape'] as String
          : 'block';
    }
    final m = frame['modes'];
    if (m is int) modes = TerminalModes(m);
    final t = frame['title'];
    if (t is String) title = t;
    notifyListeners();
  }

  /// The visible text (tests, accessibility).
  String get text =>
      lines.map((l) => l.runs.map((r) => r.text).join()).join('\n');
}

/// A pseudo-terminal session in grid mode.
class GridSession {
  GridSession({required this.pty, this.command});

  final PtyBackend pty;
  final List<String>? command;
  final GridState state = GridState();
  int? _id;
  StreamSubscription<PtyEvent>? _events;
  bool ended = false;

  Future<void> start({required int rows, required int cols}) async {
    _events = pty.events.listen((event) {
      if (event.id != _id) return;
      switch (event) {
        case PtyGrid(:final frame):
          state.apply(frame);
        case PtyExit():
          ended = true;
        case PtyOutput():
          break;
      }
    });
    _id = await pty.spawn(
      command: command,
      env: const {'TERM_PROGRAM': 'Silica Terminal'},
      rows: rows,
      cols: cols,
      grid: true,
    );
  }

  void write(String text) {
    final id = _id;
    if (id == null || ended) return;
    pty.write(id, Uint8List.fromList(utf8.encode(text))).ignore();
  }

  void resize(int rows, int cols) {
    final id = _id;
    if (id == null || ended) return;
    pty.resize(id, rows: rows, cols: cols).ignore();
  }

  void dispose() {
    _events?.cancel();
    final id = _id;
    if (id != null && !ended) pty.close(id).ignore();
  }
}

/// Colours of the grid.
@immutable
class GridPalette {
  const GridPalette({
    required this.foreground,
    required this.background,
    required this.cursor,
  });
  final Color foreground;
  final Color background;
  final Color cursor;
}

/// The terminal grid: keys in, rows painted. Size follows the layout (cell 7 × 14 pt).
class GridTerminalView extends StatefulWidget {
  const GridTerminalView({
    super.key,
    required this.session,
    required this.palette,
    required this.textStyle,
    this.cellWidth = 7,
    this.cellHeight = 14,
    this.padding = EdgeInsets.zero,
    this.optionAsMeta = false,
    this.autofocus = true,
  });

  final GridSession session;
  final GridPalette palette;
  final TextStyle textStyle;
  final double cellWidth;
  final double cellHeight;
  final EdgeInsets padding;
  final bool optionAsMeta;
  final bool autofocus;

  @override
  State<GridTerminalView> createState() => _GridTerminalViewState();
}

class _GridTerminalViewState extends State<GridTerminalView> {
  final FocusNode _focus = FocusNode(debugLabel: 'grid');
  (int, int)? _size;
  bool _started = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final bytes = encodeKey(
      event,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
      control: keyboard.isControlPressed,
      meta: keyboard.isMetaPressed,
      modes: widget.session.state.modes,
      optionAsMeta: widget.optionAsMeta,
    );
    if (bytes == null) return KeyEventResult.ignored;
    widget.session.write(bytes);
    return KeyEventResult.handled;
  }

  void _layout(Size size) {
    final inner = widget.padding.deflateSize(size);
    final cols = (inner.width / widget.cellWidth).floor().clamp(1, 1000);
    final rows = (inner.height / widget.cellHeight).floor().clamp(1, 1000);
    if (_size == (rows, cols)) return;
    _size = (rows, cols);
    if (!_started) {
      _started = true;
      widget.session.start(rows: rows, cols: cols).ignore();
    } else {
      widget.session.resize(rows, cols);
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: widget.autofocus,
    onKeyEvent: _key,
    child: LayoutBuilder(
      builder: (context, box) {
        _layout(box.biggest);
        return GestureDetector(
          onTap: _focus.requestFocus,
          child: RepaintBoundary(
            child: CustomPaint(
              size: box.biggest,
              painter: GridPainter(
                widget.session.state,
                palette: widget.palette,
                style: widget.textStyle,
                cellWidth: widget.cellWidth,
                cellHeight: widget.cellHeight,
                padding: widget.padding,
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Paints the rows: backgrounds, one cached Paragraph per row, the cursor.
class GridPainter extends CustomPainter {
  GridPainter(
    this.state, {
    required this.palette,
    required this.style,
    required this.cellWidth,
    required this.cellHeight,
    required this.padding,
  }) : super(repaint: state);

  final GridState state;
  final GridPalette palette;
  final TextStyle style;
  final double cellWidth;
  final double cellHeight;
  final EdgeInsets padding;

  /// Paragraphs by row content (least recently used first): rows that only moved, as when
  /// output scrolls, are not laid out again.
  static final Map<String, ui.Paragraph> _cache = <String, ui.Paragraph>{};
  static const int _cacheSize = 2048;

  Color _color(int value, {required bool foreground}) {
    if (value < 0) return foreground ? palette.foreground : palette.background;
    return Color(0xff000000 | value);
  }

  ui.Paragraph _paragraph(GridRow row) {
    final cached = _cache.remove(row.key);
    if (cached != null) {
      _cache[row.key] = cached;
      return cached;
    }
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        maxLines: 1,
        height: 1,
        textHeightBehavior: const ui.TextHeightBehavior(),
      ),
    );
    for (final run in row.runs) {
      var fg = _color(run.fg, foreground: true);
      if (run.inverse) fg = _color(run.bg, foreground: false);
      if (run.dim) fg = fg.withValues(alpha: fg.a * 0.6);
      if (run.hidden) fg = const Color(0x00000000);
      builder.pushStyle(
        style
            .copyWith(
              color: fg,
              fontWeight: run.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
              decoration: TextDecoration.combine([
                if (run.underline || run.curly) TextDecoration.underline,
                if (run.strikeout) TextDecoration.lineThrough,
              ]),
              decorationStyle: run.curly ? TextDecorationStyle.wavy : null,
              decorationColor: fg,
              height: cellHeight / (style.fontSize ?? 12),
            )
            .getTextStyle(),
      );
      builder.addText(run.text);
      builder.pop();
    }
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
    _cache[row.key] = paragraph;
    if (_cache.length > _cacheSize) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest)?.dispose();
    }
    return paragraph;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    final origin = Offset(padding.left, padding.top);
    final bg = Paint();
    for (var y = 0; y < state.lines.length; y++) {
      final row = state.lines[y];
      if (row.runs.isEmpty) continue;
      final top = origin.dy + y * cellHeight;
      var x = 0;
      for (final run in row.runs) {
        final cells = run.text.runes.length;
        final color = run.inverse ? run.fg : run.bg;
        if (color >= 0 || run.inverse) {
          bg.color = _color(color, foreground: run.inverse);
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + x * cellWidth,
              top,
              cells * cellWidth,
              cellHeight,
            ),
            bg,
          );
        }
        x += cells;
      }
      canvas.drawParagraph(_paragraph(row), Offset(origin.dx, top));
    }
    if (state.cursorVisible) {
      final rect = Rect.fromLTWH(
        origin.dx + state.cursorX * cellWidth,
        origin.dy + state.cursorY * cellHeight,
        cellWidth,
        cellHeight,
      );
      final paint = Paint()..color = palette.cursor.withValues(alpha: 0.7);
      switch (state.cursorShape) {
        case 'beam':
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
            paint,
          );
        case 'underline':
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2),
            paint,
          );
        default:
          canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.state != state || old.palette != palette || old.style != style;
}
