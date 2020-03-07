import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

@immutable
abstract class Bloc {
  const Bloc(this.db, this.eventQueue)
      : assert(db != null),
        assert(eventQueue != null);

  final Database db;
  final BehaviorSubject eventQueue;
}

@immutable
abstract class Event {
  const Event();
}

@immutable
class IdAlreadyExistsException implements Exception {
  const IdAlreadyExistsException(this.id) : assert(id != null);

  final String id;
}
