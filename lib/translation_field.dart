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
  }

  void _onDone() {
    print('Changing translation to ${_controller.text}');
    widget.translation.value = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Tooltip(
        message: widget.translation.value ?? 'Not translated yet.',
        child: EditableText(
          focusNode: focusNode,
          controller: _controller,
          autocorrect: true,
          scrollPadding: EdgeInsets.zero,
          minLines: 1,
          maxLines: 8,
          onChanged: (_) => _onDone,
          onEditingComplete: _onDone,
          style: Theme.of(context).textTheme.bodyText1,
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.green,
        ),
      ),
    );
  }
}
