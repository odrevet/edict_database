String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void writeInsertToBuffer(StringBuffer buffer, String tableName, Iterable<Iterable<dynamic>> values,
    [List<String> fields = const []]) {
  String fieldsStr = fields.isNotEmpty ? '(${fields.join(',')})' : '';
  buffer.write("INSERT INTO $tableName $fieldsStr VALUES");
  buffer.writeAll(values.map((e) => "(${e.join(",")})"), ",");
  buffer.write(";\n");
}
