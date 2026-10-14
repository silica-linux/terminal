# AGENTS.md

Terminal is a Silica app: the rules of `silica-desktop/AGENTS.md` apply (clean-room, assets,
never crash, everything is a command, measured parity, English everywhere). On top of them:

## Clean-room

- Observations of the reference system live in the private repository `silica-reference`
  (request TE-01, silica-reference#75; measurements in `terminal.md`), never here. Here only
  the request codes and the measured numbers are cited.
- Interface texts are our own words; no product names or texts copied from the reference.
- The geometry, the default profiles and the ANSI palette are measured (TE-01, `docs/parity.md`); the names of
  the profiles are ours.

## Work

- Before every commit: `dart format`, `flutter analyze --fatal-infos`, `flutter test`,
  `tool/check_assets.sh`. One task per commit.
- Interface texts live in `lib/l10n/app_en.arb` (English source, with descriptions) and
  `app_it.arb`; code reads them through `l10n` (`lib/src/l10n.dart`). After editing the ARB
  files run `flutter gen-l10n`; tests run in English, the Italian ones use `Locale('it')`.
- The app has no native code: the shell runs on a pseudo-terminal of the Silica embedder,
  channel `silica/pty` (`lib/src/pty.dart`). Tests use `FakePty`.
- Geometry and colours waiting for measurements are in `lib/src/style.dart`, marked
  provisional, and listed in `docs/parity.md`.
- Every user action is a `terminal.*` command, listed in `docs/spec.md`.
- `silica_ui` is used from a tag (`ref` in `pubspec.yaml`).
- Never crash: a missing pseudo-terminal service, a dead process or malformed output are normal
  cases, with a message in the grid, not an exception.
