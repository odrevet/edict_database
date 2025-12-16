import 'dart:io';
import 'common.dart';
import 'parse_expression.dart';

void writeEntityToBuffer(
    StringBuffer buffer,
    Map<String, List<Entity>> entities,
    String key,
    int maxInsert,
    ) => addSqlInsertToBuffer(
  buffer,
  key,
  entities[key]!.map((e) => [e.id, "'${e.name}'", "'${escape(e.description)}'"]),
  ["id", "name", "description"],
  maxInsert,
);

String formatSqlValue(dynamic value) {
  if (value == null) {
    return 'NULL';
  }
  if (value is String) {
    return "'${escape(value)}'";
  }
  return value.toString();
}

List<List<dynamic>> convertToSqlValues(List<List<dynamic>> values) {
  return values.map((row) {
    return row.map((val) {
      if (val == null) return 'NULL';
      if (val is String) return "'${escape(val)}'";
      return val.toString();
    }).toList();
  }).toList();
}

void main(List<String> args) {
  String langsArg = 'eng';
  int maxInsert = 1;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--langs' && i + 1 < args.length) {
      langsArg = args[i + 1];
      i++;
    } else if (args[i] == '--max-inserts' && i + 1 < args.length) {
      maxInsert = int.tryParse(args[i + 1]) ?? 1;
      i++;
    }
  }

  List<String> langs = langsArg.split(',').map((s) => s.trim()).toList();

  File('data/JMdict').readAsString().then((String contents) {
    final buffer = StringBuffer();

    // Write lang table
    addSqlInsertToBuffer(
      buffer,
      "lang",
      langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]),
      [],
      maxInsert,
    );

    // Parse XML document
    ParsedXmlData data = parseXmlDocument(contents, langs);

    print("writing entity tables...");
    writeEntityToBuffer(buffer, data.entities, "dial", maxInsert);
    writeEntityToBuffer(buffer, data.entities, "misc", maxInsert);
    writeEntityToBuffer(buffer, data.entities, "pos", maxInsert);
    writeEntityToBuffer(buffer, data.entities, "field", maxInsert);
    writeEntityToBuffer(buffer, data.entities, "ke_inf", maxInsert);
    writeEntityToBuffer(buffer, data.entities, "re_inf", maxInsert);

    print("writing SQL inserts...");

    // Write entry table
    addSqlInsertToBuffer(buffer, "entry", data.entSeqList, ["id"], maxInsert);

    // Write priority
    if (data.allPriorityValues.isNotEmpty) {
      var sqlValues = data.allPriorityValues.map((row) => [
        row[0],
        row[1],
        row[2] ?? 'NULL',
        row[3] ?? 'NULL',
        row[4] ?? 'NULL',
        row[5] ?? 'NULL',
        row[6] ?? 'NULL',
      ]).toList();
      addSqlInsertToBuffer(buffer, "pri", sqlValues, [], maxInsert);
    }

    // Write k_ele
    if (data.allKanjiValues.isNotEmpty) {
      var sqlValues = data.allKanjiValues.map((row) => [
        row[0],
        row[1],
        row[2] ?? 'NULL',
        "'${escape(row[3].toString())}'",
      ]).toList();
      addSqlInsertToBuffer(buffer, "k_ele", sqlValues, [], maxInsert);
    }

    // Write r_ele
    if (data.allReadingValues.isNotEmpty) {
      var sqlValues = data.allReadingValues.map((row) => [
        row[0],
        row[1],
        row[2] ?? 'NULL',
        "'${escape(row[3].toString())}'",
      ]).toList();
      addSqlInsertToBuffer(buffer, "r_ele", sqlValues, [], maxInsert);
    }

    // Write info relations
    List<List<dynamic>> allKanjiInfoValues = [];
    List<List<dynamic>> allReadingInfoValues = [];

    for (var infoRelation in data.allInfoRelations) {
      int elementId = infoRelation[0];
      String infoType = infoRelation[1];
      List<String> info = infoRelation[2];

      if (infoType == "ke_inf") {
        collectEntityRelation(allKanjiInfoValues, data.entities, infoType, elementId, info);
      } else if (infoType == "re_inf") {
        collectEntityRelation(allReadingInfoValues, data.entities, infoType, elementId, info);
      }
    }

    if (allKanjiInfoValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "k_ele_ke_inf", allKanjiInfoValues, [], maxInsert);
    }

    if (allReadingInfoValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "r_ele_re_inf", allReadingInfoValues, [], maxInsert);
    }

    // Write re_restr relations
    List<List<dynamic>> reRestrRows = [];
    data.allReRestrRelations.forEach((entSeq, reRestrHash) {
      reRestrHash.forEach((reb, kebList) {
        if (kebList == null && data.entryKEleMap.containsKey(entSeq)) {
          data.entryKEleMap[entSeq]!.forEach((keleId, keb) {
            reRestrRows.add([
              "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '${escape(reb)}')",
              keleId,
            ]);
          });
        } else if (kebList != null) {
          for (var keb in kebList) {
            reRestrRows.add([
              "(SELECT id from r_ele WHERE id_entry = $entSeq AND reb = '${escape(reb)}')",
              "(SELECT id from k_ele WHERE id_entry = $entSeq AND keb = '${escape(keb)}')",
            ]);
          }
        }
      });
    });

    if (reRestrRows.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "r_ele_k_ele", reRestrRows, [], maxInsert);
    }

    // Write sense
    if (data.allSenseValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "sense", data.allSenseValues, ["id", "id_entry"], maxInsert);
    }

    // Write sense relations
    if (data.allSensePosValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "sense_pos", data.allSensePosValues, [], maxInsert);
    }

    if (data.allSenseMiscValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "sense_misc", data.allSenseMiscValues, [], maxInsert);
    }

    if (data.allSenseDialValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "sense_dial", data.allSenseDialValues, [], maxInsert);
    }

    if (data.allSenseFieldValues.isNotEmpty) {
      addSqlInsertToBuffer(buffer, "sense_field", data.allSenseFieldValues, [], maxInsert);
    }

    // Write gloss
    if (data.allGlossValues.isNotEmpty) {
      var sqlValues = data.allGlossValues.map((row) => [
        row[0],
        row[1],
        "'${escape(row[2].toString())}'",
      ]).toList();
      addSqlInsertToBuffer(buffer, "gloss", sqlValues, ["id_sense", "id_lang", "content"], maxInsert);
    }

    // Write xref
    if (data.allXrefValues.isNotEmpty) {
      var sqlValues = data.allXrefValues.map((row) => [
        row[0],
        "'${escape(row[1].toString())}'",
        row[2] != null ? "'${escape(row[2].toString())}'" : "NULL",
        row[3] ?? "NULL",
      ]).toList();
      addSqlInsertToBuffer(buffer, "sense_xref", sqlValues, ["id_sense", "keb", "reb", "sense_number"], maxInsert);
    }

    // Write ant
    if (data.allAntValues.isNotEmpty) {
      var sqlValues = data.allAntValues.map((row) => [
        row[0],
        "'${escape(row[1].toString())}'",
        row[2] != null ? "'${escape(row[2].toString())}'" : "NULL",
        row[3] ?? "NULL",
      ]).toList();
      addSqlInsertToBuffer(buffer, "sense_ant", sqlValues, ["id_sense", "keb", "reb", "sense_number"], maxInsert);
    }

    print("writing output file...");
    final String filenameEntry = 'data/generated/sql/expression.sql';
    File(filenameEntry).writeAsStringSync(buffer.toString());
    print("done!");
  });
}
