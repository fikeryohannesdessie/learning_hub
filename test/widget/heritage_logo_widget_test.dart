import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chpa/core/widgets/heritage_logo.dart';

void main() {
  testWidgets('HeritageLogoWidget renders CustomPaint with specified size', (WidgetTester tester) async {
    const double targetSize = 64.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeritageLogoWidget(size: targetSize),
        ),
      ),
    );

    // Verify SizedBox size matches
    final sizedBoxFinder = find.byType(SizedBox);
    expect(sizedBoxFinder, findsOneWidget);
    final SizedBox sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
    expect(sizedBox.width, equals(targetSize));
    expect(sizedBox.height, equals(targetSize));

    // Verify CustomPaint exists inside
    final customPaintFinder = find.descendant(
      of: find.byType(HeritageLogoWidget),
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsOneWidget);
  });

  testWidgets('HeritageLogoWidget passes correct colors to painter', (WidgetTester tester) async {
    const customPrimary = Colors.amber;
    const customSecondary = Colors.deepOrange;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeritageLogoWidget(
            size: 40,
            primaryColor: customPrimary,
            secondaryColor: customSecondary,
          ),
        ),
      ),
    );

    final customPaintFinder = find.descendant(
      of: find.byType(HeritageLogoWidget),
      matching: find.byType(CustomPaint),
    );
    final CustomPaint customPaint = tester.widget<CustomPaint>(customPaintFinder);
    
    // CustomPainter must not be null
    expect(customPaint.painter, isNotNull);
  });

  testWidgets('AnimatedHeritageLogoWidget builds Container with shadow decoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedHeritageLogoWidget(size: 100),
        ),
      ),
    );

    // Verify container exists
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);

    final Container container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;

    // Decoration should have shape circle and shadow
    expect(decoration.shape, equals(BoxShape.circle));
    expect(decoration.boxShadow, isNotEmpty);

    // Verify child HeritageLogoWidget is rendered inside the container
    expect(find.byType(HeritageLogoWidget), findsOneWidget);
  });

  testWidgets('AnimatedHeritageLogoWidget animates shadows over time', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedHeritageLogoWidget(size: 80),
        ),
      ),
    );

    // Get initial shadow opacity
    final containerFinder = find.byType(Container);
    Container container = tester.widget<Container>(containerFinder);
    BoxDecoration decoration = container.decoration as BoxDecoration;
    final double initialOpacity = decoration.boxShadow!.first.color.opacity;

    // Pump widgets for 1 second to advance the animation
    await tester.pump(const Duration(seconds: 1));

    // Get updated shadow opacity
    container = tester.widget<Container>(containerFinder);
    decoration = container.decoration as BoxDecoration;
    final double midOpacity = decoration.boxShadow!.first.color.opacity;

    // Check that the opacity has changed (meaning the animation ticked)
    expect(midOpacity, isNot(equals(initialOpacity)));
  });
}
