/// Pure generation-claim tracker for reconnect-triggered reads.
///
/// This object answers whether a reconnect generation is new and claimable.
/// It MUST NOT own Futures, Timers, ConnectivityProvider, subscriptions,
/// or execute any reads/mutations. The feature/controller owns all of that.
///
/// Usage pattern:
/// 1. Feature binds to the gate with [bind].
/// 2. Feature observes ConnectivityProvider.reconnectGeneration externally.
/// 3. Before starting a reconnect read, feature calls [claimCurrentGeneration].
/// 4. If the claim succeeds, feature proceeds with its read.
/// 5. A failed read does NOT reopen the same generation.
class ReconnectGenerationGate {
  ReconnectGenerationGate();

  int _lastHandledGeneration = -1;
  bool _disposed = false;

  /// The generation most recently handled by the feature.
  int get lastHandledGeneration => _lastHandledGeneration;

  /// Binds to the current generation, recording it as handled.
  ///
  /// Call this once when the feature initializes or when it has already
  /// processed the current generation (e.g. initial data load).
  /// After bind, [claimCurrentGeneration] will only return true for
  /// a strictly newer positive generation.
  void bind(int currentGeneration) {
    if (_disposed) return;
    _lastHandledGeneration = currentGeneration;
  }

  /// Attempts to claim the given generation for a reconnect read.
  ///
  /// Returns true only if:
  /// - [generation] is strictly greater than [lastHandledGeneration]
  /// - [generation] is greater than 0 (generation 0 is not a reconnect event)
  ///
  /// On success, [lastHandledGeneration] advances to [generation].
  /// A generation can only be claimed once.
  /// A failed external read does NOT make the generation claimable again.
  bool claimCurrentGeneration(int generation) {
    if (_disposed) return false;
    if (generation <= 0) return false;
    if (generation <= _lastHandledGeneration) return false;
    _lastHandledGeneration = generation;
    return true;
  }

  /// Resets the gate to an unbound state.
  ///
  /// After this call, [lastHandledGeneration] is -1 and the next
  /// positive generation can be claimed.
  void reset() {
    _lastHandledGeneration = -1;
  }

  void dispose() {
    _disposed = true;
  }
}
