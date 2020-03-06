import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import 'data.dart';

@immutable
class Bloc {
  const Bloc._(this.directory, this.locales, this.strings)
      : assert(directory != null),
        assert(locales != null),
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

    return Bloc._(directory, locales, strings);
  }

  final Directory directory;
  final List<Locale> locales;
  final Map<String, L42nString> strings;
  Set<String> get ids => strings.keys.toSet();

  Stream<String> getTranslation(String id, Locale locale) {
    return strings[id]
        .translations
        .putIfAbsent(locale, () => Translation())
        .stream;
  }

  void update(String id, Locale locale, String value) {}

  Future<void> saveLocale(Locale locale) async {
    assert(locale != null);
    assert(locales.contains(locale));

    final file = File(join(directory.path, 'intl_$locale.arb'));
    final contents = {
      '@@locale': locale.toString(),
      for (final string in strings.values)
        if (string.translations[locale] != null)
          string.id: string.translations[locale].value,
    };
    await file.writeAsString(json.encode(contents));
  }
}
