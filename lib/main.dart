import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();

  await Supabase.initialize(
    url: 'https://skwburtcthxihpgqagmm.supabase.co',
    publishableKey: 'sb_publishable_6f7rQ5e2pJ_rdUoBxaInoA_wJW5KtHW',
  );

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
