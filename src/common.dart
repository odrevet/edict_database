String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

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

void addSqlInsertToBuffer(
    StringBuffer buffer,
    String tableName,
    Iterable<Iterable<dynamic>> values,
    [List<String> fields = const [],
      int maxInsert = 0]) {

  String fieldsStr = fields.isNotEmpty ? '(${fields.join(',')})' : '';

  if (maxInsert <= 0 || values.length <= maxInsert) {
    // No batching needed when maxInsert is 0 or not provided
    buffer.write("INSERT INTO $tableName $fieldsStr VALUES");
    buffer.writeAll(values.map((e) => "(${e.join(",")})"), ",");
    buffer.write(";\n");
  } else {
    // Only split when maxInsert > 0 and values exceed maxInsert
    var valuesList = values.toList();
    for (int i = 0; i < valuesList.length; i += maxInsert) {
      int end = (i + maxInsert < valuesList.length) ? i + maxInsert : valuesList.length;
      var batch = valuesList.sublist(i, end);

      buffer.write("INSERT INTO $tableName $fieldsStr VALUES");
      buffer.writeAll(batch.map((e) => "(${e.join(",")})"), ",");
      buffer.write(";\n");
    }
  }
}
