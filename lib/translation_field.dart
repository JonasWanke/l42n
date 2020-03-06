import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';

class TranslationField extends StatelessWidget {
  const TranslationField(this.id, this.locale)
      : assert(id != null),
        assert(locale != null);

  final String id;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);

    return StreamBuilder<String>(
      stream: project.getTranslation(id, locale),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final translation = snapshot.data;
        return EditableTranslationField(
          id: id,
          locale: locale,
          initialText: translation,
        );
      },
    );
  }
}

class EditableTranslationField extends StatefulWidget {
  const EditableTranslationField({
    @required this.id,
    @required this.locale,
    @required this.initialText,
  })  : assert(id != null),
        assert(locale != null),
        assert(initialText != null);

  final String id;
  final Locale locale;
  final String initialText;

  @override
  _EditableTranslationFieldState createState() =>
      _EditableTranslationFieldState();
}

class _EditableTranslationFieldState extends State<EditableTranslationField> {
  final _focusNode = FocusNode();
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() async {
    if (!_focusNode.hasFocus && _controller.text != widget.initialText) {
      // TODO(marcelgarus): don't save if the text remained the same
      final snackbar = Scaffold.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Text('Saving…'),
            Transform.scale(
              scale: 0.5,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
        duration: Duration(days: 1),
      ));
      await Provider.of<Project>(context, listen: false).setTranslation(
        widget.id,
        widget.locale,
        _controller.text,
      );
      print('Done.');
      snackbar.close();
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Saved 😊'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: EditableText(
        focusNode: _focusNode,
        controller: _controller,
        autocorrect: true,
        scrollPadding: EdgeInsets.zero,
        minLines: 1,
        maxLines: null,
        style: Theme.of(context).textTheme.bodyText1,
        cursorColor: Theme.of(context).primaryColor,
        backgroundCursorColor: Colors.green,
        cursorOpacityAnimates: true,
        cursorRadius: Radius.circular(1),
      ),
    );
  }
}
