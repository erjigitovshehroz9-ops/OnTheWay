import 'dart:io';

bool localFileExistsSync(String path) =>
    path.isNotEmpty && File(path).existsSync();
