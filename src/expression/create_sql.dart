import 'dart:io';

import 'package:xml/xml.dart';

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void main() {
  File('data/JMdict').readAsString().then((String contents) {
    final String filenameExpression = 'data/generated/sql/expression.sql';
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

      String sqlExp = 'INSERT INTO expression values ($entSeq,  $keb, "$reb");';
      File(filenameExpression)
          .writeAsStringSync('$sqlExp\n', mode: FileMode.append);

      // SENSES
      var poses;
      var senses = entry.findAllElements('sense');
      for (var sense in senses) {
        var glosses = sense.findAllElements('gloss');
        String? lang;
        for (var gloss in glosses) {
          var langAttr = gloss.attributes
              .where((attribute) => attribute.name.toString() == 'xml:lang');
          if (langAttr.isEmpty) {
            lang = 'eng';
          } else {
            lang = langAttr.first.value;
          }
        }

        //if the sense has no pos, take the poses of the previous sense
        var posesSense = sense.findAllElements('pos').toList();
        poses = posesSense.isEmpty ? poses : posesSense;
        lang ??= 'eng';

        String glossesStr = '';
        for (var gloss in glosses) {
          glossesStr += '${gloss.text.replaceAll(';', ' ')};';
        }

        String posesStr = '';
        poses.asMap().forEach((i, pos) {
          String posStr = pos.text.trim();
          posStr = posStr.substring(1, posStr.length - 1); //remove & and ;
          posesStr += posStr;

          if (i < poses.length - 1) posesStr += ',';
        });

        String sqlSense =
            "INSERT INTO sense (id, id_expression, glosses, pos, lang) VALUES ($senseId, $entSeq, '${escape(glossesStr)}', '${escape(posesStr)}', '$lang');\n";
        File(filenameExpression)
            .writeAsStringSync(sqlSense, mode: FileMode.append);

        senseId++;
      }
    }
  });
}
