import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInProvider = Provider<GoogleSignIn>(
  (_) => GoogleSignIn.instance,
);

/// Emits the current Google user and all subsequent auth changes
final authStateProvider = StreamProvider<GoogleSignInAccount?>((ref) async* {
  final googleSignIn = ref.watch(googleSignInProvider);

  // Try to restore a previous session before emitting the live stream
  GoogleSignInAccount? initial;
  try {
    initial = await googleSignIn.attemptLightweightAuthentication();
  } catch (_) {
    // Ignore errors on silent sign-in; stream will still emit later changes
  }

  yield initial;

  // Forward subsequent changes
  yield* googleSignIn.authenticationEvents.map(
    (val) => switch (val) {
      GoogleSignInAuthenticationEventSignIn() => val.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    },
  );
});

/// Helper: interactive sign-in using the new authenticate API
final signInProvider = Provider<Future<GoogleSignInAccount> Function()>((ref) {
  return () async {
    final googleSignIn = ref.read(googleSignInProvider);
    return googleSignIn.authenticate(
      scopeHint: const <String>[
        'email',
        'https://www.googleapis.com/auth/photoslibrary.readonly',
        'https://www.googleapis.com/auth/photoslibrary.sharing',
      ],
    );
  };
});

/// Helper: disconnect (revokes tokens) and sign-out
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final googleSignIn = ref.read(googleSignInProvider);
    try {
      await googleSignIn.disconnect();
    } catch (_) {}
    await googleSignIn.signOut();
  };
});

/// Synchronously exposes the current account from the auth stream (if loaded)
final currentAccountProvider = Provider<GoogleSignInAccount?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.asData?.value;
});

/// Fetches OAuth headers for authenticated requests (e.g., googleapis client)
final authHeadersProvider = FutureProvider<Map<String, String>?>((ref) async {
  final account = ref.watch(currentAccountProvider);
  if (account == null) return null;

  return account.authorizationClient.authorizationHeaders(const [
    'https://www.googleapis.com/auth/photoslibrary.readonly',
    'https://www.googleapis.com/auth/photoslibrary.sharing',
  ], promptIfNecessary: true);
});
