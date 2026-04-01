import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/presentation/widgets/app_modal.dart';

void main() {
  testWidgets('supports expanded content when modal has a fixed height',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppModal(
            title: AppModalTitle('Test Modal'),
            width: 400,
            height: 320,
            expandContent: true,
            content: Column(
              children: [
                Text('Header'),
                Expanded(
                  child: ColoredBox(
                    color: Colors.blue,
                    child: Center(
                      child: Text('Scrollable area'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Scrollable area'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
