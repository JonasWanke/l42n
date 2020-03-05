import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import 'data.dart';

@immutable
class Bloc {
  const Bloc._(this.strings) : assert(strings != null);

  final Map<String, L42nString> strings;
  Set<String> get ids => strings.keys.toSet();

  Stream<String> getTranslation(String id, Locale locale) {
    return strings
        .putIfAbsent(id, () => L42nString(id, {}))
        .translations
        .putIfAbsent(locale, () => Translation())
        .stream;
  }

  void update(String id, Locale locale, String value) {}
}
