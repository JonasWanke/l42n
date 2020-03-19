import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';
import 'id_with_highlighted_parts.dart';
import 'translation_field.dart';
import 'translation_grid.dart';

const _animationDuration = Duration(milliseconds: 200);
const _curve = Curves.easeInOutExpo;

class TranslationRow extends StatefulWidget {
  TranslationRow({
    @required this.id,
    @required this.proportions,
    this.partsToHighlight = const [],
  })  : assert(id != null),
        assert(proportions != null),
        super(key: Key(id));

  final String id;
  final List<int> proportions;
  final List<String> partsToHighlight;

  @override
  _TranslationRowState createState() => _TranslationRowState();
}

class _TranslationRowState extends State<TranslationRow> {
  final _focusNode = FocusNode();
  bool get _isFocused => _focusNode.hasFocus;

  Project get _project => Provider.of<Project>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Locale>>(
      stream: _project.localeBloc.all,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final locales = snapshot.data;
        return AnimatedPadding(
          duration: _animationDuration,
          curve: _curve,
          padding: EdgeInsets.symmetric(vertical: _isFocused ? 16 : 0),
          child: Focus(
            focusNode: _focusNode,
            child: Material(
              animationDuration: _animationDuration,
              color: Color.lerp(
                context.theme.scaffoldBackgroundColor,
                context.theme.primaryColor,
                _isFocused ? 0.05 : 0.0,
              ),
              elevation: _isFocused ? 4 : 0,
              child: InkWell(
                onTap: _focusNode.requestFocus,
                focusColor: Colors.transparent,
                hoverColor: _isFocused ? Colors.transparent : null,
                child: _buildRow(locales),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(List<Locale> locales) {
    return GridRow(
      proportions: widget.proportions,
      leading: _buildErrorDot(),
      cells: [
        _buildIdColumn(),
        for (final locale in locales)
          TranslationField(
            widget.id,
            locale,
            padding: EdgeInsets.symmetric(vertical: _isFocused ? 24 : 4),
          ),
      ],
      trailing: Center(
        child: IconButton(
          icon: Icon(Icons.delete_outline),
          tooltip: 'Delete resource.',
          onPressed: () async {
            await _project.resourceBloc.delete(widget.id);
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Resource ${widget.id} deleted.'),
            ));
          },
        ),
      ),
    );
  }

  Widget _buildErrorDot() {
    return StreamBuilder<List<L42nStringError>>(
      stream: _project.errorBloc.allForResource(widget.id),
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

        return ErrorDot(sorted);
      },
    );
  }

  Widget _buildIdColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 8),
        IdWithHighlightedParts(
          id: widget.id,
          partsToHighlight: widget.partsToHighlight.isNotEmpty
              ? widget.partsToHighlight
              : null,
        ),
        if (_isFocused) ...[
          SizedBox(height: 8),
          StreamBuilder<List<L42nStringError>>(
            stream: _project.errorBloc.allForResource(widget.id),
            builder: (context, snapshot) {
              final errors = snapshot.data;
              if (errors?.isEmpty != false) {
                return SizedBox();
              }

              final sorted = errors.toList(growable: false)
                ..sort((e1, e2) {
                  return (e1.locale?.toString() ?? '')
                      .compareTo(e2.locale?.toString() ?? '');
                });
              return ErrorList(sorted);
            },
          ),
        ],
        SizedBox(height: 8),
      ],
    );
  }
}

class ErrorDot extends StatelessWidget {
  ErrorDot(this.errors)
      : assert(errors != null),
        assert(errors.isNotEmpty);

  final List<L42nStringError> errors;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: errors
          .map((e) =>
              '• ${e.locale != null ? '${e.locale}: ' : ''}${e.runtimeType}')
          .join('\n'),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: errors.any((e) => e.severity == ErrorSeverity.error)
                ? context.theme.errorColor
                : Colors.yellow,
          ),
          width: 12,
          height: 12,
        ),
      ),
    );
  }
}

class ErrorList extends StatelessWidget {
  const ErrorList(this.errors);

  final List<L42nStringError> errors;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: context.theme.errorColor.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final error in errors) _buildError(error),
          ],
        ),
      ),
    );
  }

  Widget _buildError(L42nStringError error) {
    return Text(
        '• ${error.locale != null ? '${error.locale}: ' : ''}${error.runtimeType}');
  }
}
