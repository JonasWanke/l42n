import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

@immutable
class Bloc {
  const Bloc._(this.locales, this.strings)
      : assert(locales != null),
        assert(strings != null);

  static Future<Bloc> from(Directory directory) async {
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
        string.translations[locale] = Translation(entry.value);
        strings[id] = string;
      }
    }

    return Bloc._(locales, strings);
  }

  final List<Locale> locales;
  final Map<String, L42nString> strings;

  Stream<String> getTranslation(String id, Locale locale) {}
  void update(String id, Locale locale, String value) {}
}
