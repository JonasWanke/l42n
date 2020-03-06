import 'dart:io';

import 'package:flutter/material.dart';

import 'bloc.dart';
import 'translation_field.dart';

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
                for (final string in bloc.strings)
                  DataRow(
                    key: ValueKey(string.id),
                    cells: [
                      DataCell(Text(string.id)),
                      for (final locale in bloc.locales)
                        DataCell(
                          TranslationField(string.getTranslation(locale)),
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
