import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l42n/new_resource_fab.dart';
import 'package:l42n/translation_grid.dart';
import 'package:provider/provider.dart';

import 'data/data.dart';
import 'search_bar.dart';

const addNewResourceKey = Key('add_new_resource');
const addNewResourceIntent = Intent(addNewResourceKey);

class AddNewResource extends Action {
  AddNewResource() : super(addNewResourceKey);

  @override
  void invoke(FocusNode node, Intent intent) {
    print('Adding a new resource'); // TODO: add a new resource
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage(this.directory) : assert(directory != null);

  final Directory directory;

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final shortcuts = {
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyN,
    ): addNewResourceIntent,
    LogicalKeySet(LogicalKeyboardKey.brightnessDown): addNewResourceIntent,
  };

  final Map<LocalKey, Action Function()> actions = {
    addNewResourceKey: () => AddNewResource(),
  };

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

        return Provider<Project>(
          create: (_) => snapshot.data,
          child: Actions(
            actions: actions,
            child: Shortcuts(
              shortcuts: shortcuts,
              child: Builder(builder: _buildContent),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.transparent,
            iconTheme:
                IconThemeData(color: Colors.black), // TODO: make adaptive
            actionsIconTheme:
                IconThemeData(color: Colors.black), // TODO: make adaptive
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.lightbulb_outline),
                onPressed: () {}, // TODO: switch between light and dark mode
              ),
            ],
          ),
          _buildTopBar(context),
          TranslationGrid(filter: _filter),
        ],
      ),
      floatingActionButton: NewResourceFab(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: TopDashboard(
        onFilterChanged: (filter) => setState(() => _filter = filter),
      ),
    );
  }
}

class TopDashboard extends StatelessWidget {
  const TopDashboard({this.onFilterChanged});

  final void Function(String) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildProjectName(context),
        SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: SearchBar(
            onChanged: onFilterChanged,
            suggestions: [
              SearchSuggestion('has errors', ':errors'),
              SearchSuggestion('has warning', ':warnings'),
              SearchSuggestion('missing translations', ':noTranslation'),
              SearchSuggestion('news', 'news'),
              SearchSuggestion('course', 'course'),
              SearchSuggestion('app', 'app'),
              SearchSuggestion('general', 'general'),
              SearchSuggestion('screen', 'screen'),
              SearchSuggestion('empty', 'empty'),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProjectName(BuildContext context) {
    return Text(
      'L42n',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline4.copyWith(
            color: Theme.of(context).primaryColor,
          ),
    );
  }
}
