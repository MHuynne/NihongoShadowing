import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('MyApp can be constructed', (WidgetTester tester) async {
    expect(const MyApp(), isA<MyApp>());
  });
}