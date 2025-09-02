import 'package:ff_hack/presentation/screens/login_screen.dart';
import 'package:ff_hack/presentation/screens/home_screen.dart';
import 'package:ff_hack/data/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FFApp extends ConsumerWidget {
  const FFApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    print('state: ${auth.toString()}');

    return MaterialApp(
      home: auth.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => const LoginScreen(),
        data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }
}
