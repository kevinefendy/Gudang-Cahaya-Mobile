import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_hp/screens/login_screen.dart';

void main() {
  testWidgets('Halaman login tampil dengan form email dan password',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Gudang Cahaya'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
