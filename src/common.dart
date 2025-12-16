String escape(String value) {
  return value.replaceAll('\'', '\'\'');
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
