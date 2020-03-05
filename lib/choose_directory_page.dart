import 'dart:io';

import 'package:flutter/material.dart';

import 'editor_page.dart';

class ChooseDirectoryPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _pathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('L42n'),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 384,
                child: TextFormField(
                  controller: _pathController,
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
                  final isValid = _formKey.currentState.validate();
                  if (!isValid) {
                    return;
                  }

                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => EditorPage(Directory(_pathController.text)),
                  ));
                },
                child: Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
