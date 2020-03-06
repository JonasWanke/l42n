import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:l42n/data/blocs/translation.dart';
import 'package:path/path.dart';

import 'blocs/locale.dart';
import 'project.dart';

class DirectoryProjectBackend {
  DirectoryProjectBackend._(this.directory, this.project)
      : assert(directory != null),
        assert(project != null) {
    project.eventQueue.listen((event) async {
      if (event is LocaleAddedEvent) {
        await _saveLocale(event.locale);
      } else if (event is TranslationChangedEvent) {
        await _saveLocale(event.locale);
      }
    });
  }

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

    final project = await Project.create(
      locales: locales,
      resources: resources,
    );
    DirectoryProjectBackend._(directory, project);
    return project;
  }

  static const encoder = JsonEncoder.withIndent('  ');

  final Directory directory;
  final Project project;

  Future<void> _saveLocale(Locale locale) async {
    final file = File(join(directory.path, 'intl_$locale.arb'));
    final translations = await project.translationBloc.getAllForLocale(locale);
    final contents = {
      '@@locale': locale.toString(),
      for (final entry in translations.entries) entry.key: entry.value,
    };
    await file.writeAsString(encoder.convert(contents));
  }
}
