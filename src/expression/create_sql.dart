import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import '../common.dart';

class Entity {
  int id;
  String type;
  String name;
  String description;

  Entity({required this.id, required this.type, required this.name, required this.description});
}

void writeEntityToBuffer(StringBuffer buffer, Map<String, List<Entity>> entities, String key) {
  if (entities[key] != null) {
    buffer.write("INSERT INTO $key (id, name, description) VALUES \n");
    buffer.writeAll(entities[key]!.map((e) => '(${e.id}, "${e.name}", "${e.description}")'), ",\n");
    buffer.write(";\n");
  }
}

void writeSenseEntityRelationToBuffer(StringBuffer buffer, Map<String, List<Entity>> entities,
    String key, int senseId, senseEntities) {
  List<String> relations = [];
  senseEntities.asMap().forEach((i, senseEntity) {
    String senseEntityStr = senseEntity.text.trim();
    senseEntityStr = senseEntityStr.substring(1, senseEntityStr.length - 1); //remove & and ;
    relations.add(
        "($senseId, ${entities[key]!.firstWhere((element) => element.name == senseEntityStr).id})");
  });

  writeInsertToBuffer(buffer, "sense_$key", relations);
}

void main(List<String> args) {
  // langs to process are passed as arguments
  List<String> langs = args;

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    buffer.write("INSERT INTO lang VALUES \n");
    buffer.writeAll(langs.asMap().entries.map((e) => '(${e.key + 1}, "${e.value}")'), ",");
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
            entities[key]!.add(Entity(id: index, type: key, name: m[1]!, description: m[2]!));
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

      // priority
      Map<String, String> priority = {};
      entry.findAllElements('re_pri').forEach((element) {
        RegExp exp = RegExp(r'(\w+?)(\d+)');
        Iterable<RegExpMatch> matches = exp.allMatches(element.innerText);
        if (exp.hasMatch(element.innerText)) {
          for (final m in matches) {
            priority[m[1]!] = m[2]!;
          }
        }
      });

      if (kebElements.isNotEmpty) {
        keb = '"${kebElements.first.text}"';
      } else {
        keb = 'NULL';
      }

      buffer.write(
          'INSERT INTO expression values ($entSeq,  $keb, "$reb", ${priority['news'] ?? "NULL"}, ${priority['ichi'] ?? "NULL"}, ${priority['gai'] ?? "NULL"}, ${priority['nf'] ?? "NULL"});\n');

      // SENSES
      dynamic poses;
      dynamic misc;
      dynamic dial;

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
        var langAttr =
            glosses.first.attributes.where((attribute) => attribute.name.toString() == 'xml:lang');
        if (langAttr.isEmpty) {
          lang = 'eng';
        } else {
          lang = langAttr.first.value;
        }

        if (langs.contains(lang)) {
          buffer.write(
              "INSERT INTO sense (id, id_expression, id_lang) VALUES ($senseId, $entSeq, ${langs.indexOf(lang) + 1});\n");

          var posesSensesTmp = sense.findAllElements('pos').toList();
          poses = posesSensesTmp.isEmpty ? poses : posesSensesTmp;
          if (poses != null && poses.isNotEmpty) {
            writeSenseEntityRelationToBuffer(buffer, entities, "pos", senseId, poses);
          }

          var miscSensesTmp = sense.findAllElements('misc').toList();
          misc = miscSensesTmp.isEmpty ? misc : miscSensesTmp;
          if (misc != null && misc.isNotEmpty) {
            writeSenseEntityRelationToBuffer(buffer, entities, "misc", senseId, misc);
          }

          var dialSensesTmp = sense.findAllElements('dial').toList();
          dial = dialSensesTmp.isEmpty ? dial : dialSensesTmp;
          if (dial != null && dial.isNotEmpty) {
            writeSenseEntityRelationToBuffer(buffer, entities, "dial", senseId, dial);
          }

          var glossValues = <String>[];
          for (var gloss in glosses) {
            glossValues.add("($senseId, '${escape(gloss.text)}')");
          }

          if (glossValues.isNotEmpty) {
            writeInsertToBuffer(buffer, "gloss", glossValues, "(id_sense, gloss)");
          }

          senseId++;
        }
      }
    }

    final String filenameExpression = 'data/generated/sql/expression.sql';
    File(filenameExpression).writeAsStringSync(buffer.toString());
  });
}
