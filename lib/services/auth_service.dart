import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../data/database.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  Future<void> _accountTransition = Future<void>.value();
  int _contextGeneration = 0;

  SupabaseClient get _client {
    final client = SupabaseBootstrap.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }

  User? get currentUser => SupabaseBootstrap.client?.auth.currentUser;

  /// Serializes account activation/deactivation so no caller can observe a
  /// partially switched local account.
  Future<void> synchronizeAuthState(AppDatabase db, User? user) {
    final previous = _accountTransition;
    final next = previous.then((_) async {
      if (user == null) {
        _contextGeneration++;
        await clearLocalActiveAccount(db);
        return;
      }
      await syncLocalProfile(db, user: user);
      _contextGeneration++;
    });
    _accountTransition = next.catchError((_) {});
    return next;
  }

  /// Returns a validated authenticated account context for future sync work.
  /// It returns null for offline mode or while the local account does not
  /// match the current Supabase identity.
  Future<({int localAccountId, String authUserId, int generation})?>
      awaitAuthenticatedContext(AppDatabase db) async {
    await _accountTransition;
    final user = currentUser;
    if (user == null) return null;
    final active = await db.localAccountDao.getActive();
    if (active?.authProvider != 'supabase' || active?.authUserId != user.id) {
      return null;
    }
    return (
      localAccountId: active!.id,
      authUserId: user.id,
      generation: _contextGeneration,
    );
  }

  bool isContextCurrent(int generation, int localAccountId, AppDatabase db) =>
      generation == _contextGeneration &&
      db.activeAccountId == localAccountId &&
      currentUser != null;

  /// Copies the authenticated Google identity into DIMI's local profile row.
  ///
  /// This keeps the existing offline-first profile storage, while ensuring a
  /// seeded/demo email can never remain visible after a real sign-in.
  Future<void> syncLocalProfile(AppDatabase db, {User? user}) async {
    user ??= currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final metadataName = metadata['full_name'] ?? metadata['name'];
    final metadataPhoto = metadata['avatar_url'] ?? metadata['picture'];
    final fallbackName = user.email?.split('@').first;
    final name = (metadataName ?? fallbackName ?? 'Student').toString();
    final accountId = await db.localAccountDao.ensureAuthenticatedAccount(
      userId: user.id,
      email: user.email,
      displayName: name,
      avatarUrl: metadataPhoto?.toString(),
    );
    final existing = await db.profileDao.getProfile();

    await db.profileDao.upsertProfile(
      ProfileTableCompanion(
        id: Value(accountId),
        name: Value(name),
        role: Value(existing?.role ?? ''),
        email: Value(user.email ?? ''),
        phone: Value(existing?.phone ?? ''),
        college: Value(existing?.college ?? ''),
        semester: Value(existing?.semester ?? ''),
        photoPath: Value(metadataPhoto?.toString()),
        quote: const Value(null),
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

  Future<void> signOut(AppDatabase db) async {
    await _accountTransition;
    _contextGeneration++;
    await clearLocalActiveAccount(db);
    await _client.auth.signOut();
  }

  Future<void> clearLocalActiveAccount(AppDatabase db) async {
    await db.localAccountDao.ensureOfflineAccount();
  }
}
