import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncUiPhase { idle, syncing, complete }

/// Tracks sync operations that should keep the Home dashboard in its loading
/// state until the account's remote data has been applied locally.
class SyncUiStatus extends ChangeNotifier {
  SyncUiStatus._();

  static final instance = SyncUiStatus._();

  int _activeOperations = 0;
  Timer? _completionTimer;
  SyncUiPhase _phase = SyncUiPhase.idle;
  double _progress = 0.0;

  SyncUiPhase get phase => _phase;
  bool get isShowingDashboardStatus => _phase != SyncUiPhase.idle;
  double get progress => _progress;

  void begin() {
    _completionTimer?.cancel();
    _completionTimer = null;
    _activeOperations++;
    _phase = SyncUiPhase.syncing;
    _progress = 0.08;
    notifyListeners();
  }

  void updateProgress(double progress) {
    if (_phase != SyncUiPhase.syncing) return;
    _progress = progress.clamp(0.0, 0.99).toDouble();
    notifyListeners();
  }

  void complete({bool successful = true}) {
    if (_activeOperations == 0) return;
    _activeOperations--;
    if (_activeOperations > 0) return;

    if (!successful) {
      _phase = SyncUiPhase.idle;
      _progress = 0.0;
      notifyListeners();
      return;
    }

    _phase = SyncUiPhase.complete;
    _progress = 1.0;
    notifyListeners();
    _completionTimer = Timer(const Duration(milliseconds: 900), () {
      _phase = SyncUiPhase.idle;
      _progress = 0.0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }
}

final syncUiStatusProvider = ChangeNotifierProvider<SyncUiStatus>(
  (ref) => SyncUiStatus.instance,
);
