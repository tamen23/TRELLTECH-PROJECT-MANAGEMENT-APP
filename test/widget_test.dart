import 'package:flutter_test/flutter_test.dart';
import 'package:trello_wish/main.dart';

void main() {
  testWidgets('UI Verification for HomePage', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());


    await tester.pumpAndSettle();

    expect(find.text('TRELLTECH'), findsOneWidget);

    expect(find.text('Mon Profil'), findsOneWidget);
  });
}