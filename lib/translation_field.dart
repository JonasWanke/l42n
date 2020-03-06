import 'package:flutter/material.dart';

import 'data.dart';

class TranslationField extends StatefulWidget {
  const TranslationField(this.translation);

  final Translation translation;

  @override
  _TranslationFieldState createState() => _TranslationFieldState();
}

class _TranslationFieldState extends State<TranslationField> {
  TextEditingController _controller;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.translation.value);
    focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      print('User just left the field!');

      // TODO(marcelgarus): don't save if the text remained the same
      widget.translation.value = _controller.text;
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Saving…'),
        duration: Duration(milliseconds: 800),
      ));
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
        focusNode: focusNode,
        controller: _controller,
        autocorrect: true,
        scrollPadding: EdgeInsets.zero,
        minLines: 1,
        maxLines: 9223372036854775807, // 2^63-1 (the largest possible integer)
        style: Theme.of(context).textTheme.bodyText1,
        cursorColor: Theme.of(context).primaryColor,
        backgroundCursorColor: Colors.green,
        cursorOpacityAnimates: true,
        cursorRadius: Radius.circular(1),
      ),
    );
  }
}
