import 'dart:io';

import 'package:flutter/material.dart';

import 'bloc.dart';

class EditorPage extends StatelessWidget {
  const EditorPage(this.directory) : assert(directory != null);

  final Directory directory;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Bloc>(
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
        final ids = bloc.ids.toList()..sort();

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
                for (final id in ids)
                  DataRow(
                    key: ValueKey(id),
                    cells: [
                      DataCell(Text(id)),
                      for (final locale in bloc.locales)
                        DataCell(
                          Tooltip(
                            message:
                                bloc.strings[id].translations[locale].value ??
                                    'Not translated yet.',
                            child: Text(
                              bloc.strings[id].translations[locale].value ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          placeholder:
                              bloc.strings[id].translations[locale] == null,
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
