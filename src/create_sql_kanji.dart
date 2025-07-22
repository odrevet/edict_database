import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'common.dart';

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
  final String freq;
  final String jlpt;

  Kanji(
      {required this.character,
        required this.stroke,
        this.radicals = const [],
        this.on = const [],
        this.kun = const [],
        this.meanings = const [],
        required this.freq,
        required this.jlpt});

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      character: map['id'],
      stroke: map['stroke'],
      radicals: map['radicals']?.split(','),
      on: map['on_reading']?.split(','),
      kun: map['kun_reading']?.split(','),
      meanings: map['meanings']?.split(','),
      freq: map['freq'],
      jlpt: map['jlpt'],
    );
  }

  @override
  String toString() {
    return character;
  }
}

void main(List<String> args) async {
  // langs to process are passed as arguments. No arguments means all languages
  List<String> langs = args;

  String radkStr = await File('data/radkfile.json').readAsString();
  Map radkMap = jsonDecode(radkStr);

  final filename = 'data/generated/sql/kanji.sql';
  List<Kanji> kanjis = [];

  File('data/kanjidic2.xml').readAsString().then((String contents) {
    var document = XmlDocument.parse(contents);
    var characters = document.findAllElements('character');

    for (var character in characters) {
      String literal = character.findAllElements('literal').first.innerText;

      //READINGS
      var on = <String>[];
      var kun = <String>[];
      var readingsDom = character.findAllElements('reading');
      for (var reading in readingsDom) {
        var attributes = reading.attributes;
        for (var attribute in attributes) {
          switch (attribute.value) {
            case 'ja_on':
              on.add(reading.innerText);
              break;
            case 'ja_kun':
              kun.add(reading.innerText);
              break;
          }
        }
      }

      //RADICALS
      var radicals = <String>[];
      //search for radicals
      radkMap.forEach((radical, kanjiRadical) {
        if (kanjiRadical.toString().contains(literal)) {
          radicals.add(radical);
        }
      });

      //MEANINGS
      var meanings = <Meaning>[];
      var meaningsDom = character.findAllElements('meaning');
      for (var meaning in meaningsDom) {
        var attributes = meaning.attributes;
        var attributesLang = attributes.where((attribute) => attribute.name.toString() == 'm_lang');
        String lang;

        if (attributesLang.isEmpty) {
          lang = "en";
        } else {
          lang = attributesLang.first.value;
        }

        if (langs.contains(lang)) {
          meanings.add(Meaning(meaning: escape(meaning.innerText), lang: lang));
        }
      }

      String freq = "NULL";
      var freqElement = character.findAllElements('freq');
      if (freqElement.isNotEmpty) {
        freq = freqElement.first.innerText;
      }

      String jlpt = "NULL";
      var jlptElement = character.findAllElements('jlpt');
      if (jlptElement.isNotEmpty) {
        jlpt = jlptElement.first.innerText;
      }

      //Add kanji to list
      kanjis.add(Kanji(
          character: literal,
          stroke: int.parse(character.findAllElements('stroke_count').first.innerText),
          radicals: radicals,
          on: on,
          kun: kun,
          meanings: meanings,
          freq: freq,
          jlpt: jlpt));
    }

    final buffer = StringBuffer();

    writeInsertToBuffer(
        buffer, "lang", langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]));

    //Generate the SQL from the List of Kanji
    for (var kanji in kanjis) {
      writeInsertToBuffer(buffer, "character", [
        ["'${kanji.character}'", kanji.stroke, kanji.freq, kanji.jlpt]
      ]);

      if (kanji.radicals.isNotEmpty) {
        writeInsertToBuffer(buffer, "character_radical",
            kanji.radicals.map((radical) => ["'${kanji.character}'", "'$radical'"]));
      }

      if (kanji.on.isNotEmpty) {
        writeInsertToBuffer(
            buffer, "on_yomi", kanji.on.map((on) => ["NULL", "'${kanji.character}'", "'$on'"]));
      }

      if (kanji.kun.isNotEmpty) {
        writeInsertToBuffer(
            buffer, "kun_yomi", kanji.kun.map((kun) => ["NULL", "'${kanji.character}'", "'$kun'"]));
      }

      if (kanji.meanings.isNotEmpty) {
        writeInsertToBuffer(
            buffer,
            "meaning",
            kanji.meanings.map((meaning) => [
                  "NULL",
                  "'${kanji.character}'",
                  "'${langs.indexOf(meaning.lang) + 1}'",
                  "'${escape(meaning.meaning)}'",
                ]));
      }
    }

    File(filename).writeAsStringSync(buffer.toString());
  });
}
