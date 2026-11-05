import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/appearance.dart';
import 'core/session.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'screens/change_password.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = AppAppearance();
  final controller = AppController(BlueposApi(), appearance);
  runApp(BluePOSMobile(app: controller));
  controller.initialize();
}

class BluePOSMobile extends StatelessWidget {
  const BluePOSMobile({super.key, required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([app, app.appearance]),
        builder: (context, _) => MaterialApp(
          title: 'BluePOS Mobile',
          debugShowCheckedModeBanner: false,
          theme: app.appearance.data(Brightness.light),
          darkTheme: app.appearance.data(Brightness.dark),
          themeMode: app.appearance.mode,
          home: app.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : app.authenticated
                  ? app.needsPasswordChange
                      ? ChangePasswordScreen(app: app)
                      : AppShell(app: app)
                  : LoginScreen(app: app),
        ),
      );
}
