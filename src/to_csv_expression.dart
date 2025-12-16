import 'dart:io';
import 'parse_expression.dart';

String escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String formatCsvValue(dynamic value) {
  if (value == null || value == 'NULL') {
    return '';
  }

  String str = value.toString();
  if (str.startsWith("'") && str.endsWith("'")) {
    str = str.substring(1, str.length - 1);
  }

  return escapeCsv(str);
}

void writeCsvFile(
  String tableName,
  List<String> headers,
  List<List<dynamic>> rows,
) {
  final file = File('data/generated/csv/expression/$tableName.csv');
  file.createSync(recursive: true);

  final buffer = StringBuffer();
  buffer.writeln(headers.join(','));

  for (var row in rows) {
    buffer.writeln(row.map((v) => formatCsvValue(v)).join(','));
  }

  file.writeAsStringSync(buffer.toString());
  print('Written: $tableName.csv (${rows.length} rows)');
}

void main(List<String> args) {
  String langsArg = 'eng';

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--langs' && i + 1 < args.length) {
      langsArg = args[i + 1];
      i++;
    }
  }

  List<String> langs = langsArg.split(',').map((s) => s.trim()).toList();

  File('data/JMdict').readAsString().then((String contents) {
    // Parse XML document
    ParsedXmlData data = parseXmlDocument(contents, langs);

    print("writing entity tables...");

    // Write lang CSV
    writeCsvFile('lang', [
      'id',
      'code',
    ], langs.asMap().entries.map((e) => [e.key + 1, e.value]).toList());

    // Write entity CSVs
    for (var entityKey in [
      'dial',
      'misc',
      'pos',
      'field',
      'ke_inf',
      're_inf',
    ]) {
      if (data.entities.containsKey(entityKey)) {
        writeCsvFile(
          entityKey,
          ['id', 'name', 'description'],
          data.entities[entityKey]!
              .map((e) => [e.id, e.name, e.description])
              .toList(),
        );
      }
    }

    print("writing CSV files...");

    // Write entry CSV
    writeCsvFile('entry', ['id'], data.entSeqList);

    // Write priority CSV
    if (data.allPriorityValues.isNotEmpty) {
      writeCsvFile('pri', [
        'id',
        'id_entry',
        'news',
        'ichi',
        'spec',
        'gai',
        'nf',
      ], data.allPriorityValues);
    }

    // Write k_ele CSV
    if (data.allKanjiValues.isNotEmpty) {
      writeCsvFile('k_ele', [
        'id',
        'id_entry',
        'id_pri',
        'keb',
      ], data.allKanjiValues);
    }

    // Write r_ele CSV
    if (data.allReadingValues.isNotEmpty) {
      writeCsvFile('r_ele', [
        'id',
        'id_entry',
        'id_pri',
        'reb',
      ], data.allReadingValues);
    }

    // Write info relations
    List<List<dynamic>> allKanjiInfoValues = [];
    List<List<dynamic>> allReadingInfoValues = [];

    for (var infoRelation in data.allInfoRelations) {
      int elementId = infoRelation[0];
      String infoType = infoRelation[1];
      List<String> info = infoRelation[2];

      if (infoType == "ke_inf") {
        collectEntityRelation(
          allKanjiInfoValues,
          data.entities,
          infoType,
          elementId,
          info,
        );
      } else if (infoType == "re_inf") {
        collectEntityRelation(
          allReadingInfoValues,
          data.entities,
          infoType,
          elementId,
          info,
        );
      }
    }

    if (allKanjiInfoValues.isNotEmpty) {
      writeCsvFile('k_ele_ke_inf', [
        'id_k_ele',
        'id_ke_inf',
      ], allKanjiInfoValues);
    }

    if (allReadingInfoValues.isNotEmpty) {
      writeCsvFile('r_ele_re_inf', [
        'id_r_ele',
        'id_re_inf',
      ], allReadingInfoValues);
    }

    // Write re_restr relations
    List<List<dynamic>> reRestrRows = [];
    data.allReRestrRelations.forEach((entSeq, reRestrHash) {
      reRestrHash.forEach((reb, kebList) {
        // Get id_r_ele for this reb
        int? idREle = data.entryREleMap[entSeq]?.entries
            .firstWhere((e) => e.value == reb, orElse: () => MapEntry(-1, ''))
            .key;

        if (idREle != null && idREle != -1) {
          if (kebList == null && data.entryKEleMap.containsKey(entSeq)) {
            data.entryKEleMap[entSeq]!.forEach((keleId, keb) {
              reRestrRows.add([idREle, keleId]);
            });
          } else if (kebList != null) {
            // Specific restrictions - link only to specified kanji
            for (var keb in kebList) {
              int? idKEle = data.entryKEleMap[entSeq]?.entries
                  .firstWhere(
                    (e) => e.value == keb,
                    orElse: () => MapEntry(-1, ''),
                  )
                  .key;

              if (idKEle != null && idKEle != -1) {
                reRestrRows.add([idREle, idKEle]);
              }
            }
          }
        }
      });
    });
    

    if (reRestrRows.isNotEmpty) {
      writeCsvFile('r_ele_k_ele', [
        'id_entry_r',
        'id_entry_k',
      ], reRestrRows);
    }

    // Write sense CSV
    if (data.allSenseValues.isNotEmpty) {
      writeCsvFile('sense', ['id', 'id_entry'], data.allSenseValues);
    }

    // Write sense relations
    if (data.allSensePosValues.isNotEmpty) {
      writeCsvFile('sense_pos', ['id_sense', 'id_pos'], data.allSensePosValues);
    }

    if (data.allSenseMiscValues.isNotEmpty) {
      writeCsvFile('sense_misc', [
        'id_sense',
        'id_misc',
      ], data.allSenseMiscValues);
    }

    if (data.allSenseDialValues.isNotEmpty) {
      writeCsvFile('sense_dial', [
        'id_sense',
        'id_dial',
      ], data.allSenseDialValues);
    }

    if (data.allSenseFieldValues.isNotEmpty) {
      writeCsvFile('sense_field', [
        'id_sense',
        'id_field',
      ], data.allSenseFieldValues);
    }

    // Write gloss CSV
    if (data.allGlossValues.isNotEmpty) {
      writeCsvFile('gloss', [
        'id_sense',
        'id_lang',
        'content',
      ], data.allGlossValues);
    }

    // Write xref and ant CSVs
    if (data.allXrefValues.isNotEmpty) {
      writeCsvFile('sense_xref', [
        'id_sense',
        'keb',
        'reb',
        'sense_number',
      ], data.allXrefValues);
    }

    if (data.allAntValues.isNotEmpty) {
      writeCsvFile('sense_ant', [
        'id_sense',
        'keb',
        'reb',
        'sense_number',
      ], data.allAntValues);
    }

    print("done!");
  });
}
