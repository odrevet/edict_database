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

void writeEntityToBuffer(StringBuffer buffer, Map<String, List<Entity>> entities, String key) =>
    writeInsertToBuffer(
        buffer,
        key,
        entities[key]!.map((e) => [e.id, "'${e.name}'", "'${e.description}'"]).toList(),
        "(id, name, description)");

void writeRelationToBuffer(StringBuffer buffer, Map<String, List<Entity>> entities, String key,
    int id, entitiesToWrite, String tableName) {
  List<List<dynamic>> relations = [];
  entitiesToWrite.forEach((entryEntity) {
    String entryEntityStr = entryEntity.trim();
    entryEntityStr = entryEntityStr.substring(1, entryEntityStr.length - 1); //remove & and ;
    relations.add([id, entities[key]!.firstWhere((element) => element.name == entryEntityStr).id]);
  });

  writeInsertToBuffer(buffer, tableName, relations);
}

Iterable<String>? writeSenseRelationToBuffer(
    StringBuffer buffer,
    Map<String, List<Entity>> entities,
    String key,
    XmlElement senseElement,
    int senseId,
    Iterable<String>? senseEntities) {
  var posesSensesTmp = senseElement.findAllElements(key).toList();
  senseEntities = posesSensesTmp.isEmpty ? senseEntities : posesSensesTmp.map((e) => e.text);
  if (senseEntities != null && senseEntities.isNotEmpty) {
    writeRelationToBuffer(buffer, entities, key, senseId, senseEntities, "sense_$key");
  }
  return senseEntities;
}

Map<String, String> parsePriorityElement(XmlElement parent, String tagName) {
  Map<String, String> priority = {};
  parent.findAllElements(tagName).forEach((priorityElement) {
    RegExp exp = RegExp(r'(\w+?)(\d+)');
    Iterable<RegExpMatch> matches = exp.allMatches(priorityElement.innerText);
    if (exp.hasMatch(priorityElement.innerText)) {
      for (final m in matches) {
        priority[m[1]!] = m[2]!;
      }
    }
  });

  return priority;
}

int writeElementToBuffer(StringBuffer buffer, int idElement, int entSeq, XmlElement entry,
    Map<String, List<Entity>> entities, String type) {
  List<List<dynamic>> values = [];
  String tableName = type == 'k' ? 'kanji' : 'reading';
  for (var element in entry.findAllElements('${type}_ele')) {
    values.add([idElement, entSeq, 'NULL', "'${element.findElements("${type}eb").first.text}'"]);

    //info
    List<String> info = [];
    element.findAllElements('${type}e_inf').forEach((element) {
      info.add(element.innerText);
    });

    if (info.isNotEmpty) {
      writeRelationToBuffer(
          buffer, entities, "${type}e_inf", idElement, info, "${tableName}_${type}e_inf");
    }

    // priority
    /*Map<String, String> priority = parsePriorityElement(element, '${type}e_pri');
    if (priority.isNotEmpty) {
      buffer.write(
          "INSERT INTO priority VALUES ($idPriority, ${priority['news'] ?? 'NULL'}, ${priority['ichi'] ?? 'NULL'}, ${priority['gai'] ?? 'NULL'}, ${priority['nf'] ?? 'NULL'});\n");
      idPriority++;
    }*/

    idElement++;
  }

  if (values.isNotEmpty) {
    writeInsertToBuffer(buffer, tableName, values);
  }

  return idElement;
}

void main(List<String> args) {
  // langs to process are passed as arguments
  List<String> langs = args;

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    writeInsertToBuffer(
        buffer, "lang", langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]).toList());

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
    int idSense = 1;
    int idKanji = 1;
    int idReading = 1;
    int idPriority = 1;

    // Entries
    for (var entry in entries) {
      int entSeq = int.parse(entry.findAllElements('ent_seq').first.text);
      buffer.write('INSERT INTO expression values ($entSeq);\n');

      // Kanji Elements
      idKanji = writeElementToBuffer(buffer, idKanji, entSeq, entry, entities, "k");

      // Reading Elements
      idReading = writeElementToBuffer(buffer, idReading, entSeq, entry, entities, "r");

      // Senses
      Iterable<String>? poses;
      Iterable<String>? misc;
      Iterable<String>? dial;

      var senses = entry.findAllElements('sense');

      for (var sense in senses) {
        // glosses
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
              "INSERT INTO sense (id, id_expression, id_lang) VALUES ($idSense, $entSeq, ${langs.indexOf(lang) + 1});\n");

          poses = writeSenseRelationToBuffer(buffer, entities, "pos", sense, idSense, poses);
          misc = writeSenseRelationToBuffer(buffer, entities, "misc", sense, idSense, misc);
          dial = writeSenseRelationToBuffer(buffer, entities, "dial", sense, idSense, dial);

          List<List<dynamic>> glossValues = [];
          for (var gloss in glosses) {
            glossValues.add([idSense, "'${escape(gloss.text)}'"]);
          }

          if (glossValues.isNotEmpty) {
            writeInsertToBuffer(buffer, "gloss", glossValues, "(id_sense, gloss)");
          }

          idSense++;
        }
      }
    }

    final String filenameExpression = 'data/generated/sql/expression.sql';
    File(filenameExpression).writeAsStringSync(buffer.toString());
  });
}
