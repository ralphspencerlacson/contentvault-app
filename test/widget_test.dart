import 'package:flutter_test/flutter_test.dart';

import 'package:content_vault/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MuxDemoApp());

    expect(find.text('Content Vault'), findsOneWidget);
    expect(find.text('Enter vault'), findsOneWidget);
    expect(find.text('creator1'), findsOneWidget);
    expect(find.text('creator2'), findsOneWidget);
    expect(find.text('subscriber1'), findsOneWidget);
    expect(find.text('Password: 1234'), findsOneWidget);
  });
}
