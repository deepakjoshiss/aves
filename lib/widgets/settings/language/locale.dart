import 'dart:collection';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_selection_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocaleTile extends StatelessWidget {
  static const _systemLocaleOption = Locale('system');

  const LocaleTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final current = settings.locale;
    return ListTile(
      title: Text(context.l10n.settingsLanguage),
      subtitle: Text(current == null ? context.l10n.settingsSystemDefault : _getLocaleName(current)),
      onTap: () async {
        final value = await showDialog<Locale>(
          context: context,
          builder: (context) => AvesSelectionDialog<Locale>(
            initialValue: settings.locale ?? _systemLocaleOption,
            options: _getLocaleOptions(context),
            title: context.l10n.settingsLanguage,
          ),
        );
        // wait for the dialog to hide as applying the change may block the UI
        await Future.delayed(Durations.dialogTransitionAnimation * timeDilation);
        if (value != null) {
          settings.locale = value == _systemLocaleOption ? null : value;
        }
      },
    );
  }

  String _getLocaleName(Locale locale) {
    // the package `flutter_localized_locales` has the answer for all locales
    // but it comes with 3 MB of assets
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ko':
        return '한국어';
    }
    return locale.toString();
  }

  LinkedHashMap<Locale, String> _getLocaleOptions(BuildContext context) {
    final displayLocales = AppLocalizations.supportedLocales.map((locale) => MapEntry(locale, _getLocaleName(locale))).toList()..sort((a, b) => compareAsciiUpperCase(a.value, b.value));

    return LinkedHashMap.of({
      _systemLocaleOption: context.l10n.settingsSystemDefault,
      ...LinkedHashMap.fromEntries(displayLocales),
    });
  }
}