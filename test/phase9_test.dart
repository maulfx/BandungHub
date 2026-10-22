import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/app.dart';
import 'package:projek_akhir/core/theme/app_colors.dart';
import 'package:projek_akhir/core/theme/app_theme.dart';
import 'package:projek_akhir/data/sources/bandung_destinations.dart';
import 'package:projek_akhir/data/repositories/theme_repository.dart';
import 'package:projek_akhir/features/destinations/screens/explore_screen.dart';
import 'package:projek_akhir/features/profile/screens/profile_screen.dart';
import 'package:projek_akhir/shared/widgets/destination_card.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 9 - ThemeRepository State & Persistence Tests', () {
    late ThemeRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = ThemeRepository();
      repo.resetForTesting(mode: ThemeMode.system);
    });

    test('Initial theme mode defaults to ThemeMode.system', () {
      expect(repo.themeMode, equals(ThemeMode.system));
      expect(repo.themeModeLabel, contains('Ikuti Sistem'));
    });

    test('setThemeMode updates state and notifies listeners', () async {
      int notifyCount = 0;
      repo.addListener(() {
        notifyCount++;
      });

      await repo.setThemeMode(ThemeMode.dark);
      expect(repo.themeMode, equals(ThemeMode.dark));
      expect(repo.themeModeLabel, contains('Gelap'));
      expect(notifyCount, equals(1));

      await repo.setThemeMode(ThemeMode.light);
      expect(repo.themeMode, equals(ThemeMode.light));
      expect(repo.themeModeLabel, contains('Terang'));
      expect(notifyCount, equals(2));

      // Setting same mode shouldn't notify again
      await repo.setThemeMode(ThemeMode.light);
      expect(notifyCount, equals(2));
    });

    test('Theme labels return accurate Indonesian descriptions', () {
      expect(
        ThemeRepository.getModeLabel(ThemeMode.light),
        equals('Mode Terang (Light)'),
      );
      expect(
        ThemeRepository.getModeLabel(ThemeMode.dark),
        equals('Mode Gelap (Dark)'),
      );
      expect(
        ThemeRepository.getModeLabel(ThemeMode.system),
        equals('Ikuti Sistem (Otomatis)'),
      );
    });
  });

  group('Phase 9 - Theme System & Colors Integration Tests', () {
    test('AppTheme provides valid Material 3 light and dark themes', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));

      expect(light.colorScheme.primary, equals(AppColors.primary));
      expect(dark.colorScheme.primary, equals(AppColors.primaryLight));

      expect(light.scaffoldBackgroundColor, equals(AppColors.backgroundLight));
      expect(dark.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
    });

    testWidgets('AppColors adaptive helpers return correct color per theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        Theme(
          data: AppTheme.lightTheme,
          child: Builder(
            builder: (context) {
              expect(AppColors.isDarkMode(context), isFalse);
              expect(
                AppColors.getTextPrimary(context),
                equals(AppColors.textPrimaryLight),
              );
              expect(
                AppColors.getCardColor(context),
                equals(AppColors.cardLight),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: AppTheme.darkTheme,
          child: Builder(
            builder: (context) {
              expect(AppColors.isDarkMode(context), isTrue);
              expect(
                AppColors.getTextPrimary(context),
                equals(AppColors.textPrimaryDark),
              );
              expect(
                AppColors.getCardColor(context),
                equals(AppColors.cardDark),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('Phase 9 - UI Widgets & Profile Theme Switcher Tests', () {
    late ThemeRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = ThemeRepository();
      repo.resetForTesting(mode: ThemeMode.system);
    });

    testWidgets(
      'ProfileScreen displays Tampilan & Aksesibilitas card and opens dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Check for Phase 9 theme section header
        expect(
          find.text('Tampilan & Aksesibilitas (Phase 9)'),
          findsOneWidget,
        );
        expect(find.text('Mode Tampilan (Tema)'), findsOneWidget);
        expect(find.text('Ikuti Sistem (Otomatis)'), findsOneWidget);

        // Tap on theme selection row
        await tester.tap(find.text('Mode Tampilan (Tema)'));
        await tester.pumpAndSettle();

        // Dialog should be open with 3 options
        expect(find.text('Pilih Tema Aplikasi'), findsOneWidget);
        expect(find.text('Mode Gelap (Dark)'), findsOneWidget);
        expect(find.text('Mode Terang (Light)'), findsOneWidget);

        // Tap 'Mode Gelap (Dark)'
        await tester.tap(find.text('Mode Gelap (Dark)'));
        await tester.pumpAndSettle();

        // Repo should have updated to dark mode
        expect(repo.themeMode, equals(ThemeMode.dark));
        expect(find.text('Mode Gelap (Dark)'), findsOneWidget);
      },
    );

    testWidgets(
      'BandungHubApp reflects reactive ThemeMode when repository updates',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const BandungHubApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(MaterialApp), findsOneWidget);

        // Switch theme via repository
        await repo.setThemeMode(ThemeMode.dark);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, equals(ThemeMode.dark));
      },
    );
  });

  group('Phase 9 - Accessibility (A11y) & Semantics Tests', () {
    testWidgets(
      'DestinationCard provides explicit Semantics for screen readers',
      (tester) async {
        final destination = BandungDestinations.list.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DestinationCard(
                destination: destination,
                isHorizontal: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Destination name and category should be accessible via Semantics
        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains(destination.name),
        );

        expect(semanticsFinder, findsWidgets);
      },
    );

    test('Buttons meet accessibility touch target sizing of at least 48x48', () {
      final elevatedStyle = AppTheme.lightTheme.elevatedButtonTheme.style;
      final outlinedStyle = AppTheme.lightTheme.outlinedButtonTheme.style;

      final minSizeElevated = elevatedStyle?.minimumSize?.resolve({});
      final minSizeOutlined = outlinedStyle?.minimumSize?.resolve({});

      expect(minSizeElevated?.height, greaterThanOrEqualTo(48.0));
      expect(minSizeOutlined?.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Phase 9 - Responsive Layout Tests', () {
    testWidgets(
      'ExploreScreen grid layout adapts column count based on viewport width',
      (tester) async {
        // 1. Narrow viewport (e.g. standard phone portrait: width 400)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExploreScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle into grid view
        final gridToggleBtn = find.byTooltip('Tampilan Grid');
        expect(gridToggleBtn, findsOneWidget);
        await tester.tap(gridToggleBtn);
        await tester.pumpAndSettle();

        final gridFinder = find.byType(GridView);
        expect(gridFinder, findsOneWidget);

        var gridWidget = tester.widget<GridView>(gridFinder);
        var delegate =
            gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(2));

        // 2. Wide viewport (e.g. tablet / landscape phone: width 800)
        tester.view.physicalSize = const Size(800, 600);
        await tester.pumpAndSettle();

        gridWidget = tester.widget<GridView>(gridFinder);
        delegate =
            gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(3));
      },
    );
  });
}
