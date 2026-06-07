import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chpa/core/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard should render its child correctly', (WidgetTester tester) async {
    const childText = 'Hello Glass Card';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text(childText),
          ),
        ),
      ),
    );

    expect(find.text(childText), findsOneWidget);
  });

  testWidgets('GlassCard in solid mode (default) should apply custom colors and not contain BackdropFilter', (WidgetTester tester) async {
    const customColor = Colors.red;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            color: customColor,
            frosted: false,
            child: Text('Solid'),
          ),
        ),
      ),
    );

    // Verify the container decoration color matches customColor
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, customColor);

    // Verify no BackdropFilter is present
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('GlassCard in frosted mode should contain a BackdropFilter', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            frosted: true,
            child: Text('Frosted'),
          ),
        ),
      ),
    );

    // Verify a BackdropFilter is present
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
