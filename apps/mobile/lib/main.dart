// Default entry point - delegates to development build
import 'package:mobile/app/app.dart';
import 'package:mobile/bootstrap.dart';

export 'main_development.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
