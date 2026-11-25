import 'package:flutter/widgets.dart' show StringCharacters;

abstract final class PersonName {
  static final RegExp _spaces = RegExp(r'\s+');

  static Iterable<String> words(String name) =>
      name.trim().split(_spaces).where((word) => word.isNotEmpty);

  static String first(String name) => words(name).firstOrNull ?? '';

  static String initials(String name) =>
      words(name)
          .take(2)
          .map((word) => word.characters.first.toUpperCase())
          .join();
}
