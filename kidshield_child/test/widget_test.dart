import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kidshield_child/main.dart';
import 'package:kidshield_child/providers/child_auth_provider.dart';
import 'package:kidshield_child/providers/location_provider.dart';
import 'package:kidshield_child/providers/companion_provider.dart';

void main() {
  testWidgets('KidShield Junior smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChildAuthProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => CompanionProvider()),
        ],
        child: const KidShieldChildApp(),
      ),
    );

    expect(find.byType(KidShieldChildApp), findsOneWidget);
  });
}
