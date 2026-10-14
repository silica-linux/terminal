// Localization: English is the source language, Italian the first translation (lib/l10n/*.arb,
// generated with `flutter gen-l10n`). The embedder passes the system languages
// (FlutterEngineUpdateLocales); the root resolves them against the supported locales, falling
// back to English. The resolved translation is also kept in [l10n] for code outside widgets.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// The languages Terminal is translated into.
const List<Locale> supportedLocales = [Locale('en'), Locale('it')];

AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

/// The texts in the resolved language (English until the root resolves the platform's).
AppLocalizations get l10n => _current;

/// The first preferred language Terminal has, otherwise English.
Locale resolveLocale(Iterable<Locale> preferred) {
  for (final locale in preferred) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return supportedLocales.first;
}

/// Uses the translation of `locale` from now on (tests, and the root on a language change).
void useLocale(Locale locale) =>
    _current = lookupAppLocalizations(resolveLocale([locale]));

/// The root of the tree: resolves the platform languages, keeps [l10n] in step and provides
/// [Localizations] to the widgets below.
class AppLocalizationsScope extends StatefulWidget {
  const AppLocalizationsScope({super.key, required this.child, this.locale});

  final Widget child;

  /// A fixed language (tests); null: the platform's.
  final Locale? locale;

  @override
  State<AppLocalizationsScope> createState() => _AppLocalizationsScopeState();
}

class _AppLocalizationsScopeState extends State<AppLocalizationsScope>
    with WidgetsBindingObserver {
  late Locale _locale = _resolve();

  Locale _resolve() =>
      resolveLocale([?widget.locale, ...PlatformDispatcher.instance.locales]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    useLocale(_locale);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final locale = _resolve();
    if (locale == _locale) return;
    setState(() => _locale = locale);
    useLocale(locale);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations(
    locale: _locale,
    delegates: const [
      AppLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    child: widget.child,
  );
}
