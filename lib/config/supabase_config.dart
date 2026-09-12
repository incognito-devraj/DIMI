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
}

abstract final class SupabaseBootstrap {
  static SupabaseClient? _client;
  // appRouter is created before main() initializes Supabase. Keep this stream
  // stable so its refresh notifier does not accidentally subscribe to an empty
  // stream during startup.
  static final StreamController<AuthState> _authEvents =
      StreamController<AuthState>.broadcast();
  static StreamSubscription<AuthState>? _authForwarder;

  /// Set to true when the user explicitly chooses "Continue offline".
  /// When true the router will not redirect unauthenticated users to /login,
  /// even when Supabase is configured.
  static bool offlineMode = false;

  static SupabaseClient? get client => _client;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint('[Supabase] Not configured; running local-only mode.');
      }
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
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
