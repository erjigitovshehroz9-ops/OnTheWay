import 'app_database_path_stub.dart'
    if (dart.library.io) 'app_database_path_io.dart' as impl;

Future<String> resolveAppDatabasePath(String name) =>
    impl.resolveAppDatabasePath(name);
