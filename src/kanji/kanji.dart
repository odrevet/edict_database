class Meaning {
  String meaning;
  String lang;

  Meaning({this.meaning, this.lang});
}

class Kanji {
  final String character;
  final int stroke;
  final List<String> radicals;
  final List<String> on;
  final List<String> kun;
  final List<Meaning> meanings;

  Kanji(
      {this.character,
      this.stroke,
      this.radicals = const [],
      this.on = const [],
      this.kun = const [],
      this.meanings = const []});

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      character: map['id'],
      stroke: map['stroke'],
      radicals: map['radicals'] != null ? map['radicals'].split(',') : null,
      on: map['on_reading'] != null ? map['on_reading'].split(',') : null,
      kun: map['kun_reading'] != null ? map['kun_reading'].split(',') : null,
      meanings: map['meanings'] != null ? map['meanings'].split(',') : null,
    );
  }

  String toString() {
    return character;
  }
}
