// Find in the scrollback: every occurrence of the text, case-insensitive, line by line (a match
// does not continue across a wrapped line). Matches are highlighted through the controller of
// the terminal view; the current one has its own colour.

import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// An occurrence: buffer line `y`, columns `x` to `x + length`.
@immutable
class SearchMatch {
  const SearchMatch(this.y, this.x, this.length);
  final int y;
  final int x;
  final int length;

  @override
  bool operator ==(Object other) =>
      other is SearchMatch &&
      other.y == y &&
      other.x == x &&
      other.length == length;

  @override
  int get hashCode => Object.hash(y, x, length);

  @override
  String toString() => 'SearchMatch($y, $x, $length)';
}

/// Every occurrence of `query` in `buffer`, top to bottom, left to right.
List<SearchMatch> findAll(Buffer buffer, String query) {
  if (query.isEmpty) return const [];
  final needle = query.toLowerCase();
  final out = <SearchMatch>[];
  for (var y = 0; y < buffer.height; y++) {
    final text = buffer.lines[y].getText().toLowerCase();
    var from = 0;
    while (true) {
      final x = text.indexOf(needle, from);
      if (x < 0) break;
      out.add(SearchMatch(y, x, needle.length));
      from = x + needle.length;
    }
  }
  return out;
}

/// The highlights of a search on one terminal: all matches, and the current one on top.
class SearchHighlights {
  SearchHighlights(this.terminal, this.controller);

  final Terminal terminal;
  final TerminalController controller;
  final List<TerminalHighlight> _highlights = [];

  void show(List<SearchMatch> matches, int current, TerminalTheme theme) {
    clear();
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      _highlights.add(
        controller.highlight(
          p1: terminal.buffer.createAnchor(m.x, m.y),
          p2: terminal.buffer.createAnchor(m.x + m.length, m.y),
          color: i == current
              ? theme.searchHitBackgroundCurrent
              : theme.searchHitBackground,
        ),
      );
    }
  }

  void clear() {
    for (final h in _highlights) {
      h.dispose();
    }
    _highlights.clear();
  }
}
