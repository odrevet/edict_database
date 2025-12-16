import 'dart:convert';
import 'package:xml/xml.dart';

class ParsedReference {
  String keb;
  String? reb;
  int? senseNumber;

  ParsedReference({required this.keb, this.reb, this.senseNumber});
}

class Entity {
  int id;
  String type;
  String name;
  String description;

  Entity({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
  });
}

class ParsedXmlData {
  Map<String, List<Entity>> entities;
  List<List<dynamic>> entSeqList;
  List<List<dynamic>> allSenseValues;
  List<List<dynamic>> allSensePosValues;
  List<List<dynamic>> allSenseMiscValues;
  List<List<dynamic>> allSenseDialValues;
  List<List<dynamic>> allSenseFieldValues;
  List<List<dynamic>> allGlossValues;
  List<List<dynamic>> allKanjiValues;
  List<List<dynamic>> allInfoRelations;
  List<List<dynamic>> allReadingValues;
  Map<int, Map<String, List<String>?>> allReRestrRelations;
  Map<int, Map<int, String>> entryKEleMap;
  Map<int, Map<int, String>> entryREleMap;
  List<List<dynamic>> allPriorityValues;
  List<List<dynamic>> allXrefValues;
  List<List<dynamic>> allAntValues;

  ParsedXmlData({
    required this.entities,
    required this.entSeqList,
    required this.allSenseValues,
    required this.allSensePosValues,
    required this.allSenseMiscValues,
    required this.allSenseDialValues,
    required this.allSenseFieldValues,
    required this.allGlossValues,
    required this.allKanjiValues,
    required this.allInfoRelations,
    required this.allReadingValues,
    required this.allReRestrRelations,
    required this.entryKEleMap,
    required this.entryREleMap,
    required this.allPriorityValues,
    required this.allXrefValues,
    required this.allAntValues,
  });
}

void collectEntityRelation(
    List<List<dynamic>> collectedValues,
    Map<String, List<Entity>> entities,
    String key,
    int id,
    Iterable<String> entitiesToWrite,
    ) {
  for (var entity in entitiesToWrite) {
    String entryEntityStr = entity.trim();
    entryEntityStr = entryEntityStr.substring(1, entryEntityStr.length - 1); //remove & and ;
    int entityId = entities[key]!.firstWhere((element) => element.name == entryEntityStr).id;
    collectedValues.add([id, entityId]);
  }
}

Iterable<String>? collectSenseRelation(
    List<List<dynamic>> collectedValues,
    Map<String, List<Entity>> entities,
    String key,
    XmlElement senseElement,
    int senseId,
    Iterable<String>? senseEntities,
    ) {
  var posesSensesTmp = senseElement.findAllElements(key);
  senseEntities = posesSensesTmp.isEmpty ? senseEntities : posesSensesTmp.map((e) => e.innerText);
  if (senseEntities != null && senseEntities.isNotEmpty) {
    collectEntityRelation(collectedValues, entities, key, senseId, senseEntities);
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
    bool isAsciiDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
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
  } else if (parts.length == 2) {
    String secondPart = parts[1];

    if (isPureDigits(secondPart)) {
      senseNumber = int.tryParse(secondPart);
    } else {
      reb = secondPart;
    }
  } else if (parts.length == 3) {
    reb = parts[1];
    senseNumber = int.tryParse(parts[2]);
  }

  return ParsedReference(keb: keb, reb: reb, senseNumber: senseNumber);
}

void collectXrefAnt(
    List<List<dynamic>> collectedValues,
    String type,
    XmlElement sense,
    int senseId,
    ) {
  for (var element in sense.findAllElements(type)) {
    String text = element.innerText;
    ParsedReference parsed = parseReference(text);

    List<dynamic> values = [
      senseId,
      parsed.keb,
      parsed.reb,
      parsed.senseNumber,
    ];

    collectedValues.add(values);
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

List<dynamic> collectElementData(
    List<List<dynamic>> allElementValues,
    List<List<dynamic>> allInfoRelations,
    Map<int, Map<String, List<String>?>> allReRestrRelations,
    List<List<dynamic>> allPriorityValues,
    int idElement,
    int entSeq,
    int idPriority,
    XmlElement entry,
    Map<String, List<Entity>> entities,
    String type,
    Map<int, String>? kEleMap,
    ) {
  List<List<dynamic>> values = [];
  Map<int, String> elementMap = {};

  for (var element in entry.findAllElements('${type}_ele')) {
    String elementText = element.findElements("${type}eb").first.innerText;

    // info - collect
    List<String> info = [];
    element.findAllElements('${type}e_inf').forEach((element) {
      info.add(element.innerText);
    });
    if (info.isNotEmpty) {
      allInfoRelations.add([idElement, "${type}e_inf", info]);
    }

    // priority
    Map<String, String> priority = parsePriorityElement(element, '${type}e_pri');
    int? insertedIdPriority;
    if (priority.isNotEmpty) {
      allPriorityValues.add([
        idPriority,
        entSeq,
        priority['news'],
        priority['ichi'],
        priority['spec'],
        priority['gai'],
        priority['nf'],
      ]);
      insertedIdPriority = idPriority;
      idPriority++;
    }

    values.add([
      idElement,
      entSeq,
      insertedIdPriority,
      elementText,
    ]);

    elementMap[idElement] = elementText;
    idElement++;
  }

  if (values.isNotEmpty) {
    allElementValues.addAll(values);

    if (type == "r") {
      var reRestrHash = bindElementReRestr(entry);
      allReRestrRelations[entSeq] = reRestrHash;
    }
  }

  return [idElement, idPriority, elementMap];
}

Map<String, List<Entity>> parseEntities(XmlDoctype doctypeElement) {
  Map<String, List<Entity>> entities = {};
  String key = "";
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
          Entity(id: index, type: key, name: m[1]!, description: m[2]!),
        );
      }
      index++;
    }
  });

  return entities;
}

