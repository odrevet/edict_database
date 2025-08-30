import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'common.dart';

class ParsedReference {
  String keb;
  String? reb;
  int? senseNumber;
  
  ParsedReference({
    required this.keb,
    this.reb,
    this.senseNumber,
  });
}

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

void writeEntityToBuffer(
        StringBuffer buffer, Map<String, List<Entity>> entities, String key) =>
    writeInsertToBuffer(
        buffer,
        key,
        entities[key]!
            .map((e) => [e.id, "'${e.name}'", "'${escape(e.description)}'"]),
        ["id", "name", "description"]);

void writeEntityRelationToBuffer(
        StringBuffer buffer,
        Map<String, List<Entity>> entities,
        String key,
        int id,
        Iterable<String> entitiesToWrite,
        String tableName) =>
    writeInsertToBuffer(buffer, tableName, entitiesToWrite.map((entity) {
      String entryEntityStr = entity.trim();
      entryEntityStr = entryEntityStr.substring(
          1, entryEntityStr.length - 1); //remove & and ;
      return [
        id,
        entities[key]!
            .firstWhere((element) => element.name == entryEntityStr)
            .id
      ];
    }));

/// write sense relation table (e.g sense_misc, sense_pos, sense_dial)
Iterable<String>? writeSenseRelationToBuffer(
    StringBuffer buffer,
    Map<String, List<Entity>> entities,
    String key,
    XmlElement senseElement,
    int senseId,
    Iterable<String>? senseEntities) {
  var posesSensesTmp = senseElement.findAllElements(key);
  senseEntities = posesSensesTmp.isEmpty
      ? senseEntities
      : posesSensesTmp.map((e) => e.innerText);
  if (senseEntities != null && senseEntities.isNotEmpty) {
    writeEntityRelationToBuffer(
        buffer, entities, key, senseId, senseEntities, "sense_$key");
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

bool isPureDigits(String text) {
  if (text.isEmpty) return false;
  
  for (int i = 0; i < text.length; i++) {
    int codeUnit = text.codeUnitAt(i);
    // ASCII digits (0-9)
    bool isAsciiDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    // Fullwidth digits (０-９)
    bool isFullwidthDigit = codeUnit >= 0xFF10 && codeUnit <= 0xFF19;
    
    if (!isAsciiDigit && !isFullwidthDigit) {
      return false;
    }
  }
  
  return true;
}

ParsedReference parseReference(String refText) {
  String trimmed = refText.trim();
  List<String> parts = trimmed.split('・');
  
  String keb = parts[0];
  String? reb;
  int? senseNumber;
  
  if (parts.length == 1) {
    // Pattern: just primary text
  }
  else if (parts.length == 2) {
    String secondPart = parts[1];
    
    if (isPureDigits(secondPart)) {
      // Pattern: primary・sense_number
      senseNumber = int.tryParse(secondPart);
    } else {
      // Pattern: primary・reading  
      reb = secondPart;
    }
  }
  else if (parts.length == 3) {
    // Pattern: primary・reading・sense_number
    reb = parts[1];
    senseNumber = int.tryParse(parts[2]);
  }
  
  return ParsedReference(
    keb: keb,
    reb: reb,
    senseNumber: senseNumber,
  );
}

void writeXrefAntToBuffer(StringBuffer buffer, XmlElement sense, int senseId) {
  // Process cross-references
  for (var xrefElement in sense.findAllElements('xref')) {
    String xrefText = xrefElement.innerText;
    ParsedReference parsed = parseReference(xrefText);

    String sqlGetRefIdSense = "(SELECT sense.id FROM sense JOIN entry ON entry.id = sense.id_entry JOIN k_ele ON entry.id = k_ele.id_entry WHERE k_ele.keb = '${parsed.keb}' LIMIT 1)";

    List<dynamic> values = [
      "NULL", // id (auto-increment)
      senseId,
      sqlGetRefIdSense,
      "'${escape(parsed.keb)}'",
      parsed.reb != null ? "'${escape(parsed.reb!)}'" : "NULL",
      parsed.senseNumber ?? "NULL"
    ];
    
    writeInsertToBuffer(buffer, "sense_xref", [values]);
  }
  
  // Process antonyms
  for (var antElement in sense.findAllElements('ant')) {
    String antText = antElement.innerText;
    ParsedReference parsed = parseReference(antText);
    String sqlGetRefIdSense = "(SELECT sense.id FROM sense JOIN entry ON entry.id = sense.id_entry JOIN k_ele ON entry.id = k_ele.id_entry WHERE k_ele.keb = '${parsed.keb}' LIMIT 1)";

    List<dynamic> values = [
      "NULL", // id (auto-increment)
      senseId,
      sqlGetRefIdSense,
      "'${escape(parsed.keb)}'",
      parsed.reb != null ? "'${escape(parsed.reb!)}'" : "NULL",
      parsed.senseNumber ?? "NULL"
    ];
    
    writeInsertToBuffer(buffer, "sense_ant", [values]);
  }
}

Map<String, List<String>?> bindElementReRestr(XmlElement entry) {
  Map<String, List<String>?> reRestrHash = {};

  for (var element in entry.findAllElements('r_ele')) {
    String reb = element.findElements('reb').first.innerText;
    var reRestrElements = element.findElements('re_restr');
    if (reRestrElements.isEmpty) {
      if (element.findElements('re_nokanji').isEmpty) {
        reRestrHash[reb] = null;
      }
    } else {
      reRestrHash[reb] = [];
      for (var reRestrElement in reRestrElements) {
        reRestrHash[reb]!.add(reRestrElement.innerText);
      }
    }
  }

  return reRestrHash;
}

List<dynamic> writeElementToBuffer(
    StringBuffer buffer,
    int idElement,
    int entSeq,
    int idPriority,
    XmlElement entry,
    Map<String, List<Entity>> entities,
    String type,
    List<List<dynamic>>? kEle) {
  List<List<dynamic>> values = [];
  String tableName = '${type}_ele';
  for (var element in entry.findAllElements('${type}_ele')) {
    //info
    List<String> info = [];
    element.findAllElements('${type}e_inf').forEach((element) {
      info.add(element.innerText);
    });
    if (info.isNotEmpty) {
      writeEntityRelationToBuffer(buffer, entities, "${type}e_inf", idElement,
          info, "${tableName}_${type}e_inf");
    }

    // priority
    Map<String, String> priority =
        parsePriorityElement(element, '${type}e_pri');
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
      "'${element.findElements("${type}eb").first.innerText}'"
    ]);

    idElement++;
  }

  if (values.isNotEmpty) {
    writeInsertToBuffer(buffer, tableName, values);

    if (type == "r") {
      var reRestrHash = bindElementReRestr(entry);
      reRestrHash.forEach((reRestrReb, reRestrKebList) {
        if (reRestrKebList == null && kEle != null) {
          for (var k in kEle) {
            writeInsertToBuffer(buffer, "r_ele_k_ele", [
              [
                "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '$reRestrReb')",
                k[0]
              ]
            ]);
          }
        } else {
          for (var reRestrKeb in reRestrKebList!) {
            writeInsertToBuffer(buffer, "r_ele_k_ele", [
              [
                "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '$reRestrReb')",
                "(SELECT id from k_ele WHERE id_entry = $entSeq AND keb = '$reRestrKeb')"
              ]
            ]);
          }
        }
      });
    }
  }

  return [idElement, idPriority, values];
}

