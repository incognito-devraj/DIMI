import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Retained for compatibility with existing callers; it is not an auth
  /// state and must not be used to enter protected routes.
  static bool offlineMode = false;

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

    // If already authenticated from a previous session, clear offline mode.
    if (_client?.auth.currentSession != null) {
      offlineMode = false;
    }
  }

  static Stream<AuthState> get authChanges => _authEvents.stream;
}

bool _isSupabaseAuthCallback(Uri uri) =>
    uri.scheme == 'com.dimi.dimi' && uri.host == 'login-callback';