ParsedXmlData parseXmlDocument(String contents, List<String> langs) {
  print("parsing...");
  var document = XmlDocument.parse(contents);
  XmlDoctype? doctypeElement = document.doctypeElement;

  // Parse entities
  Map<String, List<Entity>> entities = parseEntities(doctypeElement!);

  print("processing entries...");
  var entries = document.findAllElements('entry');
  int idSense = 1;
  int idKanji = 1;
  int idReading = 1;
  int idPriority = 1;

  // Collect all entry IDs
  List<List<dynamic>> entSeqList = [];
  for (var entry in entries) {
    entSeqList.add([int.parse(entry.findAllElements('ent_seq').first.innerText)]);
  }

  // Collect all data
  List<List<dynamic>> allSenseValues = [];
  List<List<dynamic>> allSensePosValues = [];
  List<List<dynamic>> allSenseMiscValues = [];
  List<List<dynamic>> allSenseDialValues = [];
  List<List<dynamic>> allSenseFieldValues = [];
  List<List<dynamic>> allGlossValues = [];
  List<List<dynamic>> allKanjiValues = [];
  List<List<dynamic>> allInfoRelations = [];
  List<List<dynamic>> allReadingValues = [];
  Map<int, Map<String, List<String>?>> allReRestrRelations = {};
  List<List<dynamic>> allPriorityValues = [];
  List<List<dynamic>> allXrefValues = [];
  List<List<dynamic>> allAntValues = [];
  Map<int, Map<int, String>> entryKEleMap = {};
  Map<int, Map<int, String>> entryREleMap = {};

  // Entries
  for (var entry in entries) {
    int entSeq = int.parse(entry.findAllElements('ent_seq').first.innerText);
    List<dynamic> ids = [];

    // Kanji Elements
    ids = collectElementData(
      allKanjiValues,
      allInfoRelations,
      allReRestrRelations,
      allPriorityValues,
      idKanji,
      entSeq,
      idPriority,
      entry,
      entities,
      "k",
      null,
    );
    idKanji = ids[0];
    idPriority = ids[1];
    Map<int, String> kEleMap = ids[2];
    entryKEleMap[entSeq] = kEleMap;

    // Reading Elements
    ids = collectElementData(
      allReadingValues,
      allInfoRelations,
      allReRestrRelations,
      allPriorityValues,
      idReading,
      entSeq,
      idPriority,
      entry,
      entities,
      "r",
      kEleMap,
    );
    idReading = ids[0];
    idPriority = ids[1];
    Map<int, String> rEleMap = ids[2];
    entryREleMap[entSeq] = rEleMap;

    // Senses
    Iterable<String>? poses;
    Iterable<String>? misc;
    Iterable<String>? dial;
    Iterable<String>? field;

    var senses = entry.findAllElements('sense');

    for (var sense in senses) {
      var glosses = sense.findAllElements('gloss');
      String? lang;

      if (glosses.isEmpty) {
        continue;
      }

      var langAttr = glosses.first.attributes.where(
            (attribute) => attribute.name.toString() == 'xml:lang',
      );
      if (langAttr.isEmpty) {
        lang = 'eng';
      } else {
        lang = langAttr.first.value;
      }

      if (langs.contains(lang)) {
        allSenseValues.add([idSense, entSeq]);

        poses = collectSenseRelation(allSensePosValues, entities, "pos", sense, idSense, poses);
        misc = collectSenseRelation(allSenseMiscValues, entities, "misc", sense, idSense, misc);
        dial = collectSenseRelation(allSenseDialValues, entities, "dial", sense, idSense, dial);
        field = collectSenseRelation(allSenseFieldValues, entities, "field", sense, idSense, field);

        for (var gloss in glosses) {
          allGlossValues.add([
            idSense,
            langs.indexOf(lang) + 1,
            gloss.innerText,
          ]);
        }

        collectXrefAnt(allXrefValues, 'xref', sense, idSense);
        collectXrefAnt(allAntValues, 'ant', sense, idSense);

        idSense++;
      }
    }
  }

  return ParsedXmlData(
    entities: entities,
    entSeqList: entSeqList,
    allSenseValues: allSenseValues,
    allSensePosValues: allSensePosValues,
    allSenseMiscValues: allSenseMiscValues,
    allSenseDialValues: allSenseDialValues,
    allSenseFieldValues: allSenseFieldValues,
    allGlossValues: allGlossValues,
    allKanjiValues: allKanjiValues,
    allInfoRelations: allInfoRelations,
    allReadingValues: allReadingValues,
    allReRestrRelations: allReRestrRelations,
    entryKEleMap: entryKEleMap,
    entryREleMap: entryREleMap,
    allPriorityValues: allPriorityValues,
    allXrefValues: allXrefValues,
    allAntValues: allAntValues,
  );
}