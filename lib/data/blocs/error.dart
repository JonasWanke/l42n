import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

import '../error.dart';
import '../utils.dart';
import 'bloc.dart';
import 'locale.dart';
import 'translation.dart';

class ErrorBloc extends Bloc {
  ErrorBloc(
    Database db,
    BehaviorSubject<Event> eventQueue, {
    @required this.localeBloc,
    @required this.translationBloc,
  })  : assert(localeBloc != null),
        assert(translationBloc != null),
        super(db, eventQueue);

  final LocaleBloc localeBloc;
  final TranslationBloc translationBloc;

  final StoreRef<int, Map<String, dynamic>> _store =
      intMapStoreFactory.store('error');

  // final Map<String, StreamSubscription> _perResourceJobs = {};
  // void _startLinting() async {
  //   (await all.first).forEach(_startJobForResource);
  // }

  // void _startJobForResource(String id) {
  //   _perResourceJobs[id]?.cancel();
  //   _perResourceJobs[id] = Rx.combineLatest2(
  //     localeBloc.all,
  //     translationBloc.getAllForResource(id),
  //     (l, t) => Tuple2<List<Locale>, Map<Locale, String>>(l, t),
  //   ).listen((tuple) {
  //     final locales = tuple.item1;
  //     final translations = tuple.item2;

  //     final errors = locales
  //         .where((l) => translations[l] == null)
  //         .map((l) => MissingTranslationError(l))
  //         .map((e) => _Error(id, e).toJson())
  //         .toList();
  //     db.transaction((t) async {
  //       await _store.delete(
  //         t,
  //         finder: Finder(
  //           filter: Filter.equals('resource', id) &
  //               Filter.equals('error._type', MissingTranslationError.type),
  //         ),
  //       );
  //       await _store.addAll(t, errors);
  //     });
  //   });
  // }

  Stream<List<L42nStringError>> allForResource(String id) {
    return _store
        .query(
          finder: Finder(
            filter: Filter.equals('resource', id) &
                Filter.equals('error._type', MissingTranslationError.type),
          ),
        )
        .onSnapshots(db)
        .map((list) => list.map((e) => _Error.fromJson(e.value).error));
  }
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