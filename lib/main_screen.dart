import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bloc.dart';
import 'editor.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Directory _directory;
  bool get _isDirOpened => _directory != null;

  final _noDirOpenedFormKey = GlobalKey<FormState>();
  final _noDirPathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (!_isDirOpened) {
      return _buildNoFolderContent(context);
    }

    return FutureBuilder(
      future: Bloc.from(_directory),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? snapshot.error.toString()
                : CircularProgressIndicator(),
          );
        }

        return Provider<Bloc>(
          create: (_) => snapshot.data,
          child: Editor(),
        );
      },
    );
  }

  Widget _buildNoFolderContent(BuildContext context) {
    return Center(
      child: Form(
        key: _noDirOpenedFormKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 384,
              child: TextFormField(
                controller: _noDirPathController,
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
                final isValid = _noDirOpenedFormKey.currentState.validate();
                if (!isValid) {
                  return;
                }

                setState(() {
                  _directory = Directory(_noDirPathController.text);
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
