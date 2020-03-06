import 'dart:ui';

import 'package:meta/meta.dart';

import 'utils.dart';

@immutable
class ErrorSeverity {
  const ErrorSeverity._(this.ordinal, this.title)
      : assert(ordinal != null),
        assert(title != null);
  factory ErrorSeverity.fromJson(int json) =>
      values.singleWhere((s) => s.ordinal == json);
  int toJson() => ordinal;

  final int ordinal;
  final String title;

  static const warning = ErrorSeverity._(2, 'warning');
  static const error = ErrorSeverity._(3, 'error');
  static const values = [warning, error];
}

@immutable
abstract class L42nStringError {
  const L42nStringError({
    @required this.severity,
    this.locale,
  }) : assert(severity != null);

  factory L42nStringError.fromJson(Map<String, dynamic> json) {
    return {
      MissingTranslationError.type: (json) =>
          MissingTranslationError.fromJson(json),
      MissingPlaceholdersError.type: (json) =>
          MissingPlaceholdersError.fromJson(json),
    }[json['_type']](json);
  }
  Map<String, dynamic> toJson();

  final ErrorSeverity severity;
  final Locale locale;
}

class MissingTranslationError extends L42nStringError {
  const MissingTranslationError(Locale locale)
      : assert(locale != null),
        super(
          severity: ErrorSeverity.error,
          locale: locale,
        );
  MissingTranslationError.fromJson(Map<String, dynamic> json)
      : this((json['locale'] as String).parseLocale());
  @override
  Map<String, dynamic> toJson() => {
        '_type': type,
        'locale': locale.toLanguageTag(),
      };

  static const type = 'missing_translation';
}

class MissingPlaceholdersError extends L42nStringError {
  const MissingPlaceholdersError(Locale locale)
      : assert(locale != null),
        super(
          severity: ErrorSeverity.warning,
          locale: locale,
        );
  MissingPlaceholdersError.fromJson(Map<String, dynamic> json)
      : this((json['locale'] as String).parseLocale());
  @override
  Map<String, dynamic> toJson() => {
        '_type': type,
        'locale': locale.toLanguageTag(),
      };

  static const type = 'missing_placeholder';
}
