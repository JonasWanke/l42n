import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data/error.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tuple/tuple.dart';

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
      _localeRef(locale).put(_db, _Locale().toJson());
    }

    // Store resources
    for (final entry in resources.entries) {
      final id = entry.key;
      final translations = entry.value;
      _resourceRef(id).put(_db, _Resource().toJson());

      for (final translation in translations.entries) {
        _translationStore.add(
            _db, _Translation(id, translation.key, translation.value).toJson());
      }
    }

    _startLinting();
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
  Future<void> createResource(String id) async {
    final ref = _resourceRef(id);
    if (await ref.exists(_db)) {
      throw IdAlreadyExistsException(id);
    }

    await ref.add(_db, _Resource().toJson());
    _startErrorJobForResource(id);
  }

  Stream<List<String>> get resourceIds => _resourceStore.streamKeys(_db);

  // Translation
  final StoreRef<int, Map<String, dynamic>> _translationStore =
      intMapStoreFactory.store('translation');
  Future<RecordRef<int, Map<String, dynamic>>> _translationRef(
      String resourceId, Locale locale) async {
    final snapshot = await _translationStore.findFirst(
      _db,
      finder: Finder(
        filter: Filter.equals('resourceId', resourceId) &
            Filter.equals('locale', locale.toLanguageTag()),
        limit: 1,
      ),
    );
    final ref = snapshot?.ref;
    if (ref != null) {
      return ref;
    }

    final id = await _translationStore.add(
        _db, _Translation(resourceId, locale).toJson());
    return _translationStore.record(id);
  }

  Stream<String> getTranslation(String resourceId, Locale locale) {
    return _translationRef(resourceId, locale).asStream().switchMap((ref) =>
        ref.onSnapshot(_db).map((snapshot) => snapshot.value['value']));
  }

  Future<void> setTranslation(
    String resourceId,
    Locale locale,
    String value,
  ) async {
    final ref = await _translationRef(resourceId, locale);
    await ref.update(_db, _Translation(resourceId, locale, value).toJson());
    await backend.onTranslationChanged(this, resourceId, locale, value);
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
      for (final translation
          in values.map((json) => _Translation.fromJson(json.value)))
        if (translation.value != null)
          translation.resourceId: translation.value,
    };
  }

  Stream<Map<Locale, String>> getAllTranslationsForResource(String id) {
    return _translationStore
        .query(
          finder: Finder(filter: Filter.equals('resourceId', id)),
        )
        .onSnapshots(_db)
        .map((list) => list
            .map((json) => _Translation.fromJson(json.value))
            .where((t) => t.value != null))
        .map((list) => {
              for (final translation in list)
                translation.locale: translation.value,
            });
  }

  // Errors
  final StoreRef<int, Map<String, dynamic>> _errorStore =
      intMapStoreFactory.store('error');
  final Map<String, StreamSubscription> _perResourceErrorJobs = {};
  void _startLinting() async {
    (await resourceIds.first).forEach(_startErrorJobForResource);
  }

  void _startErrorJobForResource(String id) {
    _perResourceErrorJobs[id]?.cancel();
    _perResourceErrorJobs[id] = Rx.combineLatest2(
      locales,
      getAllTranslationsForResource(id),
      (l, t) => Tuple2<List<Locale>, Map<Locale, String>>(l, t),
    ).listen((tuple) {
      final locales = tuple.item1;
      final translations = tuple.item2;

      final errors = locales
          .where((l) => translations[l] == null)
          .map((l) => MissingTranslationError(l))
          .map((e) => _Error(id, e).toJson())
          .toList();
      _db.transaction((t) async {
        await _errorStore.delete(
          t,
          finder: Finder(
            filter: Filter.equals('resource', id) &
                Filter.equals('error._type', MissingTranslationError.type),
          ),
        );
        await _errorStore.addAll(t, errors);
      });
    });
  }

  Stream<List<L42nStringError>> getErrorsForResource(String id) {
    return _errorStore
        .query(
          finder: Finder(
            filter: Filter.equals('resource', id) &
                Filter.equals('error._type', MissingTranslationError.type),
          ),
        )
        .onSnapshots(_db)
        .map((list) => list.map((e) => L42nStringError.fromJson(e.value)));
  }
}

@immutable
class IdAlreadyExistsException implements Exception {
  const IdAlreadyExistsException(this.id) : assert(id != null);

  final String id;
}

@immutable
class _Locale {
  const _Locale();

  // ignore: avoid_unused_constructor_parameters
  const _Locale.fromJson(Map<String, dynamic> json) : this();
  Map<String, dynamic> toJson() => {};
}

@immutable
class _Resource {
  const _Resource();

  // ignore: avoid_unused_constructor_parameters
  const _Resource.fromJson(Map<String, dynamic> json) : this();
  Map<String, dynamic> toJson() => {};
}

@immutable
class _Translation {
  const _Translation(
    this.resourceId,
    this.locale, [
    this.value,
  ])  : assert(resourceId != null),
        assert(locale != null);

  _Translation.fromJson(Map<String, dynamic> json)
      : this(
          json['resourceId'],
          (json['locale'] as String).parseLocale(),
          json['value'],
        );
  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        'locale': locale.toString(),
        'value': value,
      };

  final String resourceId;
  final Locale locale;
  final String value;
}

@immutable
class _Error {
  const _Error(
    this.resourceId,
    this.error,
  )   : assert(resourceId != null),
        assert(error != null);

  _Error.fromJson(Map<String, dynamic> json)
      : this(
          json['resourceId'],
          L42nStringError.fromJson(json['value']),
        );
  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        'error': error.toJson(),
      };

  final String resourceId;
  final L42nStringError error;
}
