import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';
import 'translation_field.dart';

class TranslationGrid extends StatelessWidget {
  TranslationGrid({String filter = ''})
      : _filterParts = filter.trim().toLowerCase().split(RegExp(' +'));

  final List<String> _filterParts;

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);

    return StreamBuilder<List<Locale>>(
      stream: project.localeBloc.all,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverFillRemaining(
            child: Center(
              child: snapshot.hasError
                  ? Text(snapshot.error.toString())
                  : CircularProgressIndicator(),
            ),
          );
        }

        final locales = snapshot.data;
        final proportions = [
          1,
          for (final _ in locales) 1,
        ];
        return SliverStickyHeaderBuilder(
          builder: (context, state) => Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: state.isPinned ? 4 : 0,
            child: _HeaderRow(proportions: proportions),
          ),
          sliver: StreamBuilder<List<String>>(
            stream: project.resourceBloc.all,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverFillRemaining(
                  child: Center(
                    child: snapshot.hasError
                        ? Text(snapshot.error.toString())
                        : CircularProgressIndicator(),
                  ),
                );
              }

              final ids = snapshot.data.where(_applyFilter).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return SizedBox(height: 8);
                    }
                    if (index.isEven) {
                      return Divider();
                    }

                    return _TranslationRow(
                      id: ids[index ~/ 2],
                      proportions: proportions,
                    );
                  },
                  childCount: 2 * ids.length + 1,
                ),
              );
            },
          ),
        );
      },
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
    @required this.proportions,
  })  : assert(proportions != null),
        super(key: key);

  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);
    final textStyle = Theme.of(context).textTheme.subtitle1;

    return StreamBuilder<List<Locale>>(
      stream: project.localeBloc.all,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final titles = [
          'ID',
          for (final locale in snapshot.data) locale.toString(),
        ];
        return SizedBox(
          height: 56,
          child: _Row(
            proportions: proportions,
            cells: [
              for (final title in titles)
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: title, style: textStyle),
                    TextSpan(text: ' '),
                    TextSpan(
                      text: '(intl_$title.arb) – ${89} % complete',
                      style: textStyle.apply(
                          color: textStyle.color.withOpacity(0.26)),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({
    Key key,
    @required this.id,
    @required this.proportions,
  })  : assert(id != null),
        assert(proportions != null),
        super(key: key);

  final String id;
  final List<int> proportions;

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);

    return StreamBuilder<List<Locale>>(
      stream: project.localeBloc.all,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final locales = snapshot.data;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _Row(
            proportions: proportions,
            leading: StreamBuilder<List<L42nStringError>>(
              stream: project.errorBloc.allForResource(id),
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
                          '• ${e.locale != null ? '${e.locale}: ' : ''}${e.runtimeType}')
                      .join('\n'),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            errors.any((e) => e.severity == ErrorSeverity.error)
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
            trailing: Center(
              child: IconButton(
                icon: Icon(Icons.delete_outline),
                tooltip: 'Delete resource',
                onPressed: () {
                  // project.
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('Resource deleted.'),
                  ));
                },
              ),
            ),
            cells: [
              Text(id),
              for (final locale in locales) TranslationField(id, locale),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    Key key,
    this.leading,
    this.trailing = const SizedBox(),
    @required this.cells,
    @required this.proportions,
  })  : assert(cells != null),
        assert(proportions != null),
        assert(cells.length == proportions.length),
        super(key: key);

  final Widget leading;
  final Widget trailing;
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
        trailing,
      ],
    );
  }
}
