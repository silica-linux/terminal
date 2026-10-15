# Changelog

## Unreleased

- Closing the window (Logo+W, the close button) with a program running in any tab asks first:
  "Do you want to terminate running processes in this window?" (silica_ui 0.35.0
  `SilicaWindows.onMainCloseRequested`; needs silica-desktop with `closeRequested` for the main
  window).

- Menus in Silica's menu bar (silica_ui 0.34.0 `SilicaMenuBar`, silica-menu-v1): Terminal, Shell,
  Edit, View, Window and Help as measured in TE-01. New Tab, Close Tab, Copy, Paste, Select All,
  Find (next, previous, hide, use selection), scrolling and tab switching are wired; the items
  whose feature does not exist yet are shown disabled. The ⌘ shortcuts are bound by the menu
  bar, also while the grid has the keyboard.

## 0.1.0 · 2026-10-14

- First version: the login shell on the `silica/pty` pseudo-terminal of the Silica embedder,
  xterm.dart as the emulator, title with the program and the size, tabs, find, copy and paste,
  light and dark profiles, English and Italian. Geometry and colours are provisional until
  TE-01 is measured.
