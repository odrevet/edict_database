import 'dart:io';
import 'package:xml/xml.dart' as xml;

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void main() {
  File('data/JMdict').readAsString().then((String contents) {
      final String filenameExpression = 'data/generated/sql/expression.sql';
    var document = xml.parse(contents);
    var entries = document.findAllElements('entry');
    int senseId = 0;
    entries.forEach((entry) {
      int entSeq = int.parse(entry.findAllElements('ent_seq').first.text);
      String reb = entry.findAllElements('reb').first.text;
      var kebElements = entry.findAllElements('keb');
      String keb;

      if (kebElements.isNotEmpty)
        keb = '"${kebElements.first.text}"';
      else
        keb = 'NULL';

      String sqlExp = 'INSERT INTO expression values ($entSeq,  $keb, "$reb");';
      File(filenameExpression)
          .writeAsStringSync('$sqlExp\n', mode: FileMode.append);

      // SENSES
      var poses;
      var senses = entry.findAllElements('sense');
      senses.forEach((sense) {
        var glosses = sense.findAllElements('gloss');
        String lang;
        glosses.forEach((gloss) {
          var langAttr = gloss.attributes
              .where((attribute) => attribute.name.toString() == 'xml:lang');
          if (langAttr.isEmpty)
            lang = 'eng';
          else
            lang = langAttr.first.value;
        });

        //if the sense has no pos, take the poses of the previous sense
        var posesSense = sense.findAllElements('pos').toList();
        poses = posesSense.isEmpty ? poses : posesSense;
        if(lang == null)lang = 'eng';

        String glossesStr = '';
        glosses.forEach((gloss) => glossesStr += gloss.text.replaceAll(';', ' ') + ';');

        String posesStr = '';
        poses.asMap().forEach((i, pos) {
          String posStr = pos.text.trim();
          posStr = posStr.substring(1, posStr.length - 1);   //remove & and ;
          posesStr += posStr;

          if (i < poses.length - 1) posesStr += ',';
        });

        String sqlSense =
            "INSERT INTO sense (id, id_expression, glosses, pos, lang) VALUES ($senseId, $entSeq, '${escape(glossesStr)}', '${escape(posesStr)}', '$lang');\n";
        File(filenameExpression).writeAsStringSync(
            '$sqlSense',
            mode: FileMode.append);

        senseId++;
      });
    });
  });
}
