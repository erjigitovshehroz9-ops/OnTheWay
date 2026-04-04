import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> resolveAppDatabasePath(String name) async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, name);
}
