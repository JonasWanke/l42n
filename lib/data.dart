import 'dart:async';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class L42nString {
  const L42nString(this.id, Map<Locale, Translation> translations)
      : assert(id != null),
        assert(translations != null),
        _translations = translations;

  final String id;
  final Map<Locale, Translation> _translations;

  Translation getTranslation(Locale locale) {
    return _translations.putIfAbsent(locale, () => Translation());
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
