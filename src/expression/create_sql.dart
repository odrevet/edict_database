import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

class Entity {
  int id;
  String type;
  String name;
  String description;

  Entity(
      {required this.id,
      required this.type,
      required this.name,
      required this.description});
}

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void writeEntityToBuffer(
    StringBuffer buffer, Map<String, List<Entity>> entities, String key) {
  if (entities[key] != null) {
    buffer.write("INSERT INTO $key (id, name, description) VALUES \n");
    buffer.writeAll(
        entities[key]!.map((e) => '(${e.id}, "${e.name}", "${e.description}")'),
        ",\n");
    buffer.write(";\n");
  }
}

void main(List<String> args) {
  // langs to process are passed as arguments
  List<String> langs = args;

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    buffer.write("INSERT INTO lang VALUES \n");
    buffer.writeAll(
        langs.asMap().entries.map((e) => '(${e.key + 1}, "${e.value}")'), ",");
    buffer.write(";\n");

    print("parsing...");
    var document = XmlDocument.parse(contents);

    XmlDoctype? doctypeElement = document.doctypeElement;

    // parse entities
    Map<String, List<Entity>> entities = {};
    String key = "";
    if (doctypeElement != null) {
      int index = 1;
      LineSplitter ls = LineSplitter();

      ls.convert(doctypeElement.internalSubset!).forEach((element) {
        RegExp exp = RegExp(r'ENTITY (.*) "(.*)"');
        RegExp expType = RegExp(r'<!-- <(.*)> \((.*)\) entities -->');

        if (expType.hasMatch(element)) {
          Iterable<RegExpMatch> matches = expType.allMatches(element);
          for (final m in matches) {
            key = m[1]!;
            entities[key] = [];

            print("entity: $key");
          }

          index = 1;
        }

        if (exp.hasMatch(element)) {
          Iterable<RegExpMatch> matches = exp.allMatches(element);
          for (final m in matches) {
            entities[key]!.add(
                Entity(id: index, type: key, name: m[1]!, description: m[2]!));
          }
          index++;
        }
      });

      writeEntityToBuffer(buffer, entities, "dial");
      writeEntityToBuffer(buffer, entities, "ke_inf");
      writeEntityToBuffer(buffer, entities, "misc");
      writeEntityToBuffer(buffer, entities, "pos");
      writeEntityToBuffer(buffer, entities, "re_inf");
    }

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
        // GLOSSES
        var glosses = sense.findAllElements('gloss');
        String? lang;

        if (glosses.isEmpty) {
          continue;
        }

        // check lang attribute of the first gloss
        // assume every gloss in this sense has the same lang
        var langAttr = glosses.first.attributes
            .where((attribute) => attribute.name.toString() == 'xml:lang');
        if (langAttr.isEmpty) {
          lang = 'eng';
        } else {
          lang = langAttr.first.value;
        }

        if (langs.contains(lang)) {
          buffer.write(
              "INSERT INTO sense (id, id_expression, id_lang) VALUES ($senseId, $entSeq, ${langs.indexOf(lang) + 1});\n");

          // pos or previous sense pos when empty
          var posesSense = sense.findAllElements('pos').toList();
          poses = posesSense.isEmpty ? poses : posesSense;

          List<String> sensePos = [];
          poses.asMap().forEach((i, pos) {
            String posStr = pos.text.trim();
            posStr = posStr.substring(1, posStr.length - 1); //remove & and ;
            sensePos.add(
                "($senseId, ${entities['pos']!.firstWhere((element) => element.name == posStr).id})");
          });

          buffer.write("INSERT INTO sense_pos VALUES");
          buffer.writeAll(sensePos, ",");
          buffer.write(";\n");

          var glossValues = <String>[];
          for (var gloss in glosses) {
            glossValues.add("($senseId, '${escape(gloss.text)}')");
          }

          if (glossValues.isNotEmpty) {
            buffer.write("INSERT INTO gloss (id_sense, gloss) VALUES ");
            buffer.writeAll(glossValues, ",");
            buffer.write(";\n");
          }

          senseId++;
        }
      }
    }

    final String filenameExpression = 'data/generated/sql/expression.sql';
    File(filenameExpression).writeAsStringSync(buffer.toString());
  });
}
