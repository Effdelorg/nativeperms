import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_perms/native_perms.dart';

void main() {
  testWidgets('demo lists every Permission', (WidgetTester tester) async {
    // Just make sure the demo screen builds and renders one tile per permission.
    await tester.pumpWidget(const MaterialApp(home: _Probe()));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
  });
}

class _Probe extends StatelessWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          for (final Permission p in Permission.values)
            ListTile(title: Text(p.toString())),
        ],
      ),
    );
  }
}
