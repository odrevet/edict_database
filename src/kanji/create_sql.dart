import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'kanji.dart';

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
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
        var attributesLang = attributes
            .where((attribute) => attribute.name.toString() == 'm_lang');
        String lang;

        if (attributesLang.isEmpty) {
          lang = "eng";
        } else {
          switch (attributesLang.first.value) {
            case 'fr':
              lang = 'fre';
              break;
            case 'es':
              lang = 'spa';
              break;
            case 'pt':
              lang = 'por';
              break;
            default:
              lang = attributesLang.first.value;
          }
        }

        if (langs.isEmpty || langs.contains(lang)) {
          meanings.add(Meaning(meaning: escape(meaning.text), lang: lang));
        }
      }

      //Add kanji to list
      kanjis.add(Kanji(
          character: literal,
          stroke:
              int.parse(character.findAllElements('stroke_count').first.text),
          radicals: radicals,
          on: on,
          kun: kun,
          meanings: meanings));
    }

    final buffer = StringBuffer();

    //Generate the SQL from the List of Kanji
    for (var kanji in kanjis) {
      buffer.write(
          "INSERT INTO kanji VALUES ('${kanji.character}', ${kanji.stroke});\n");

      if (kanji.radicals.isNotEmpty) {
        var values = <String>[];
        for (var radical in kanji.radicals) {
          values.add("('${kanji.character}', '$radical')");
        }
        buffer.write("INSERT INTO kanji_radical VALUES ");
        buffer.writeAll(values, ",");
        buffer.write(";\n");
      }

      if (kanji.on.isNotEmpty) {
        var values = <String>[];
        for (var on in kanji.on) {
          values.add("(NULL, '${kanji.character}', '$on')");
        }
        buffer.write("INSERT INTO on_yomi VALUES ");
        buffer.writeAll(values, ",");
        buffer.write(";\n");
      }

      if (kanji.kun.isNotEmpty) {
        var values = <String>[];
        for (var kun in kanji.kun) {
          values.add(" (NULL, '${kanji.character}', '$kun')");
        }

        buffer.write("INSERT INTO kun_yomi VALUES");
        buffer.writeAll(values, ",");
        buffer.write(";\n");
      }

      if (kanji.meanings.isNotEmpty) {
        var values = <String>[];
        for (var meaning in kanji.meanings) {
          values.add(
              "(NULL, '${kanji.character}', '${escape(meaning.meaning)}', '${meaning.lang}')");
        }
        buffer.write("INSERT INTO meaning VALUES ");
        buffer.writeAll(values, ",");
        buffer.write(";\n");
      }

      File(filename).writeAsStringSync(buffer.toString());
    }
  });
}
