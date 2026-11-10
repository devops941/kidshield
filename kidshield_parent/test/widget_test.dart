import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kidshield_parent/main.dart';
import 'package:kidshield_parent/providers/theme_provider.dart';
import 'package:kidshield_parent/providers/auth_provider.dart';
import 'package:kidshield_parent/providers/child_provider.dart';
import 'package:kidshield_parent/providers/monitoring_provider.dart';

void main() {
  testWidgets('KidShield Parent App loads smoke test', (WidgetTester tester) async {
    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ChildProvider()),
          ChangeNotifierProvider(create: (_) => MonitoringProvider()),
        ],
        child: const KidShieldParentApp(),
      ),
    );

    // Verify KidShield Parent app initializes
    expect(find.byType(KidShieldParentApp), findsOneWidget);
  });
}
