import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';
import 'translation_row.dart';

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
            color: context.theme.colorScheme.surface,
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
                      return Divider(height: 0);
                    }

                    return TranslationRow(
                      id: ids[index ~/ 2],
                      proportions: proportions,
                      partsToHighlight: _filterParts,
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
    final textStyle = context.textTheme.subtitle1;

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
          child: GridRow(
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

class GridRow extends StatelessWidget {
  const GridRow({
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
    );
  }
}
