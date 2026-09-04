import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const MeerathAdminApp());
}

class MeerathAdminApp extends StatelessWidget {
  const MeerathAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEERATH Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const LoginScreen(),
    );
  }
}
