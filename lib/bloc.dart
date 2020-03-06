import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:path/path.dart';

import 'data.dart';

@immutable
class Bloc {
  const Bloc._(this.locales, Map<String, L42nString> strings)
      : assert(locales != null),
        assert(strings != null),
        _strings = strings;

  static Future<Bloc> from(Directory directory) async {
    // final de = Locale('de-DE');
    // final en = Locale('en-US');

    // return Bloc._([
    //   de,
    //   en
    // ], {
    //   'a': L42nString('a', {
    //     en: Translation('An a string.'),
    //     de: Translation('Ein A-String.'),
    //   }),
    //   'b': L42nString('b', {
    //     en: Translation('A b string.'),
    //     de: Translation('Ein b-String.'),
    //   }),
    // });

    final entities = await directory.list(followLinks: false).toList();
    final files = entities.whereType<File>();

    final locales = <Locale>[];
    final strings = <String, L42nString>{};
    for (final file in files) {
      if (extension(file.path) != '.arb') {
        continue;
      }

      final fileName = basenameWithoutExtension(file.path);
      if (!fileName.startsWith('intl_')) {
        continue;
      }

      final Map<String, dynamic> currentStrings =
          json.decode(await file.readAsString());
      final locale = Locale(currentStrings['@@locale']);
      locales.add(locale);

      for (final entry in currentStrings.entries) {
        final id = entry.key;
        if (id.startsWith('@')) {
          continue;
        }

        final string = strings[id] ??= L42nString(id, {});
        string.getTranslation(locale).value = entry.value;
        strings[id] = string;
      }
    }

    return Bloc._(locales, strings);
  }

  final List<Locale> locales;
  final Map<String, L42nString> _strings;
  Set<String> get ids => _strings.keys.toSet();
  List<L42nString> get strings => _strings.values.toList();

  L42nString createString(String id) {
    if (_strings.containsKey(id)) {
      throw Exception('String with id $id already exists.');
    }

    final string = L42nString(id, {});
    _strings[id] = string;
    return string;
  }

  L42nString getString(String id) {
    return _strings[id] ?? (throw Exception('String not found.'));
  }
}
