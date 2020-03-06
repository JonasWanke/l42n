import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data/blocs/locale.dart';
import 'package:l42n/data/blocs/resource.dart';
import 'package:l42n/data/blocs/translation.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'blocs/bloc.dart';
import 'blocs/error.dart';
import 'project_backend.dart';

@immutable
class Project {
  const Project._(
    this._db,
    this.eventQueue,
    this.localeBloc,
    this.errorBloc,
    this.resourceBloc,
    this.translationBloc,
  )   : assert(_db != null),
        assert(eventQueue != null),
        assert(localeBloc != null),
        assert(errorBloc != null),
        assert(resourceBloc != null),
        assert(translationBloc != null);

  static Future<Project> create({
    @required Set<Locale> locales,
    @required Map<String, Map<Locale, String>> resources,
  }) async {
    assert(locales != null);
    assert(resources != null);

    // Setting the [path] to `null` always creates a new DB
    final db = await databaseFactoryMemory.openDatabase(null);
    // final db = await databaseFactoryIo.openDatabase('db.json');

    // We use the event queue throughout the lifetime of [Project] and close it
    // in [close].
    // ignore: close_sinks
    final eventQueue = BehaviorSubject<Event>();

    final localeBloc = LocaleBloc(db, eventQueue);
    final resourceBloc = ResourceBloc(db, eventQueue);
    final translationBloc = TranslationBloc(db, eventQueue);
    final errorBloc = ErrorBloc(
      db,
      eventQueue,
      localeBloc: localeBloc,
      translationBloc: translationBloc,
    );

    // Store locales
    for (final locale in locales) {
      await localeBloc.add(locale);
    }

    // Store resources
    for (final entry in resources.entries) {
      final id = entry.key;
      final translations = entry.value;
      await resourceBloc.add(id);

      for (final translation in translations.entries) {
        await translationBloc.set(id, translation.key, translation.value);
      }
    }

    return Project._(
        db, eventQueue, localeBloc, errorBloc, resourceBloc, translationBloc);
  }

  static Future<Project> forDirectory(Directory directory) =>
      DirectoryProjectBackend.from(directory);

  final Database _db;
  final BehaviorSubject<Event> eventQueue;

  final LocaleBloc localeBloc;
  final ErrorBloc errorBloc;
  final ResourceBloc resourceBloc;
  final TranslationBloc translationBloc;

  void close() {
    translationBloc.close();
    resourceBloc.close();
    errorBloc.close();
    localeBloc.close();
    eventQueue.close();
  }
}
