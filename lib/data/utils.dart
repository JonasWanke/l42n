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
  Stream<List<K>> streamKeys<K>(Database db) {
    return query()
        .onSnapshots(db)
        .map((list) => list.map((snapshot) => snapshot.key).cast<K>().toList());
  }
}

extension FancyFilter on Filter {
  Filter operator &(Filter other) => Filter.and([this, other]);
  Filter operator |(Filter other) => Filter.or([this, other]);
}
