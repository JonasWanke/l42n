import 'package:flutter/material.dart';

class IdWithHighlightedParts extends StatelessWidget {
  const IdWithHighlightedParts({this.id, this.partsToHighlight});

  final String id;
  final List<String> partsToHighlight;

  List<Part> match() {
    // Which characters to highlight.
    final highlights = [for (var i = 0; i < id.length; i++) false];

    for (final part in partsToHighlight) {
      for (final match in id.allMatches(part)) {
        for (var i = match.start; i < match.end; i++) {
          highlights[i] = true;
        }
      }
    }

    var cursor = 1;
    var currentlyHighlighting = highlights[0];
    var parts = <Part>[];

    while (cursor < id.length) {
      if (highlights[cursor] != currentlyHighlighting) {
        final start =
            parts.lastWhere((_) => true, orElse: () => null)?.end ?? 0;
        final end = cursor;
        parts.add(Part(
          start: start,
          end: end,
          isHighlighted: currentlyHighlighting,
        ));
        currentlyHighlighting = !currentlyHighlighting;
      }
    }

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final parts = match();

    final normalStyle = TextStyle();
    final highlightStyle = TextStyle(backgroundColor: Colors.yellow);

    return RichText(
        text: TextSpan(
      children: [
        for (final part in parts)
          TextSpan(
            text: id.substring(part.start, part.end),
            style: part.isHighlighted ? highlightStyle : normalStyle,
          ),
      ],
    ));
  }
}

class Part {
  const Part({
    @required this.start,
    @required this.end,
    @required this.isHighlighted,
  });

  final int start;
  final int end;
  final bool isHighlighted;
}
