import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';

import '../utils.dart';
import 'bloc.dart';

class ResourceBloc extends Bloc {
  ResourceBloc(Database db, BehaviorSubject<Event> eventQueue)
      : super(db, eventQueue);

  final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('resource');
  RecordRef<String, Map<String, dynamic>> _ref(String id) => _store.record(id);

  Stream<List<String>> get all => _store.streamKeys(db);

  Future<void> add(String id) async {
    final ref = _ref(id);
    if (await ref.exists(db)) {
      throw IdAlreadyExistsException(id);
    }

    await ref.add(db, _Resource().toJson());
    eventQueue.add(ResourceAddedEvent(id));
  }

  Future<void> delete(String id) async {
    await _ref(id).delete(db);

    eventQueue.add(ResourceDeletedEvent(id));
  }
}

class ResourceAddedEvent extends Event {
  const ResourceAddedEvent(this.id) : assert(id != null);

  final String id;
}

class ResourceDeletedEvent extends Event {
  const ResourceDeletedEvent(this.id) : assert(id != null);

  final String id;
}

@immutable
class _Resource {
  const _Resource();

  // ignore: avoid_unused_constructor_parameters
  const _Resource.fromJson(Map<String, dynamic> json) : this();
  Map<String, dynamic> toJson() => {};
}
