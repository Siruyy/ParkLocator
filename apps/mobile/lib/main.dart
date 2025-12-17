// Default entry point - delegates to development build
export 'main_development.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
