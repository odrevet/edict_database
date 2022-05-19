import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'kanji.dart';

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void main() async {
  String radkStr = await File('data/radkfile.json').readAsString();
  Map radkMap = jsonDecode(radkStr);

  final filename = 'data/generated/sql/kanji.sql';
  List<Kanji> kanjis = [];

  File('data/kanjidic2.xml').readAsString().then((String contents) {
    // remove doctype
    contents = contents.replaceRange(
        contents.indexOf('<!DOCTYPE'), contents.indexOf('<kanjidic2>'), '');

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

        meanings.add(Meaning(meaning: escape(meaning.text), lang: lang));
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

    //Generate the SQL from the List of Kanji
    for (var kanji in kanjis) {
      String sql =
          "INSERT INTO kanji VALUES ('${kanji.character}', ${kanji.stroke});\n";

      if (kanji.radicals.isNotEmpty) {
        sql += "INSERT INTO kanji_radical VALUES \n";
        kanji.radicals.asMap().forEach((i, String radical) {
          sql += "('${kanji.character}', '$radical')";
          if (i < kanji.radicals.length - 1) sql += ',\n';
        });
        sql += ";\n";
      }

      if (kanji.on.isNotEmpty) {
        sql += 'INSERT INTO on_yomi VALUES \n';
        kanji.on.asMap().forEach((i, String on) {
          sql += "(NULL, '${kanji.character}', '$on')";
          if (i < kanji.on.length - 1) sql += ',\n';
        });
        sql += ';\n';
      }

      if (kanji.kun.isNotEmpty) {
        sql += "INSERT INTO kun_yomi VALUES \n";
        kanji.kun.asMap().forEach((i, String kun) {
          sql += " (NULL, '${kanji.character}', '$kun')";
          if (i < kanji.kun.length - 1) sql += ',\n';
        });
        sql += ";\n";
      }

      if (kanji.meanings.isNotEmpty) {
        sql += "INSERT INTO meaning VALUES \n";
        kanji.meanings.asMap().forEach((i, Meaning meaning) {
          sql +=
              "(NULL, '${kanji.character}', '${escape(meaning.meaning)}', '${meaning.lang}')";
          if (i < kanji.meanings.length - 1) sql += ',\n';
        });
        sql += ";\n";
      }

      File(filename).writeAsStringSync(sql, mode: FileMode.append);
    }
  });
}
