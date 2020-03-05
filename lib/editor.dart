import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bloc.dart';

class Editor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<Bloc>(context);

    return SingleChildScrollView(
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
                    Text(
                      entry.value.translations[locale].value ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    placeholder: entry.value.translations[locale] == null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
