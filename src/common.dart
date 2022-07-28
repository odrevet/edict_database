String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

void writeInsertToBuffer(StringBuffer buffer, String tableName, List<String> values, [String fields = ""]){
  buffer.write("INSERT INTO $tableName $fields VALUES");
  buffer.writeAll(values, ",");
  buffer.write(";\n");
}