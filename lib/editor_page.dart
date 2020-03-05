import 'dart:io';

import 'package:flutter/material.dart';

import 'bloc.dart';

class EditorPage extends StatelessWidget {
  const EditorPage(this.directory) : assert(directory != null);

  final Directory directory;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Bloc.from(directory),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? snapshot.error.toString()
                : CircularProgressIndicator(),
          );
        }

        final bloc = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text('L42n'),
          ),
          body: SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(label: Text('ID')),
                for (final locale in bloc.locales)
                  DataColumn(label: Text(locale.toString())),
              ],
              rows: [
                for (final entry in bloc.strings.entries)
                  DataRow(
                    key: ValueKey(entry.key),
                    cells: [
                      DataCell(Text(entry.key)),
                      for (final locale in bloc.locales)
                        DataCell(
                          Tooltip(
                            message: entry.value.translations[locale].value ??
                                'Not translated yet.',
                            child: Text(
                              entry.value.translations[locale].value ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          placeholder: entry.value.translations[locale] == null,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
