import 'package:flutter/material.dart';

class IdWithHighlightedParts extends StatelessWidget {
  IdWithHighlightedParts({
    @required this.id,
    this.partsToHighlight = const [],
  })  : assert(id != null),
        assert(partsToHighlight != null);

  final String id;
  final List<String> partsToHighlight;

  List<Part> match() {
    // Which characters to highlight.
    final highlights = [for (var i = 0; i < id.length; i++) false];

    for (final part in partsToHighlight) {
      for (final match in part.allMatches(id)) {
        for (var i = match.start; i < match.end; i++) {
          highlights[i] = true;
        }
      }
    }

    var cursor = 0;
    var currentlyHighlighting = highlights[0];
    var parts = <Part>[];

    while (++cursor < id.length) {
      if (highlights[cursor] != currentlyHighlighting) {
        parts.add(Part(
          start: parts.lastWhere((_) => true, orElse: () => null)?.end ?? 0,
          end: cursor,
          isHighlighted: currentlyHighlighting,
        ));
        currentlyHighlighting = !currentlyHighlighting;
      }
    }

    parts.add(Part(
      start: parts.lastWhere((_) => true, orElse: () => null)?.end ?? 0,
      end: cursor,
      isHighlighted: highlights.last,
    ));

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    // match();
    // return Text('${id} ${partsToHighlight} $matches $highlights');

    final parts = match();

    final normalStyle = DefaultTextStyle.of(context).style;
    final highlightStyle = normalStyle.copyWith(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
    );

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
