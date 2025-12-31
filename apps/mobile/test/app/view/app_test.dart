// Ignore for testing purposes

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  group('App', () {
    testWidgets('renders AppView', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
