import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';

const _fabSize = 56.0;
final _borderRadius = BorderRadius.circular(_fabSize * 0.5);

class NewResourceFab extends StatefulWidget {
  @override
  _NewResourceFabState createState() => _NewResourceFabState();
}

class _NewResourceFabState extends State<NewResourceFab> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  bool _isOpen = false;

  void _createNewResource(String id) async {
    await Provider.of<Project>(context, listen: false).resourceBloc.add(id);
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text('Added resource $id 👍'),
    ));
  }

  void _open() {
    setState(() {
      _isOpen = true;
      _controller.clear();
      _focusNode
        ..requestFocus()
        ..addListener(_onFocusChange);
    });
  }

  void _close() {
    setState(() {
      _isOpen = false;
      _focusNode.removeListener(_onFocusChange);

      if (_controller.text?.isNotEmpty ?? false) {
        _createNewResource(_controller.text);
      }
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.white,
      borderRadius: _borderRadius,
      child: Container(
        height: _fabSize,
        child: AnimatedCrossFade(
          firstChild: _buildFab(context),
          secondChild: _buildIdInput(context),
          sizeCurve: Curves.easeInOutExpo,
          crossFadeState:
              _isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      width: _fabSize,
      height: _fabSize,
      child: InkWell(
        borderRadius: _borderRadius,
        onTap: _open,
        child: Icon(Icons.add, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildIdInput(BuildContext context) {
    return Container(
      width: 300,
      height: _fabSize,
      alignment: Alignment.center,
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          hintText: 'New resource id',
        ),
      ),
      // child: InkWell(
      //   onTap: () => setState(() => _isOpen = false),
      //   child: Icon(Icons.add, color: Theme.of(context).primaryColor),
      // ),
    );
  }
}
