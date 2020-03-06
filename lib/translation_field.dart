import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart';

class TranslationField extends StatefulWidget {
  const TranslationField(this.id, this.locale)
      : assert(id != null),
        assert(locale != null);

  final String id;
  final Locale locale;

  @override
  _TranslationFieldState createState() => _TranslationFieldState();
}

class _TranslationFieldState extends State<TranslationField> {
  TextEditingController _controller;
  final _focusNode = FocusNode();

  void _onDone(Project project) {
    print('Changing translation to ${_controller.text}');
    project.setTranslation(widget.id, widget.locale, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);

    return StreamBuilder<String>(
      stream: project.getTranslation(widget.id, widget.locale),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final translation = snapshot.data;
        _controller = TextEditingController(text: translation);
        return Container(
          width: 200,
          child: Tooltip(
            message: translation ?? 'Not translated yet.',
            child: EditableText(
              focusNode: _focusNode,
              controller: _controller,
              autocorrect: true,
              scrollPadding: EdgeInsets.zero,
              minLines: 1,
              maxLines: 8,
              onChanged: (_) => _onDone(project),
              onEditingComplete: () => _onDone(project),
              style: Theme.of(context).textTheme.bodyText1,
              cursorColor: Colors.red,
              backgroundCursorColor: Colors.green,
            ),
          ),
        );
      },
    );
  }
}
