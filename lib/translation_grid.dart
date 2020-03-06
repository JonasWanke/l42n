import 'package:flutter/material.dart';
import 'package:l42n/translation_field.dart';

import 'bloc.dart';

class TranslationGrid extends StatelessWidget {
  TranslationGrid({@required this.bloc, String filter = ''})
      : _filterParts = filter.trim().toLowerCase().split(RegExp(' +'));

  final Bloc bloc;
  final List<String> _filterParts;

  @override
  Widget build(BuildContext context) {
    final ids = bloc.ids.where(_applyFilter).toList()..sort();
    final proportions = [
      1,
      for (final _ in bloc.locales) 1,
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return _HeaderRow(
              bloc: bloc,
              proportions: proportions,
            );
          }
          if (index.isOdd) {
            return Divider();
          }

          final translationIndex = index ~/ 2 - 1;
          return _TranslationRow(
            bloc: bloc,
            id: ids[translationIndex],
            proportions: proportions,
          );
        },
        childCount: 2 * bloc.ids.length + 1,
      ),
    );
  }

  bool _applyFilter(String id) {
    final lowerId = id.toLowerCase();
    return _filterParts.every(lowerId.contains);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    Key key,
    @required this.bloc,
    @required this.proportions,
  })  : assert(bloc != null),
        assert(proportions != null),
        super(key: key);

  final Bloc bloc;
  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    final titles = [
      'ID',
      for (final locale in bloc.locales) locale.toString(),
    ];
    final textStyle = Theme.of(context).textTheme.subhead;

    return SizedBox(
      height: 52,
      child: _Row(
        proportions: proportions,
        cells: [
          for (final title in titles)
            Text(
              title,
              style: textStyle,
            ),
        ],
      ),
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({
    Key key,
    @required this.bloc,
    @required this.id,
    @required this.proportions,
  })  : assert(bloc != null),
        assert(id != null),
        assert(proportions != null),
        super(key: key);

  final Bloc bloc;
  final String id;
  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    final string = bloc.getString(id);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: _Row(
        proportions: proportions,
        cells: [
          Text(string.id),
          for (final locale in bloc.locales)
            TranslationField(string.getTranslation(locale)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    Key key,
    @required this.cells,
    @required this.proportions,
  })  : assert(cells != null),
        assert(proportions != null),
        assert(cells.length == proportions.length),
        super(key: key);

  final List<Widget> cells;
  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < proportions.length; i++)
          Expanded(
            flex: proportions[i],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: cells[i],
            ),
          ),
      ],
    );
  }
}
