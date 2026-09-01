import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itantsoroka/screens/common/coming_soon_screen.dart';

void main() {
  testWidgets('coming soon screen renders title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComingSoonScreen(
          title: 'Collecte de besoins',
          subtitle: 'Bientôt disponible',
        ),
      ),
    );

    expect(find.text('Collecte de besoins'), findsOneWidget);
    expect(find.text('Bientôt disponible'), findsOneWidget);
  });
}
