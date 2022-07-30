String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void writeInsertToBuffer(StringBuffer buffer, String tableName, List<List<dynamic>> values, [String fields = ""]){
  buffer.write("INSERT INTO $tableName $fields VALUES");
  buffer.writeAll(values.map((e) => "(${e.join(",")})"), ",");
  buffer.write(";\n");
}