import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'kanji.dart';
import '../common.dart';

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
      String literal = character.findAllElements('literal').first.text;

      //READINGS
      var on = <String>[];
      var kun = <String>[];
      var readingsDom = character.findAllElements('reading');
      for (var reading in readingsDom) {
        var attributes = reading.attributes;
        for (var attribute in attributes) {
          switch (attribute.value) {
            case 'ja_on':
              on.add(reading.text);
              break;
            case 'ja_kun':
              kun.add(reading.text);
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
          meanings.add(Meaning(meaning: escape(meaning.text), lang: lang));
        }
      }

      String freq = "NULL";
      var freqElement = character.findAllElements('freq');
      if (freqElement.isNotEmpty) {
        freq = freqElement.first.text;
      }

      String jlpt = "NULL";
      var jlptElement = character.findAllElements('jlpt');
      if (jlptElement.isNotEmpty) {
        jlpt = jlptElement.first.text;
      }

      //Add kanji to list
      kanjis.add(Kanji(
          character: literal,
          stroke: int.parse(character.findAllElements('stroke_count').first.text),
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
