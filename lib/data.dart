import 'dart:async';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class L42nString {
  L42nString(this.id, this._translations)
      : assert(id != null),
        assert(_translations != null),
        _localesController = BehaviorSubject.seeded(_translations.keys.toSet());

  final String id;
  final Map<Locale, Translation> _translations;

  Translation getTranslation(Locale locale) {
    final translation = _translations.putIfAbsent(locale, () => Translation());
    if (_translations.keys.length != _localesController.value.length) {
      _localesController.add(_translations.keys.toSet());
    }
    return translation;
  }

  void dispose() => _localesController.close();

  final BehaviorSubject<Set<Locale>> _localesController;
  Stream<Set<Locale>> get locales => _localesController.stream;

  Stream<List<L42nStringError>> get errors {
    Stream<MapEntry<Locale, String>> localeAndValue(Locale locale) =>
        getTranslation(locale).stream.map((v) => MapEntry(locale, v));

    return locales
        .switchMap(
            (locales) => Rx.combineLatestList(locales.map(localeAndValue)))
        .map((localesAndValues) => {
              for (final entry in localesAndValues) entry.key: entry.value,
            })
        .map((values) {
      final locales = values.keys;

      return [
        for (final locale in locales)
          if (values[locale].isEmpty) MissingTranslationError(locale),
      ];
    });
  }
}

/// A translation of a [L42nString] in one [Locale].
class Translation {
  Translation([String value = ''])
      : _value = value,
        _controller = BehaviorSubject<String>();

  void dispose() => _controller.close();

  final StreamController<String> _controller;
  Stream<String> get stream => _controller.stream;

  String _value;
  String get value => _value;
  set value(String value) {
    _value = value;
    _controller.add(value);
  }
}

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
