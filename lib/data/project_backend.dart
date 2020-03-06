import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart';

import 'project.dart';

abstract class ProjectBackend {
  void onLocaleAdded(Locale locale);
  void onResourceAdded(String id);
  void onTranslationChanged(String id, Locale locale, String value);
}

class DirectoryProjectBackend extends ProjectBackend {
  DirectoryProjectBackend._(this.directory) : assert(directory != null);

  final Directory directory;

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

    return Project.create(
      backend: DirectoryProjectBackend._(directory),
      locales: locales,
      resources: resources,
    );
  }

  @override
  void onLocaleAdded(Locale locale) async {
    // TODO(JonasWanke): implement onLocaleAdded
  }

  @override
  void onResourceAdded(String id) {}

  @override
  void onTranslationChanged(String id, Locale locale, String value) async {
    // TODO(JonasWanke): implement onTranslationChanged
    // final file = File(join(directory.path, 'intl_$locale.arb'));
    // final contents = {
    //   '@@locale': locale.toString(),
    //   for (final string in resources)
    //     if (string.getTranslation(locale).value.isNotEmpty)
    //       string.id: string.getTranslation(locale).value,
    // };
    // await file.writeAsString(json.encode(contents));
  }
}
