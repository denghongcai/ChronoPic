import 'package:chronopic/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launches ChronoPic app shell', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('ChronoPic'), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('all-photos-nav')), findsOneWidget);
    expect(find.byKey(const Key('settings-nav')), findsOneWidget);
  });
}
