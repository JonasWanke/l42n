import 'dart:async';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class L42nString {
  const L42nString(this.id, this.translations)
      : assert(id != null),
        assert(translations != null);

  final String id;
  final Map<Locale, Translation> translations;
}

/// A translation of a [L42nString] in one [Locale].
class Translation {
  Translation([String value])
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
