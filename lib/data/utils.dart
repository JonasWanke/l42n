import 'dart:ui';

import 'package:sembast/sembast.dart';

extension FancyString on String {
  Locale parseLocale() {
    final parts = split(RegExp('[-_]'));
    assert(parts.length == 1,
        'We only support locales with only a language code for now.');
    return Locale(parts.first);
  }
}

extension FancyStoreRef on StoreRef {
  Stream<List<K>> streamKeys<K>(Database db, {Finder finder}) {
    return query(finder: finder)
        .onSnapshots(db)
        .map((list) => list.map((snapshot) => snapshot.key).cast<K>().toList());
  }
}