void main(List<String> args) {
  // langs to process are passed as arguments
  List<String> langs = args;

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    writeInsertToBuffer(buffer, "lang",
        langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]));

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
        RegExp expType = RegExp(r'<!-- <(.*)>.*entities -->');

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
      writeEntityToBuffer(buffer, entities, "misc");
      writeEntityToBuffer(buffer, entities, "pos");
      writeEntityToBuffer(buffer, entities, "field");
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
      int entSeq = int.parse(entry.findAllElements('ent_seq').first.innerText);
      buffer.write('INSERT INTO entry values ($entSeq);\n');

      List<dynamic> ids = [];

      // Kanji Elements
      ids = writeElementToBuffer(
          buffer, idKanji, entSeq, idPriority, entry, entities, "k", null);
      idKanji = ids[0];
      idPriority = ids[1];

      // Reading Elements
      ids = writeElementToBuffer(
          buffer, idReading, entSeq, idPriority, entry, entities, "r", ids[2]);
      idReading = ids[0];
      idPriority = ids[1];

      // Senses
      Iterable<String>? poses;
      Iterable<String>? misc;
      Iterable<String>? dial;
      Iterable<String>? field;

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
        var langAttr = glosses.first.attributes
            .where((attribute) => attribute.name.toString() == 'xml:lang');
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

          poses = writeSenseRelationToBuffer(
              buffer, entities, "pos", sense, idSense, poses);
          misc = writeSenseRelationToBuffer(
              buffer, entities, "misc", sense, idSense, misc);
          dial = writeSenseRelationToBuffer(
              buffer, entities, "dial", sense, idSense, dial);
          field = writeSenseRelationToBuffer(
              buffer, entities, "field", sense, idSense, field);

          List<List<dynamic>> glossValues = [];
          for (var gloss in glosses) {
            glossValues.add([
              idSense,
              langs.indexOf(lang) + 1,
              "'${escape(gloss.innerText)}'"
            ]);
          }

          if (glossValues.isNotEmpty) {
            writeInsertToBuffer(buffer, "gloss", glossValues,
                ["id_sense", "id_lang", "content"]);
          }

          // Process cross-references and antonyms
          writeXrefAntToBuffer(buffer, sense, idSense);

          idSense++;
        }
      }
    }

    final String filenameEntry = 'data/generated/sql/expression.sql';
    File(filenameEntry).writeAsStringSync(buffer.toString());
  });
}
