import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRefreshNotifier extends ChangeNotifier {
  SupabaseAuthRefreshNotifier(Stream<AuthState> events) {
    _subscription = events.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Runtime configuration is supplied with --dart-define so secrets and
/// project-specific values do not need to be committed to source control.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const redirectUrl = 'com.dimi.dimi://login-callback/';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static String? get configurationError {
    if (url.isEmpty && publishableKey.isEmpty) {
      return 'Supabase is not configured. Google sign-in and online YouTube sync are unavailable in this build.';
    }
    if (url.isEmpty) return 'SUPABASE_URL is missing.';
    if (publishableKey.isEmpty) return 'SUPABASE_PUBLISHABLE_KEY is missing.';
    return null;
  }
}

abstract final class SupabaseBootstrap {
  static SupabaseClient? _client;
  static Future<void>? _initialization;
  // appRouter is created before main() initializes Supabase. Keep this stream
  // stable so its refresh notifier does not accidentally subscribe to an empty
  // stream during startup.
  static final StreamController<AuthState> _authEvents =
      StreamController<AuthState>.broadcast();
  static StreamSubscription<AuthState>? _authForwarder;

  // ── Offline mode ──────────────────────────────────────────────────────────
  // In-memory flag (used by the router during the session).
  static bool offlineMode = false;

  // SharedPreferences key for persisting the offline choice across launches.
  static const _kOfflineModeKey = 'dimi_offline_mode';

  /// Call once during startup (before runApp) to restore the persisted choice.
  static Future<void> loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    offlineMode = prefs.getBool(_kOfflineModeKey) ?? false;
  }

  /// Persist "Continue offline" so the choice survives app restarts.
  static Future<void> persistOfflineMode() async {
    offlineMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOfflineModeKey, true);
  }

  /// Clear the persisted choice on sign-out or when the user signs in.
  static Future<void> clearOfflineMode() async {
    offlineMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfflineModeKey);
  }
  // ─────────────────────────────────────────────────────────────────────────

  static SupabaseClient? get client => _client;

  static Future<void> initialize() async {
    final activeInitialization = _initialization;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initializeOnce();
    _initialization = initialization;
    return initialization;
  }

  static Future<void> _initializeOnce() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint('[Supabase] ${SupabaseConfig.configurationError}');
      }
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
        detectSessionInUriPredicate: _isSupabaseAuthCallback,
      ),
    );
    _client = Supabase.instance.client;
    await _authForwarder?.cancel();
    _authForwarder = _client!.auth.onAuthStateChange.listen(_authEvents.add);

    // If the user has an active Google session, clear offline mode so they
    // land on Home as a signed-in user, not as an offline user.
    // Do NOT clear it here if there's no session — that would wipe a valid
    // "Continue offline" choice made on a previous launch.
    if (_client?.auth.currentSession != null) {
      offlineMode = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOfflineModeKey);
    }
  }

  static Stream<AuthState> get authChanges => _authEvents.stream;
}

bool _isSupabaseAuthCallback(Uri uri) =>
    uri.scheme == 'com.dimi.dimi' && uri.host == 'login-callback';
