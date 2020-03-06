import 'dart:ui';

import 'package:meta/meta.dart';

@immutable
class L42nStringError {
  const L42nStringError({
    @required this.message,
    @required this.severity,
    this.locale,
  })  : assert(message != null),
        assert(severity != null);

  final String message;
  final ErrorSeverity severity;
  final Locale locale;
}

enum ErrorSeverity {
  warning,
  error,
}

class MissingTranslationError extends L42nStringError {
  const MissingTranslationError(Locale locale)
      : assert(locale != null),
        super(
          message: 'Missing translation.',
          severity: ErrorSeverity.error,
          locale: locale,
        );
}
