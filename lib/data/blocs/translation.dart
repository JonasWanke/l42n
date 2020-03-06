import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

import '../utils.dart';
import 'bloc.dart';
import 'resource.dart';

class TranslationBloc extends Bloc {
  TranslationBloc(Database db, BehaviorSubject<Event> eventQueue)
      : super(db, eventQueue) {
    eventQueue.listen((event) {
      if (event is ResourceDeletedEvent) {}
    });
  }

  final StoreRef<int, Map<String, dynamic>> _store =
      intMapStoreFactory.store('translation');

  Future<RecordRef<int, Map<String, dynamic>>> _ref(
    String resourceId,
    Locale locale,
  ) async {
    final snapshot = await _store.findFirst(
      db,
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

    final id = await _store.add(db, _Translation(resourceId, locale).toJson());
    return _store.record(id);
  }

  Stream<String> get(String resourceId, Locale locale) async* {
    final ref = await _ref(resourceId, locale);

    yield* ref
        .onSnapshot(db)
        .map((snapshot) => _Translation.fromJson(snapshot.value).value);
  }

  Future<void> set(
    String resourceId,
    Locale locale,
    String value,
  ) async {
    // ignore: parameter_assignments
    value ??= '';

    final ref = await _ref(resourceId, locale);
    await ref.update(db, _Translation(resourceId, locale, value).toJson());

    eventQueue.add(TranslationChangedEvent(resourceId, locale, value));
  }

  Future<Map<String, String>> getAllForLocale(Locale locale) async {
    final values = await _store
        .query(
          finder: Finder(
            filter: Filter.equals('locale', locale.toLanguageTag()),
          ),
        )
        .getSnapshots(db);
    return {
      for (final translation
          in values.map((json) => _Translation.fromJson(json.value)))
        if (translation.value != null)
          translation.resourceId: translation.value,
    };
  }

  Stream<Map<Locale, String>> getAllForResource(String resourceId) {
    return _store
        .query(
          finder: Finder(filter: Filter.equals('resourceId', resourceId)),
        )
        .onSnapshots(db)
        .map((list) => list
            .map((json) => _Translation.fromJson(json.value))
            .where((t) => t.value != null))
        .map((list) => {
              for (final translation in list)
                translation.locale: translation.value,
            });
  }

  Future<void> deleteAllForResource(String resourceId) async {
    final keys = await _store.findKeys(
      db,
      finder: Finder(filter: Filter.equals('resourceId', resourceId)),
    );
    for (final key in keys) {
      await _store.record(key).delete(db);
    }
  }
}

class TranslationChangedEvent extends Event {
  const TranslationChangedEvent(this.resourceId, this.locale, this.value)
      : assert(resourceId != null),
        assert(locale != null),
        assert(value != null);

  final String resourceId;
  final Locale locale;
  final String value;
}

@immutable
class _Translation {
  const _Translation(
    this.resourceId,
    this.locale, [
    this.value = '',
  ])  : assert(resourceId != null),
        assert(locale != null),
        assert(value != null);

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
