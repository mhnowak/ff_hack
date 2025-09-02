import 'package:ff_hack/ff_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final signIn = GoogleSignIn.instance;

  await signIn.initialize(
    clientId:
        '',
    serverClientId:
        '',
  );

  runApp(ProviderScope(child: const FFApp()));
}
