import 'dart:io';

import 'package:flutter/material.dart';
import 'package:l42n/translation_grid.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';

class EditorPage extends StatefulWidget {
  const EditorPage(this.directory) : assert(directory != null);

  final Directory directory;

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project>(
      future: Project.forDirectory(widget.directory),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Text(snapshot.error.toString())
                : CircularProgressIndicator(),
          );
        }

        final project = snapshot.data;
        return Provider<Project>(
          create: (_) => project,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      title: Text('L42n'),
                    ),
                    _buildTopBar(),
                    TranslationGrid(filter: _filter),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SliverToBoxAdapter(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search',
                ),
                onChanged: (filter) => setState(() => _filter = filter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
