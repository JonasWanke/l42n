import 'dart:io';
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'project_backend.dart';
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
      DirectoryProjectBackend.from(directory);

  final ProjectBackend backend;
  final Database _db;

  // Locale
  final StoreRef<String, Map<String, dynamic>> _localeStore =
      stringMapStoreFactory.store('locale');
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
    await backend.onLocaleAdded(this, locale);
  }

  // Resource
  final StoreRef<String, Map<String, dynamic>> _resourceStore =
      stringMapStoreFactory.store('resource');
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
  final StoreRef<int, Map<String, dynamic>> _translationStore =
      intMapStoreFactory.store('translation');
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

    final id = await _translationStore.add(_db, {
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

  Future<void> setTranslation(String id, Locale locale, String value) async {
    final ref = await _translationRef(id, locale);
    await ref.update(_db, {
      'id': id,
      'locale': locale.toLanguageTag(),
      'value': value,
    });
    await backend.onTranslationChanged(this, id, locale, value);
  }

  Future<Map<String, String>> getAllTranslationsForLocale(Locale locale) async {
    final values = await _translationStore
        .query(
          finder: Finder(
            filter: Filter.equals('locale', locale.toLanguageTag()),
          ),
        )
        .getSnapshots(_db);
    return {
      for (final snapshot in values)
        if (snapshot.value['value'] != null)
          snapshot.value['id']: snapshot.value['value'],
    };
  }
}
