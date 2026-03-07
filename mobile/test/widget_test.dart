import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/screens/placeholder_screen.dart';

void main() {
  testWidgets('placeholder screen renders text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceholderScreen(),
      ),
    );

    expect(find.text('Пока пусто'), findsOneWidget);
  });
}
