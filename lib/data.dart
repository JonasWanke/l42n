import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'utils.dart';

@immutable
class Project {
  Project._(
    this.backend,
    this._db,
    Set<Locale> locales,
    Map<String, Map<Locale, String>> resources,
  )   : assert(backend != null),
        assert(_db != null),
        assert(locales != null),
        assert(resources != null) {
    // Store locales
    for (final locale in locales) {
      _localeRef(locale).put(_db, <String, dynamic>{});
    }

    // Store resources
    for (final entry in resources.entries) {
      final id = entry.key;
      final translations = entry.value;
      _resourceRef(id).put(_db, {});

      for (final translation in translations.entries) {
        _translationStore.add(_db, {
          'id': id,
          'locale': translation.key.toLanguageTag(),
          'value': translation.value,
        });
      }
    }
  }

  static Future<Project> create({
    @required ProjectBackend backend,
    @required Set<Locale> locales,
    @required Map<String, Map<Locale, String>> resources,
  }) async {
    assert(backend != null);
    assert(locales != null);
    assert(resources != null);

    // Setting the [path] to `null` always creates a new DB
    final db = await databaseFactoryMemory.openDatabase(null);

    return Project._(backend, db, locales, resources);
  }

  static Future<Project> forDirectory(Directory directory) =>
      _DirectoryProjectBackend.from(directory);

  final ProjectBackend backend;
  final Database _db;

  // Locale
  final StoreRef _localeStore = stringMapStoreFactory.store('locale');
  RecordRef<String, Map<String, dynamic>> _localeRef(Locale locale) =>
      _localeStore.record(locale.toLanguageTag());

  Stream<List<Locale>> get locales {
    return _localeStore
        .streamKeys(_db)
        .map((keys) => keys.map((k) => (k as String).parseLocale()).toList());
  }

  void addLocale(Locale locale) async {
    final ref = _localeRef(locale);
    if (await ref.exists(_db)) {
      return;
    }

    await ref.put(_db, {});
    backend.onLocaleAdded(locale);
  }

  // Resource
  final StoreRef _resourceStore = stringMapStoreFactory.store('resource');
  RecordRef<String, Map<String, dynamic>> _resourceRef(String id) =>
      _resourceStore.record(id);
  // L42nString addString(String id) {
  //   if (_strings.containsKey(id)) {
  //     throw Exception('String with id $id already exists.');
  //   }

  //   final string = L42nString(id, {});
  //   _strings[id] = string;
  //   backend.onStringAdded(string);
  //   return string;
  // }

  Stream<List<String>> get resourceIds => _resourceStore.streamKeys(_db);

  // Translation
  final StoreRef _translationStore = intMapStoreFactory.store('translation');
  Future<RecordRef<int, Map<String, dynamic>>> _translationRef(
      String resourceId, Locale locale) async {
    final snapshot = await _translationStore.findFirst(
      _db,
      finder: Finder(
        filter: Filter.equals('id', resourceId) &
            Filter.equals('locale', locale.toLanguageTag()),
        limit: 1,
      ),
    );
    final ref = snapshot?.ref;
    if (ref != null) {
      return ref;
    }

    final id = _translationStore.add(_db, {
      'id': resourceId,
      'locale': locale.toLanguageTag(),
      'value': null,
    });
    return _translationStore.record(id);
  }

  Stream<String> getTranslation(String resourceId, Locale locale) {
    return _translationRef(resourceId, locale).asStream().switchMap((ref) =>
        ref.onSnapshot(_db).map((snapshot) => snapshot.value['value']));
  }

  void setTranslation(String resourceId, Locale locale, String value) async {
    final ref = await _translationRef(resourceId, locale);
    await ref.update(_db, {
      'id': resourceId,
      'locale': locale.toLanguageTag(),
      'value': value,
    });
  }
}

abstract class ProjectBackend {
  void onLocaleAdded(Locale locale);
  void onResourceAdded(String id);
  void onTranslationChanged(String id, Locale locale, String value);
}

class _DirectoryProjectBackend extends ProjectBackend {
  _DirectoryProjectBackend._(this.directory) : assert(directory != null);

  final Directory directory;

  static Future<Project> from(Directory directory) async {
    final entities = await directory.list(followLinks: false).toList();
    final l42nFiles = entities
        .whereType<File>()
        .where((file) => extension(file.path) == '.arb')
        .where(
            (file) => basenameWithoutExtension(file.path).startsWith('intl_'));

    final locales = <Locale>{};
    final resources = <String, Map<Locale, String>>{};

    for (final file in l42nFiles) {
      final Map<String, dynamic> currentStrings =
          json.decode(await file.readAsString());
      final locale = Locale(currentStrings['@@locale']);
      locales.add(locale);

      currentStrings.forEach((id, translation) {
        if (id.startsWith('@')) {
          return;
        }

        final string = resources[id] ??= {};
        string[locale] = translation;
        resources[id] = string;
      });
    }

    return Project.create(
      backend: _DirectoryProjectBackend._(directory),
      locales: locales,
      resources: resources,
    );
  }

  @override
  void onLocaleAdded(Locale locale) async {
    // TODO(JonasWanke): implement onLocaleAdded
  }

  @override
  void onResourceAdded(String id) {}

  @override
  void onTranslationChanged(String id, Locale locale, String value) async {
    // TODO(JonasWanke): implement onTranslationChanged
    // final file = File(join(directory.path, 'intl_$locale.arb'));
    // final contents = {
    //   '@@locale': locale.toString(),
    //   for (final string in resources)
    //     if (string.getTranslation(locale).value.isNotEmpty)
    //       string.id: string.getTranslation(locale).value,
    // };
    // await file.writeAsString(json.encode(contents));
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
