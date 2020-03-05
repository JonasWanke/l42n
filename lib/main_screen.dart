import 'dart:io';

import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Directory _folder;
  bool get _isFolderOpened => _folder != null;

  final _noFolderOpenedFormKey = GlobalKey<FormState>();
  final _noFolderFolderController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (!_isFolderOpened) {
      return _buildNoFolderContent(context);
    }

    return Center(
        child: Text((_folder.listSync().first as File).readAsStringSync()));
  }

  Widget _buildNoFolderContent(BuildContext context) {
    return Center(
      child: Form(
        key: _noFolderOpenedFormKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 384,
              child: TextFormField(
                controller: _noFolderFolderController,
                validator: (value) {
                  final type = FileSystemEntity.typeSync(value);
                  if (type == FileSystemEntityType.notFound) {
                    return "The specified path doesn't exist.";
                  }
                  if (type != FileSystemEntityType.directory) {
                    return "The specified path isn't a directory";
                  }

                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: () {
                final isValid = _noFolderOpenedFormKey.currentState.validate();
                if (!isValid) {
                  return;
                }

                setState(() {
                  _folder = Directory(_noFolderFolderController.text);
                });
              },
              child: Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
