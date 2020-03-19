import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';

@immutable
class SearchSuggestion {
  const SearchSuggestion(this.displayText, this.searchText);

  final String displayText;
  final String searchText;
}

/// The whole search bar, including suggestions.
class SearchBar extends StatefulWidget {
  const SearchBar({@required this.onChanged, this.suggestions = const []})
      : assert(onChanged != null, suggestions != null);

  final void Function(String) onChanged;
  final List<SearchSuggestion> suggestions;

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
              hintText: 'Search for ids or translations…',
            ),
            onChanged: widget.onChanged,
          ),
        ),
        _buildSuggestedSearchFilters(context),
      ],
    );
  }

  Widget _buildSuggestedSearchFilters(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 60,
          child: ListView(
            padding: EdgeInsets.only(left: 16, right: 8),
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final suggestion in widget.suggestions) ...[
                _SearchChip(
                  text: suggestion.displayText,
                  onTap: () {
                    _controller.text += ' ${suggestion.searchText}';
                    widget.onChanged(_controller.text);
                  },
                ),
                SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 30,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white.withOpacity(0)],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 30,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white.withOpacity(0), Colors.white],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({this.text, this.onTap}) : super();

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      elevation: 2,
      pressElevation: 6,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      onPressed: onTap,
    );
  }
}
