import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/appearance.dart';
import 'core/session.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'screens/change_password.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = AppAppearance();
  final controller = AppController(BlueposApi(), appearance);
  runApp(BluePOSMobile(app: controller));
  controller.initialize();
}

class BluePOSMobile extends StatefulWidget {
  const BluePOSMobile({super.key, required this.app});
  final AppController app;
  @override
  State<BluePOSMobile> createState() => _BluePOSMobileState();
}

class _BluePOSMobileState extends State<BluePOSMobile> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      widget.app.lockForBackground();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([widget.app, widget.app.appearance]),
        builder: (context, _) => MaterialApp(
          title: 'BluePOS Mobile',
          debugShowCheckedModeBanner: false,
          theme: widget.app.appearance.data(Brightness.light),
          darkTheme: widget.app.appearance.data(Brightness.dark),
          themeMode: widget.app.appearance.mode,
          home: widget.app.loading
              ? BlueposSplash(appearance: widget.app.appearance)
              : widget.app.needsPasswordChange
                  ? ChangePasswordScreen(app: widget.app)
                  : !widget.app.authenticated || widget.app.locked
                      ? LoginScreen(app: widget.app)
                      : AppShell(key: ValueKey('mobile-${widget.app.currentUserUlid}-${field(objectOf(widget.app.session?['branch'])['ulid'])}'), app: widget.app),
        ),
      );
}
