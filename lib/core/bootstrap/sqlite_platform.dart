import 'sqlite_platform_stub.dart'
    if (dart.library.html) 'sqlite_platform_html.dart'
    if (dart.library.io) 'sqlite_platform_io.dart' as sqlite_impl;

/// Desktop (Windows, Linux, macOS) uses FFI. Web uses wasm/IndexedDB factory.
/// Mobile uses default sqflite.
Future<void> configureSqliteForPlatform() async {
  await sqlite_impl.configureSqliteImpl();
}
