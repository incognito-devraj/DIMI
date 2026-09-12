import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../data/database.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  SupabaseClient get _client {
    final client = SupabaseBootstrap.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }

  User? get currentUser => SupabaseBootstrap.client?.auth.currentUser;

  /// Copies the authenticated Google identity into DIMI's local profile row.
  ///
  /// This keeps the existing offline-first profile storage, while ensuring a
  /// seeded/demo email can never remain visible after a real sign-in.
  Future<void> syncLocalProfile(AppDatabase db) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await db.profileDao.getProfile();
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final metadataName = metadata['full_name'] ?? metadata['name'];
    final fallbackName = user.email?.split('@').first;
    final name = (metadataName ?? fallbackName ?? 'Student').toString();

    await db.profileDao.upsertProfile(
      ProfileTableCompanion(
        id: const Value(1),
        name: Value(name),
        role: Value(existing?.role ?? ''),
        email: Value(user.email ?? ''),
        phone: Value(existing?.phone ?? ''),
        college: Value(existing?.college ?? ''),
        semester: Value(existing?.semester ?? ''),
        photoPath: Value(existing?.photoPath),
        quote: Value(existing?.quote ?? 'A better you, One day at a time.'),
        points: Value(existing?.points ?? 0),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    const provider = OAuthProvider.google;
    final redirectTo = SupabaseConfig.redirectUrl;
    if (kDebugMode) {
      debugPrint('[DIMI OAuth] platform=${defaultTargetPlatform.name}');
      debugPrint('[DIMI OAuth] provider=$provider');
      debugPrint('[DIMI OAuth] redirectTo=$redirectTo');
      debugPrint('[DIMI OAuth] supabaseUrl=${SupabaseConfig.url}');
    }

    // Use Supabase's complete OAuth entry point. Besides launching Chrome,
    // this keeps the PKCE verifier and callback/session exchange coupled to
    // the same auth client that observes the Android deep link on return.
    final launched = await _client.auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Could not launch the Google OAuth browser.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
