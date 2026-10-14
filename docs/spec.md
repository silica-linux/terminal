# Terminal: specification

Terminal runs the user's login shell (or `-e program args…`) on a pseudo-terminal of the Silica
embedder and shows it in a character grid. Measurements come from TE-01 (silica-reference#75);
until they arrive, the values in `lib/src/style.dart` are provisional.

## Window

- Full-size content (`SilicaWindow.setFullSizeContent`): a title band at the top, 32 pt
  (provisional), where Ossido puts the window buttons; the empty band moves the window
  (`WindowDragArea`).
- Title, centred in the band: the title set by the program (OSC 0/2) or the name of the shell,
  then the size in cells: "bash — 80×24". The same text goes to the window title
  (`SystemChrome.setApplicationSwitcherDescription`). Inactive window: a lighter title.
- Tab bar under the band from two tabs, 26 pt (provisional): one cell per tab, the current one
  highlighted, a click selects.
- Find bar under the tab bar while finding.
- The grid fills the rest with 6 / 4 pt of padding (provisional). The emulator follows the
  layout: every size change resizes the pseudo-terminal (rows, columns and pixels).
- Profiles: dark text on white in the light appearance, light text on `#1e1e1e` in the dark
  one (provisional, our own palette); JetBrains Mono 12 pt, line height 1.2.
- First window: 640 × 420 pt (the `--size` of the `.desktop` entry, about 80 × 24 cells).

## Emulator

xterm.dart (MIT): VT100/xterm sequences, 256 colours and true colour, alternate screen, mouse
reporting, bracketed paste, OSC title, 10 000 lines of scrollback, selection with the mouse.
Output is decoded as a UTF-8 stream (a character split between two messages arrives whole).

## Process

- `spawn` with the current grid size; `TERM_PROGRAM=Silica Terminal` in the environment.
- When the process exits, a dimmed line says how ("The process exited with code 0.") and the
  tab keeps its output; keys are no longer sent.
- Outside Silica the channel is missing: the grid says the terminal needs the Silica desktop.
- Closing a tab closes its pseudo-terminal (SIGHUP); closing the last tab closes the window.

## Commands

| Command | Shortcut | What |
| --- | --- | --- |
| `terminal.new_tab` | ⌘T | a new tab after the current one, with a new shell |
| `terminal.close_tab` | ⌘W | closes the current tab and its process |
| `terminal.next_tab` | ⌃⇥ | the next tab |
| `terminal.previous_tab` | ⌃⇧⇥ | the previous tab |
| `terminal.find` | ⌘F | the find bar: matches highlighted, Enter / ⇧Enter next and previous, Esc closes |
| `terminal.copy` | ⌘C, ⌃⇧C | copies the selection |
| `terminal.paste` | ⌘V, ⌃⇧V | pastes (bracketed when the program asks for it) |
| `terminal.select_all` | ⌘A | selects the scrollback and the screen |

⌘ is the Logo key. Plain ⌃C and ⌃V go to the program.

## Pseudo-terminal channel

`silica/pty`, JSONMethodCodec, implemented by the embedder of silica-desktop (issue #17):

- app → embedder: `spawn {command?, cwd?, env?, rows, cols}` → `{id}`; `write {id, data}`
  (base64); `resize {id, rows, cols, pixelWidth?, pixelHeight?}`; `signal {id, signal}`
  (`INT`, `TERM`, `HUP`, `KILL`); `close {id}`.
- embedder → app: `output {id, data}` (base64), `exit {id, code?, signal?}`.
