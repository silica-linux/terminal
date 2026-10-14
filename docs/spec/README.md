# Terminal · public specification

This folder describes how the terminal app of the reference system (macOS 27) looks and
behaves, as observed by measurement. Silica follows a clean-room process: the observations
were made on a real machine and are restated here in our own words, with the numbers that
came out of them. The raw material (screenshots, screen recordings, accessibility dumps,
session notes) stays in the private repository `silica-reference` and is not reproduced here.

## Conventions

- **IDs.** `TE-01` names the measurement session of this app; `ST-APPSET-05` to `-07` are
  the rows of the settings inventory that cover this app's settings window.
- **Units.** Lengths are points at 1× (1 pt = 1 px on the reference display). Positions are
  measured from the top-left corner of the window unless a table says otherwise.
- **Colours.** sRGB hex. Neutral grays were read directly; saturated colours were converted
  from the display profile to sRGB, and only the sRGB value is given.
- **Timing.** Recorded at 75 Hz: one frame is 13.3 ms, which is also the precision of every
  time given here. Times are counted from the input event named in each table.
- **Status.** Values marked *provisional* are estimates or single readings that need a
  second look; items marked *unmeasured* were not observed at all.
- **Labels.** English, matching `lib/l10n/app_en.arb` where the app already has a string.
  They name controls; they are not quotations of the reference interface.

## Reference conditions

Display 2560 × 1440 at 1×, 75 Hz, solid mid-gray wallpaper. A fresh window with the
default profile, an empty test folder and a plain `$ ` prompt. Light and dark appearance
were both captured for the window, colours, selection and inactive state; tabs, split,
find bar and the inspector were captured in light only.

## Files

| File | Covers |
| --- | --- |
| [window.md](window.md) | Default size, cell grid, insets, size formulas, resizing |
| [title-and-tabs.md](title-and-tabs.md) | Title bar, always-visible tab bar, tabs, tab animations |
| [colors.md](colors.md) | Default colour scheme (light / dark), ANSI palette, selection, text attributes |
| [cursor.md](cursor.md) | Cursor shapes, inactive cursor, blinking |
| [scrolling.md](scrolling.md) | Scroller, scrollback, output and typing latency |
| [split-and-find.md](split-and-find.md) | Split view and find bar |
| [inspector.md](inspector.md) | Inspector panel |
| [settings.md](settings.md) | Settings window, preset colour schemes, defaults (ST-APPSET-05..07) |
| [menus.md](menus.md) | Menu bar structure and shortcuts |
| [diagrams/window-geometry.svg](diagrams/window-geometry.svg) | Default window: bars, insets, cell grid |
