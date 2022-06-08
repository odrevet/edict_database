import 'dart:io';

import 'package:xml/xml.dart';

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void main() {
  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();
    var document = XmlDocument.parse(contents);
    var entries = document.findAllElements('entry');
    int senseId = 0;
    for (var entry in entries) {
      int entSeq = int.parse(entry.findAllElements('ent_seq').first.text);
      String reb = entry.findAllElements('reb').first.text;
      var kebElements = entry.findAllElements('keb');
      String keb;

      if (kebElements.isNotEmpty) {
        keb = '"${kebElements.first.text}"';
      } else {
        keb = 'NULL';
      }

      buffer.write('INSERT INTO expression values ($entSeq,  $keb, "$reb");\n');

      // SENSES
      dynamic poses;
      var senses = entry.findAllElements('sense');
      for (var sense in senses) {
        //if the sense has no pos, take the poses of the previous sense
        var posesSense = sense.findAllElements('pos').toList();
        poses = posesSense.isEmpty ? poses : posesSense;

        String posesStr = '';
        poses.asMap().forEach((i, pos) {
          String posStr = pos.text.trim();
          posStr = posStr.substring(1, posStr.length - 1); //remove & and ;
          posesStr += posStr;

          if (i < poses.length - 1) posesStr += ',';
        });

        buffer.write(
            "INSERT INTO sense (id, id_expression, pos) VALUES ($senseId, $entSeq, '${escape(posesStr)}');\n");

        // GLOSSES
        var glosses = sense.findAllElements('gloss');
        String? lang;
        var glossValues = <String>[];
        for (var gloss in glosses) {
          var langAttr = gloss.attributes
              .where((attribute) => attribute.name.toString() == 'xml:lang');
          if (langAttr.isEmpty) {
            lang = 'eng';
          } else {
            lang = langAttr.first.value;
          }

          glossValues.add("($senseId, '$lang', '${escape(gloss.text)}')");
        }

        if (glossValues.isNotEmpty) {
          buffer.write("INSERT INTO gloss (id_sense, lang, gloss) VALUES ");
          buffer.writeAll(glossValues, ",");
          buffer.write(";\n");
        }

        senseId++;
      }
    }

    final String filenameExpression = 'data/generated/sql/expression.sql';
    File(filenameExpression).writeAsStringSync(buffer.toString());
  });
}
