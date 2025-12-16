import 'dart:io';

import 'parse_kanji.dart';

String escapeCsv(String value) {
  // Always wrap in quotes and escape internal quotes by doubling them
  return '"${value.replaceAll('"', '""')}"';
}

String formatCsvValue(dynamic value) {
  if (value == null || value == 'NULL') {
    return '';
  }

  String str = value.toString();
  // Remove surrounding quotes if present (from SQL format)
  if (str.startsWith("'") && str.endsWith("'")) {
    str = str.substring(1, str.length - 1);
  }

  return escapeCsv(str);
}

String formatCsvNumber(dynamic value) {
  if (value == null || value == 'NULL') {
    return '';
  }
  return value.toString();
}

void writeCsvFile(
    String tableName,
    List<String> headers,
    List<List<dynamic>> rows,
    {List<bool>? isNumeric}
    ) {
  final file = File('data/generated/csv/kanji/$tableName.csv');
  file.createSync(recursive: true);

  final buffer = StringBuffer();

  // Write header
  buffer.writeln(headers.join(','));

  // Write rows
  for (var row in rows) {
    List<String> formattedRow = [];
    for (int i = 0; i < row.length; i++) {
      if (isNumeric != null && i < isNumeric.length && isNumeric[i]) {
        formattedRow.add(formatCsvNumber(row[i]));
      } else {
        formattedRow.add(formatCsvValue(row[i]));
      }
    }
    buffer.writeln(formattedRow.join(','));
  }

  file.writeAsStringSync(buffer.toString());
  print('Written: $tableName.csv (${rows.length} rows)');
}

void main(List<String> args) async {
  // Parse named arguments
  String langsArg = 'en'; // default

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--langs' && i + 1 < args.length) {
      langsArg = args[i + 1];
      i++;
    }
  }

  // Parse comma-separated languages
  List<String> langs = langsArg.split(',').map((s) => s.trim()).toList();

  // Parse kanji data from XML
  List<Kanji> kanjis = await parseKanjiXml(langs);

  print("writing CSV files...");

  // Write lang CSV
  writeCsvFile(
    'lang',
    ['id', 'code'],
    langs.asMap().entries.map((e) => [e.key + 1, e.value]).toList(),
    isNumeric: [true, false],
  );

  // Collect all values for batching
  List<List<dynamic>> allCharacterValues = [];
  List<List<dynamic>> allRadicalValues = [];
  List<List<dynamic>> allOnYomiValues = [];
  List<List<dynamic>> allKunYomiValues = [];
  List<List<dynamic>> allMeaningValues = [];

  int onYomiId = 1;
  int kunYomiId = 1;
  int meaningId = 1;

  // Collect data from the List of Kanji
  for (var kanji in kanjis) {
    allCharacterValues.add([
      kanji.character,
      kanji.stroke,
      kanji.freq,
      kanji.jlpt,
    ]);

    if (kanji.radicals.isNotEmpty) {
      for (var radical in kanji.radicals) {
        allRadicalValues.add([kanji.character, radical]);
      }
    }

    if (kanji.on.isNotEmpty) {
      for (var on in kanji.on) {
        allOnYomiValues.add([onYomiId, kanji.character, on]);
        onYomiId++;
      }
    }

    if (kanji.kun.isNotEmpty) {
      for (var kun in kanji.kun) {
        allKunYomiValues.add([kunYomiId, kanji.character, kun]);
        kunYomiId++;
      }
    }

    if (kanji.meanings.isNotEmpty) {
      for (var meaning in kanji.meanings) {
        allMeaningValues.add([
          meaningId,
          kanji.character,
          langs.indexOf(meaning.lang) + 1,
          meaning.meaning,
        ]);
        meaningId++;
      }
    }
  }

  // Write all CSV files
  if (allCharacterValues.isNotEmpty) {
    writeCsvFile(
      'character',
      ['id', 'stroke', 'freq', 'jlpt'],
      allCharacterValues,
      isNumeric: [false, true, true, true],
    );
  }

  if (allRadicalValues.isNotEmpty) {
    writeCsvFile(
      'character_radical',
      ['id_character', 'radical'],
      allRadicalValues,
      isNumeric: [false, false],
    );
  }

  if (allOnYomiValues.isNotEmpty) {
    writeCsvFile(
      'on_yomi',
      ['id', 'id_character', 'reading'],
      allOnYomiValues,
      isNumeric: [true, false, false],
    );
  }

  if (allKunYomiValues.isNotEmpty) {
    writeCsvFile(
      'kun_yomi',
      ['id', 'id_character', 'reading'],
      allKunYomiValues,
      isNumeric: [true, false, false],
    );
  }

  if (allMeaningValues.isNotEmpty) {
    writeCsvFile(
      'meaning',
      ['id', 'id_character', 'id_lang', 'content'],
      allMeaningValues,
      isNumeric: [true, false, true, false],
    );
  }

  print("done!");
}