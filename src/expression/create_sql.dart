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
        entities[key]!.map((e) => [e.id, "'${e.name}'", "'${escape(e.description)}'"]),
        ["id", "name", "description"]);

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
  var posesSensesTmp = senseElement.findAllElements(key);
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

Map<String, String> bindElementReRestr(XmlElement entry) {
  Map<String, String> reRestrHash = {};

  for (var element in entry.findAllElements('r_ele')) {
    String reb = element.findElements('reb').first.text;
    var reRestrElements = element.findAllElements('re_restr');
    if (reRestrElements.isEmpty) {
      // when re_restr is empty, apply reb to all keb without reb
      reRestrHash[''] = reb;
    } else {
      for (var reRestrElement in reRestrElements) {
        reRestrHash[reRestrElement.text] = reb;
      }
    }
  }

  return reRestrHash;
}

List<int> writeElementToBuffer(
    StringBuffer buffer,
    int idElement,
    int entSeq,
    int idPriority,
    XmlElement entry,
    Map<String, List<Entity>> entities,
    String type) {
  List<List<dynamic>> values = [];
  String tableName = '${type}_ele';
  for (var element in entry.findAllElements('${type}_ele')) {
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
    Map<String, String> priority = parsePriorityElement(element, '${type}e_pri');
    String insertedIdPriority = "NULL";
    if (priority.isNotEmpty) {
      writeInsertToBuffer(buffer, "pri", [
        [
          idPriority,
          idElement,
          priority['news'] ?? 'NULL',
          priority['ichi'] ?? 'NULL',
          priority['spec'] ?? 'NULL',
          priority['gai'] ?? 'NULL',
          priority['nf'] ?? 'NULL'
        ]
      ]);
      insertedIdPriority = idPriority.toString();
      idPriority++;
    }

    values.add([
      idElement,
      entSeq,
      insertedIdPriority,
      "'${element.findElements("${type}eb").first.text}'"
    ]);

    idElement++;
  }

  if (values.isNotEmpty) {
    // set id_r_ele when processing k_ele
    if (type == "k") {
      // init id_r_ele to null
      for (var value in values) {
        value.insert(2, 'NULL');
      }

      var reRestrHash = bindElementReRestr(entry);

      reRestrHash.forEach((reRestrKey, reRestrValue) {
        if (reRestrKey != '') {
          for (var value in values) {
            // compare keb with reRestr text
            if (value[4] == "'$reRestrKey'") {
              value[2] =
                  "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '$reRestrValue')";
            }
          }
        }
      });

      if (reRestrHash.containsKey('')) {
        for (var value in values) {
          // update all keb with null reRestr
          if (value[2] == 'NULL') {
            value[2] =
                "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '${reRestrHash['']}')";
          }
        }
      }
    }

    writeInsertToBuffer(buffer, tableName, values);
  }

  return [idElement, idPriority];
}

void main(List<String> args) {
  // langs to process are passed as arguments
  List<String> langs = args;

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    writeInsertToBuffer(
        buffer, "lang", langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]));

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
      writeEntityToBuffer(buffer, entities, "misc");
      writeEntityToBuffer(buffer, entities, "pos");
      writeEntityToBuffer(buffer, entities, "ke_inf");
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
      buffer.write('INSERT INTO entry values ($entSeq);\n');

      List<int> ids = [];

      // Reading Elements
      ids = writeElementToBuffer(buffer, idReading, entSeq, idPriority, entry, entities, "r");
      idReading = ids[0];
      idPriority = ids[1];

      // Kanji Elements
      ids = writeElementToBuffer(
          buffer, idKanji, entSeq, idPriority, entry, entities, "k");
      idKanji = ids[0];
      idPriority = ids[1];

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
          writeInsertToBuffer(buffer, "sense", [
            [idSense, entSeq]
          ], [
            "id",
            "id_entry",
          ]);

          poses = writeSenseRelationToBuffer(buffer, entities, "pos", sense, idSense, poses);
          misc = writeSenseRelationToBuffer(buffer, entities, "misc", sense, idSense, misc);
          dial = writeSenseRelationToBuffer(buffer, entities, "dial", sense, idSense, dial);

          List<List<dynamic>> glossValues = [];
          for (var gloss in glosses) {
            glossValues.add([idSense, langs.indexOf(lang) + 1, "'${escape(gloss.text)}'"]);
          }

          if (glossValues.isNotEmpty) {
            writeInsertToBuffer(buffer, "gloss", glossValues, ["id_sense", "id_lang", "content"]);
          }

          idSense++;
        }
      }
    }

    final String filenameEntry = 'data/generated/sql/expression.sql';
    File(filenameEntry).writeAsStringSync(buffer.toString());
  });
}
