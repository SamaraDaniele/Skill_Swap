import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../error/failure.dart';

export '../../l10n/app_localizations.dart';

const List<LocalizationsDelegate<Object>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureMessages on AppLocalizations {
  String failureMessage(Object error) => switch (mapToFailure(error)) {
    NetworkFailure() => errorNetwork,
    InvalidCredentialsFailure() => errorInvalidCredentials,
    EmailInUseFailure() => errorEmailInUse,
    WeakPasswordFailure() => errorWeakPassword,
    TooManyRequestsFailure() => errorTooManyRequests,
    InvalidEmailFailure() => validationEmail,
    InvalidImageFailure() => errorInvalidImage,
    InvalidPostFailure() => errorInvalidPost,
    InvalidVideoFailure() => errorInvalidVideo,
    PermissionFailure() => errorPermission,
    UnknownFailure() => errorUnknown,
  };
}

Locale resolveAppLocale(Locale? device, Iterable<Locale> supported) {
  for (final locale in supported) {
    if (locale.languageCode == device?.languageCode) return locale;
  }
  return const Locale('pt');
}
