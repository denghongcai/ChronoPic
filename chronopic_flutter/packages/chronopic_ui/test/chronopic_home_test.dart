import 'package:chronopic_app/chronopic_app.dart';
import 'package:chronopic_database/chronopic_database.dart';
import 'package:chronopic_domain/chronopic_domain.dart';
import 'package:chronopic_testkit/chronopic_testkit.dart';
import 'package:chronopic_ui/chronopic_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Flutter desktop MVP surfaces', (tester) async {
    final backup = ChronoPicBackup.fromJson(FlutterParityFixtures.readBackupJson());
    final repository = ChronoPicRepository()..restoreBackup(backup);
    await tester.pumpWidget(ChronoPicHome(service: ChronoPicAppService(repository)));

    expect(find.text('ChronoPic Flutter'), findsOneWidget);
    expect(find.text('Add Library'), findsOneWidget);
    expect(find.text('Scan Library'), findsOneWidget);
    expect(find.text('Search and filters'), findsOneWidget);
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Preview Restore'), findsOneWidget);
    expect(find.text('Restore Backup'), findsOneWidget);
    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);

    await tester.tap(find.text('Manual lake caption'));
    await tester.pump();
    expect(find.text('Detail view and gallery view'), findsOneWidget);
    expect(find.text('Edit caption'), findsOneWidget);
    expect(find.text('Add to Memory'), findsOneWidget);
  });
}

