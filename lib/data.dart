import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

/// A translation of a [L42nString] in one [Locale].
class Translation extends ValueNotifier<String> {
  Translation._(this.locale, [String value = ''])
      : assert(locale != null),
        assert(value != null),
        super(value);

  final Locale locale;
}

/// A string that should be translated into different languages.
@immutable
class L42nString {
  L42nString(this.id, this._translations)
      : assert(id != null),
        assert(_translations != null),
        _localesController = BehaviorSubject.seeded(_translations.keys.toSet());

  final String id;
  final Map<Locale, Translation> _translations;

  Iterable<Translation> get translations => _translations.values;
  Translation addTranslation(Locale locale) {
    if (_translations.containsKey(locale)) {
      throw Exception(
          'Translation for locale $locale already exists for string $id.');
    }
    final translation = Translation._(locale);
    _translations[locale] = translation;
    return translation;
  }

  Translation getTranslation(Locale locale) {
    final translation =
        _translations.putIfAbsent(locale, () => Translation._(locale));
    if (_translations.keys.length != _localesController.value.length) {
      _localesController.add(_translations.keys.toSet());
    }
    return translation;
  }

  void dispose() => _localesController.close();

  final BehaviorSubject<Set<Locale>> _localesController;
  Stream<Set<Locale>> get locales => _localesController.stream;

  // Stream<List<L42nStringError>> get errors {
  //   Stream<MapEntry<Locale, String>> localeAndValue(Locale locale) =>
  //       getTranslation(locale).stream.map((v) => MapEntry(locale, v));

  //   return locales
  //       .switchMap(
  //           (locales) => Rx.combineLatestList(locales.map(localeAndValue)))
  //       .map((localesAndValues) => {
  //             for (final entry in localesAndValues) entry.key: entry.value,
  //           })
  //       .map((values) {
  //     final locales = values.keys;

  //     return [
  //       for (final locale in locales)
  //         if (values[locale].isEmpty) MissingTranslationError(locale),
  //     ];
  //   });
  // }

  Translation operator [](Locale locale) =>
      _translations[locale] ??
      (throw Exception(
          'No translation for locale $locale exists for string $id.'));
}

abstract class ProjectBackend {
  void onStringAdded(L42nString string);
  void onLocaleAdded(Locale locale);
  void onTranslationChanged(Translation translation, L42nString string);
}

@immutable
class Project {
  const Project({
    @required this.backend,
    @required List<Locale> locales,
    @required Map<String, L42nString> strings,
  })  : assert(locales != null),
        assert(strings != null),
        _locales = locales,
        _strings = strings;

  final ProjectBackend backend;

  final List<Locale> _locales;
  Iterable<Locale> get locales => _locales;

  final Map<String, L42nString> _strings;
  Iterable<String> get ids => _strings.keys;
  Iterable<L42nString> get strings => _strings.values;

  void addLocale(Locale locale) {
    if (_locales.contains(locale)) {
      return;
    }
    _locales.add(locale);
    for (final string in strings) {
      final translation = string.addTranslation(locale);
      translation.addListener(() {
        backend.onTranslationChanged(translation, string);
      });
    }
    backend.onLocaleAdded(locale);
  }

  L42nString addString(String id) {
    if (_strings.containsKey(id)) {
      throw Exception('String with id $id already exists.');
    }

    final string = L42nString(id, {});
    _strings[id] = string;
    backend.onStringAdded(string);
    return string;
  }

  L42nString operator [](String id) =>
      _strings[id] ?? (throw Exception('String with id $id not found.'));

  void onTranslationChanged(Translation translation, L42nString string) {
    backend.onTranslationChanged(translation, string);
  }
}

/*class DirectoryProject extends Project {
  DirectoryProject._(
    this.directory,
    List<Locale> locales,
    Map<String, L42nString> initialStrings,
  )   : assert(directory != null),
        super(_locales: locales, strings: initialStrings) {
    for (final string in strings) {
      for (final locale in locales) {
        string.getTranslation(locale).stream.forEach((value) {});
      }
    }
  }

  final Directory directory;

  static Future<Project> fromDirectory(Directory directory) async {
    // final de = Locale('de-DE');
    // final en = Locale('en-US');

    // return Project._(Directory('nonexistent'), [
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
    final l42nFiles = entities
        .whereType<File>()
        .where((file) => extension(file.path) == '.arb')
        .where(
            (file) => basenameWithoutExtension(file.path).startsWith('intl_'));

    final locales = <Locale>[];
    final strings = <String, L42nString>{};

    for (final file in l42nFiles) {
      final Map<String, dynamic> currentStrings =
          json.decode(await file.readAsString());
      final locale = Locale(currentStrings['@@locale']);
      locales.add(locale);

      currentStrings.forEach((id, stringValue) {
        if (id.startsWith('@')) {
          return;
        }

        final string = strings[id] ??= L42nString(id, {});
        string.getTranslation(locale).value = stringValue;
        strings[id] = string;
      });
    }

    return Project(
      _locales: locales,
      strings: strings,
      saveLocale: (locale) async {
        assert(locale != null);
        assert(locales.contains(locale));

        final file = File(join(directory.path, 'intl_$locale.arb'));
        final contents = {
          '@@locale': locale.toString(),
          for (final string in strings)
            if (string.getTranslation(locale).value.isNotEmpty)
              string.id: string.getTranslation(locale).value,
        };
        await file.writeAsString(json.encode(contents));
      },
    );
  }
}*/
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
