import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

import '../utils.dart';
import 'bloc.dart';

class LocaleBloc extends Bloc {
  LocaleBloc(Database db, BehaviorSubject<Event> eventQueue)
      : super(db, eventQueue);

  final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('locale');
  RecordRef<String, Map<String, dynamic>> _ref(Locale locale) =>
      _store.record(locale.toLanguageTag());

  Stream<List<Locale>> get all {
    return _store
        .streamKeys(db)
        .map((keys) => keys.map((k) => (k as String).parseLocale()).toList());
  }

  Future<void> add(Locale locale) async {
    await _ref(locale).add(db, _Locale().toJson());
    eventQueue.add(LocaleAddedEvent(locale));
  }
}

class LocaleAddedEvent extends Event {
  const LocaleAddedEvent(this.locale) : assert(locale != null);

  final Locale locale;
}

@immutable
class _Locale {
  const _Locale();

  // ignore: avoid_unused_constructor_parameters
  const _Locale.fromJson(Map<String, dynamic> json) : this();
  Map<String, dynamic> toJson() => {};
}
