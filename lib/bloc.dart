import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

@immutable
class Bloc {
  const Bloc._(this.strings) : assert(strings != null);

  final Map<String, L42nString> strings;

  Stream<String> getTranslation(String id, Locale locale) {}
  void update(String id, Locale locale, String value) {}
}
