import 'dart:io';

import 'common.dart';
import 'parse_kanji.dart';

void main(List<String> args) async {
  String langsArg = 'en';
  int maxInsert = 1;
  bool usedNamedArgs = false;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--langs' && i + 1 < args.length) {
      langsArg = args[i + 1];
      usedNamedArgs = true;
      i++;
    } else if (args[i] == '--max-inserts' && i + 1 < args.length) {
      maxInsert = int.tryParse(args[i + 1]) ?? 1;
      usedNamedArgs = true;
      i++;
    }
  }

  List<String> langs = langsArg.split(',').map((s) => s.trim()).toList();

  if (!usedNamedArgs && args.isNotEmpty && int.tryParse(args.last) != null) {
    maxInsert = int.parse(args.last);
    langs = args.sublist(0, args.length - 1);
  }

  final filename = 'data/generated/sql/kanji.sql';

  List<Kanji> kanjis = await parseKanjiXml(langs, escapeFunction: escape);

  final buffer = StringBuffer();

  addSqlInsertToBuffer(
      buffer,
      "lang",
      langs.asMap().entries.map((e) => [e.key + 1, "'${e.value}'"]),
      [],
      maxInsert);

  List<List<dynamic>> allCharacterValues = [];
  List<List<dynamic>> allRadicalValues = [];
  List<List<dynamic>> allOnYomiValues = [];
  List<List<dynamic>> allKunYomiValues = [];
  List<List<dynamic>> allMeaningValues = [];

  for (var kanji in kanjis) {
    allCharacterValues.add(
        ["'${kanji.character}'", kanji.stroke, kanji.freq, kanji.jlpt]);

    if (kanji.radicals.isNotEmpty) {
      for (var radical in kanji.radicals) {
        allRadicalValues.add(["'${kanji.character}'", "'$radical'"]);
      }
    }

    if (kanji.on.isNotEmpty) {
      for (var on in kanji.on) {
        allOnYomiValues.add(["NULL", "'${kanji.character}'", "'$on'"]);
      }
    }

    if (kanji.kun.isNotEmpty) {
      for (var kun in kanji.kun) {
        allKunYomiValues.add(["NULL", "'${kanji.character}'", "'$kun'"]);
      }
    }

    if (kanji.meanings.isNotEmpty) {
      for (var meaning in kanji.meanings) {
        allMeaningValues.add([
          "NULL",
          "'${kanji.character}'",
          "'${langs.indexOf(meaning.lang) + 1}'",
          "'${meaning.meaning}'",
        ]);
      }
    }
  }

  if (allCharacterValues.isNotEmpty) {
    addSqlInsertToBuffer(
        buffer, "character", allCharacterValues, [], maxInsert);
  }

  if (allRadicalValues.isNotEmpty) {
    addSqlInsertToBuffer(
        buffer, "character_radical", allRadicalValues, [], maxInsert);
  }

  if (allOnYomiValues.isNotEmpty) {
    addSqlInsertToBuffer(buffer, "on_yomi", allOnYomiValues, [], maxInsert);
  }

  if (allKunYomiValues.isNotEmpty) {
    addSqlInsertToBuffer(buffer, "kun_yomi", allKunYomiValues, [], maxInsert);
  }

  if (allMeaningValues.isNotEmpty) {
    addSqlInsertToBuffer(buffer, "meaning", allMeaningValues, [], maxInsert);
  }

  File(filename).writeAsStringSync(buffer.toString());
  print("SQL file written to $filename");
}