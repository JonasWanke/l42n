import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart';

import 'project.dart';

abstract class ProjectBackend {
  Future<void> onLocaleAdded(Project project, Locale locale);
  Future<void> onResourceAdded(Project project, String id);
  Future<void> onTranslationChanged(
      Project project, String id, Locale locale, String value);
}

class DirectoryProjectBackend extends ProjectBackend {
  DirectoryProjectBackend._(this.directory) : assert(directory != null);

  static Future<Project> from(Directory directory) async {
    final project = DirectoryProjectBackend._(directory);

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
      backend: project,
      locales: locales,
      resources: resources,
    );
  }

  static const encoder = JsonEncoder.withIndent('  ');
  final Directory directory;

  @override
  Future<void> onLocaleAdded(Project project, Locale locale) =>
      _saveLocale(project, locale);

  @override
  Future<void> onResourceAdded(Project project, String id) async {}

  @override
  Future<void> onTranslationChanged(
          Project project, String id, Locale locale, String value) =>
      _saveLocale(project, locale);

  Future<void> _saveLocale(Project project, Locale locale) async {
    final file = _fileForLocale(locale);
    final translations = await project.getAllTranslationsForLocale(locale);
    final contents = {
      '@@locale': locale.toString(),
      for (final entry in translations.entries) entry.key: entry.value,
    };
    await file.writeAsString(encoder.convert(contents));
  }

  File _fileForLocale(Locale locale) =>
      File(join(directory.path, 'intl_$locale.arb'));
}
