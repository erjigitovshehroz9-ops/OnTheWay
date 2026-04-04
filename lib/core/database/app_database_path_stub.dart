/// Web / non-IO: absolute path so sqflite_common does not call [getDatabasesPath]
/// (which would invoke path_provider on some web/Wasm builds).
Future<String> resolveAppDatabasePath(String name) async {
  if (name.startsWith('/')) return name;
  return '/$name';
}
