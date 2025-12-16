import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

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

  Kanji({
    required this.character,
    required this.stroke,
    this.radicals = const [],
    this.on = const [],
    this.kun = const [],
    this.meanings = const [],
    required this.freq,
    required this.jlpt,
  });

  @override
  String toString() {
    return character;
  }
}

/// Parses the kanjidic2.xml file and returns a list of Kanji objects
///
/// [langs] - List of language codes to include in meanings (e.g., ['en', 'fr'])
/// [escapeFunction] - Optional function to escape special characters in meanings
Future<List<Kanji>> parseKanjiXml(
    List<String> langs, {
      String Function(String)? escapeFunction,
    }) async {
  print("loading radicals...");
  String radkStr = await File('data/radkfile.json').readAsString();
  Map radkMap = jsonDecode(radkStr);

  List<Kanji> kanjis = [];

  print("parsing kanji...");
  String contents = await File('data/kanjidic2.xml').readAsString();

  var document = XmlDocument.parse(contents);
  var characters = document.findAllElements('character');

  for (var character in characters) {
    String literal = character.findAllElements('literal').first.innerText;

    // READINGS
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

    // RADICALS
    var radicals = <String>[];
    radkMap.forEach((radical, kanjiRadical) {
      if (kanjiRadical.toString().contains(literal)) {
        radicals.add(radical);
      }
    });

    // MEANINGS
    var meanings = <Meaning>[];
    var meaningsDom = character.findAllElements('meaning');
    for (var meaning in meaningsDom) {
      var attributes = meaning.attributes;
      var attributesLang = attributes
          .where((attribute) => attribute.name.toString() == 'm_lang');
      String lang;

      if (attributesLang.isEmpty) {
        lang = "en";
      } else {
        lang = attributesLang.first.value;
      }

      if (langs.contains(lang)) {
        String meaningText = meaning.innerText;
        if (escapeFunction != null) {
          meaningText = escapeFunction(meaningText);
        }
        meanings.add(Meaning(meaning: meaningText, lang: lang));
      }
    }

    // FREQUENCY
    String freq = "NULL";
    var freqElement = character.findAllElements('freq');
    if (freqElement.isNotEmpty) {
      freq = freqElement.first.innerText;
    }

    // JLPT LEVEL
    String jlpt = "NULL";
    var jlptElement = character.findAllElements('jlpt');
    if (jlptElement.isNotEmpty) {
      jlpt = jlptElement.first.innerText;
    }

    // Add kanji to list
    kanjis.add(Kanji(
      character: literal,
      stroke: int.parse(
          character.findAllElements('stroke_count').first.innerText),
      radicals: radicals,
      on: on,
      kun: kun,
      meanings: meanings,
      freq: freq,
      jlpt: jlpt,
    ));
  }

  print("parsed ${kanjis.length} kanji characters");
  return kanjis;
}