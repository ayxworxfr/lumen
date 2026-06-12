import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Convenient shorthand: `context.l10n.commonConfirm`
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
