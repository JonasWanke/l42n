import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:l42n/data.dart';

import 'bloc.dart';
import 'translation_field.dart';

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

    return SliverStickyHeaderBuilder(
      builder: (context, state) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: state.isPinned ? 4 : 0,
        child: _HeaderRow(
          bloc: bloc,
          proportions: proportions,
        ),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return SizedBox(height: 8);
            }
            if (index.isEven) {
              return Divider();
            }

            return _TranslationRow(
              bloc: bloc,
              id: ids[index ~/ 2],
              proportions: proportions,
            );
          },
          childCount: 2 * bloc.ids.length + 1,
        ),
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
    final textStyle = Theme.of(context).textTheme.subtitle1;

    return SizedBox(
      height: 56,
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
        leading: StreamBuilder<List<L42nStringError>>(
          stream: string.errors,
          builder: (context, snapshot) {
            final errors = snapshot.data;
            if (errors?.isEmpty != false) {
              return SizedBox();
            }

            final sorted = errors.toList()
              ..sort((e1, e2) {
                return (e1.locale?.toString() ?? '')
                    .compareTo(e2.locale?.toString() ?? '');
              });
            return Tooltip(
              message: sorted
                  .map((e) =>
                      '• ${e.locale != null ? '${e.locale}: ' : ''}${e.message}')
                  .join('\n'),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: errors.any((e) => e.severity == ErrorSeverity.error)
                        ? Theme.of(context).errorColor
                        : Colors.yellow,
                  ),
                  width: 12,
                  height: 12,
                ),
              ),
            );
          },
        ),
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
    this.leading,
    @required this.cells,
    @required this.proportions,
  })  : assert(cells != null),
        assert(proportions != null),
        assert(cells.length == proportions.length),
        super(key: key);

  final Widget leading;
  final List<Widget> cells;
  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 32,
          height: 32,
          child: leading,
        ),
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
