import 'local_file_exists_stub.dart'
    if (dart.library.io) 'local_file_exists_io.dart' as impl;

/// True only on IO platforms when [path] points to an existing file.
bool localFileExistsSync(String path) => impl.localFileExistsSync(path);
