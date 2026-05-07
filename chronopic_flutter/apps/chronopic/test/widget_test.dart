import 'package:chronopic/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launches ChronoPic Flutter app shell', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('ChronoPic Flutter'), findsOneWidget);
    expect(find.text('First run library setup'), findsOneWidget);
    expect(find.text('Add Library'), findsOneWidget);
  });
}
