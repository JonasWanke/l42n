import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';
import 'id_with_highlighted_parts.dart';
import 'translation_field.dart';
import 'translation_grid.dart';

class TranslationRow extends StatefulWidget {
  const TranslationRow({
    Key key,
    @required this.id,
    @required this.proportions,
    this.partsToHighlight = const [],
  })  : assert(id != null),
        assert(proportions != null),
        super(key: key);

  final String id;
  final List<int> proportions;
  final List<String> partsToHighlight;

  @override
  _TranslationRowState createState() => _TranslationRowState();
}

class _TranslationRowState extends State<TranslationRow> {
  bool _isSelected = false;

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
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: _isSelected ? 4 : 0,
          child: GridRow(
            proportions: widget.proportions,
            leading: _buildIssueDot(),
            trailing: Center(
              child: IconButton(
                icon: Icon(Icons.delete_outline),
                tooltip: 'Delete resource',
                onPressed: () {
                  // project.
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('Resource ${widget.id} deleted.'),
                  ));
                },
              ),
            ),
            cells: [
              IdWithHighlightedParts(
                id: widget.id,
                partsToHighlight: widget.partsToHighlight.isNotEmpty
                    ? widget.partsToHighlight
                    : null,
              ),
              for (final locale in locales) TranslationField(widget.id, locale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssueDot() {
    final project = Provider.of<Project>(context);

    return StreamBuilder<List<L42nStringError>>(
      stream: project.errorBloc.allForResource(widget.id),
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
    );
  }
}
