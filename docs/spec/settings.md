# Settings window

Session TE-01, inventory rows ST-APPSET-05 (general), ST-APPSET-06 (profiles) and
ST-APPSET-07 (window groups, encodings). Viewed only: no profile was created, changed or
deleted.

## Window

| Item | Value |
| --- | --- |
| Size | **671 × 628** |
| Toolbar tabs | General · Profiles · Window Groups · Encodings |
| Profiles tab | profile list on the left, rows **45** tall with a small preview; on the right, sub-tabs Text · Window · Tab · Shell · Keyboard · Advanced |

Control sizes and spacing inside the tabs: *unmeasured* (values were read, layout was not
measured).

## General (ST-APPSET-05, partial)

| Setting | Default |
| --- | --- |
| On launch | open a new window with the default profile |
| Shell for new windows | the user's default login shell |
| New windows | default profile, home as working directory |
| New tabs | same profile and same working directory as the current tab |
| Tab switching | ⌘1–⌘9 select tabs |

## Default profile (ST-APPSET-06)

| Group | Default |
| --- | --- |
| Text | monospaced Regular 11 pt; antialiasing on; bold face for bold text on; blinking text allowed; ANSI colours on; bright colours for bold off |
| Cursor | block, not blinking |
| Window title | app name plus working directory, running process with its arguments, and size |
| Window size | 80 × 24 |
| Scrollback | limited by available memory |
| Restore | text restored on reopen, up to 10,000 lines |

## Preset colour schemes (ST-APPSET-06)

The reference ships eleven preset profiles. Their names are not reused; the descriptive
names below are ours. Values are the centres of the colour wells (3 × 5 px average).

| Scheme (our name) | Background | Text | Bold | Selection | Cursor |
| --- | --- | --- | --- | --- | --- |
| Default (dynamic) | `#ffffff` (dark: `#1e1e1e`) | `#000000` | `#000000` | `#b3d7ff` | `#9d9d9d` |
| Translucent dark | `#262c38`, translucent | `#e6e6e6` | `#f0f0f0` | `#334d5f` | `#9d9d9d` |
| Translucent light | `#f6f6f6`, translucent | `#3a4851` | `#303d44` | `#e5ecf1` | `#919191` |
| Lawn | `#13773d` | `#fff0a5` | `#ffb03c` | `#b64826` | `#8e2900` |
| Phosphor | `#0d0d0d` | `#27fe13` | `#00fa00` | `#494bdb` | `#38fe26` |
| Yellow paper | `#fef49c` | `#000000` | `#000000` | `#bfb875` | `#9d9d9d` |
| Parchment | `#dfdbc3` | `#4d2e2d` | `#933a21` | `#929077` | `#665656` |
| Deep blue | `#2b66c8` | `#ffffff` | `#ffffff` | `#2886ff` | `#9d9d9d` |
| Near black | `#141414` | `#f4f4f4` | `#ffffff` | `#525252` | `#606060` |
| Brick | `#8d4136` | `#d6c9a7` | `#e5c72b` | `#3d1917` | `#ffffff` |
| Mid gray | `#8a8a8a` | `#000000` | `#ffffff` | `#787a9b` | `#e0e0e0` |

ANSI colours: every scheme uses the default palette ([colors.md](colors.md)) except the two
translucent ones:

| Scheme | Normal 0–7 | Bright 0–7 |
| --- | --- | --- |
| Translucent dark | `35424b b45647 6caa71 c4ac62 6d96b4 bd7bcd 7ccacd dee5eb` | `475c6d df6c5a 79bd7e e5c872 67b6ed d389e5 84dee0 e5eff5` |
| Translucent light | `2c3840 b45647 6caa71 c4ac62 5685a7 ad64be 6ac6ca c1c8cc` | `506573 df6c5a 79bd7e e5c872 49a2e2 d389e5 77e1e5 d8e1e7` |

- The translucent backgrounds let the desktop show through; their opacity was not read
  (*unmeasured*).
- The translucent dark scheme uses a 12 pt variant of the monospaced face made for
  terminals; all the others use the 11 pt default.

## Window Groups and Encodings (ST-APPSET-07)

Only the tab names are known: *unmeasured*.
