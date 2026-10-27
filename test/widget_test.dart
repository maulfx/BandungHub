import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/app.dart';
import 'package:projek_akhir/features/navigation/main_navigation_screen.dart';

void main() {
  testWidgets('BandungHubApp loads and displays initial home screen', (
    WidgetTester tester,
  ) async {
    // Provide a larger screen size so everything is visible
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const BandungHubApp(home: MainNavigationScreen()));
    await tester.pumpAndSettle();

    // Verify BandungHub branding is shown
    expect(find.text('BandungHub'), findsOneWidget);
    expect(find.text('Your Smart Bandung Travel Companion'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(
      find.widgetWithText(NavigationDestination, 'Beranda'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(NavigationDestination, 'Eksplorasi'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(NavigationDestination, 'Rencana'),
      findsOneWidget,
    );
    expect(find.widgetWithText(NavigationDestination, 'Game'), findsOneWidget);
    expect(
      find.widgetWithText(NavigationDestination, 'Profil'),
      findsOneWidget,
    );

    // Verify category chips are present using ChoiceChip selector
    expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Alam'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Kuliner'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Mulai Eksplorasi'), findsOneWidget);
    expect(find.text('Tanya Kang Bandung (AI)'), findsOneWidget);
  });
}
