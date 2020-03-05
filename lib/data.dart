import 'dart:ui';

import 'package:meta/meta.dart';

@immutable
class L42nString {
  const L42nString(this.id, [this.translations = const {}])
      : assert(id != null),
        assert(translations != null);

  final String id;
  final Map<Locale, Translation> translations;
}

class Translation {
  Translation([this.value]);

  String value;
}
