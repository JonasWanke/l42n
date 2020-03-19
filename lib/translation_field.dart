import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';

class TranslationField extends StatelessWidget {
  const TranslationField(this.id, this.locale, {this.padding})
      : assert(id != null),
        assert(locale != null);

  final String id;
  final Locale locale;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final project = Provider.of<Project>(context);

    return StreamBuilder<String>(
      stream: project.translationBloc.get(id, locale),
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
    this.padding,
  })  : assert(id != null),
        assert(locale != null),
        assert(initialText != null);

  final String id;
  final Locale locale;
  final String initialText;
  final EdgeInsets padding;

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
      await Provider.of<Project>(context, listen: false)
          .translationBloc
          .set(widget.id, widget.locale, _controller.text);
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
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      child: Container(
        width: 200,
        color: Colors.transparent,
        padding: widget.padding,
        alignment: Alignment.center,
        child: EditableText(
          focusNode: _focusNode,
          controller: _controller,
          autocorrect: true,
          scrollPadding: EdgeInsets.symmetric(vertical: 100),
          minLines: 1,
          maxLines: null,
          style: context.textTheme.bodyText1,
          cursorColor: context.theme.primaryColor,
          backgroundCursorColor: Colors.green,
          cursorOpacityAnimates: true,
          cursorRadius: Radius.circular(1),
        ),
      ),
    );
  }
}
