import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Texts in the device language for code without a [BuildContext]
/// (controllers). Resolves like `MaterialApp`: the first supported device
/// language wins, otherwise English. Rebuilds when the device language changes.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final binding = WidgetsBinding.instance;
  final observer = _LocaleObserver(ref.invalidateSelf);
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));
  return lookupAppLocalizations(
    basicLocaleListResolution(
      binding.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    ),
  );
});

class _LocaleObserver with WidgetsBindingObserver {
  final VoidCallback onChange;

  _LocaleObserver(this.onChange);

  @override
  void didChangeLocales(List<Locale>? locales) => onChange();
}
