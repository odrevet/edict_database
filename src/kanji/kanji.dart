class Meaning {
  String meaning;
  String lang;

  Meaning({required this.meaning, required this.lang});
}

class Kanji {
  final String character;
  final int stroke;
  final List<String> radicals;
  final List<String> on;
  final List<String> kun;
  final List<Meaning> meanings;

  Kanji(
      {required this.character,
      required this.stroke,
      this.radicals = const [],
      this.on = const [],
      this.kun = const [],
      this.meanings = const []});

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      character: map['id'],
      stroke: map['stroke'],
      radicals: map['radicals']?.split(','),
      on: map['on_reading']?.split(','),
      kun: map['kun_reading']?.split(','),
      meanings: map['meanings']?.split(','),
    );
  }

  @override
  String toString() {
    return character;
  }
}
