part of 'jetleaf_vm.dart';

/// {@template entry_state}
/// Runtime state of one entry VM managed by [JetleafVM].
///
/// Linear lifecycle: `discovered → warming → parked → running → parked`,
/// with `failed` and `stopped` as terminal side states. Internal to the
/// `jetleaf_vm` library.
///
/// {@endtemplate}
@internal
enum EntryState {
  /// Discovered but not yet booted.
  discovered,

  /// Frontend compile + VM boot in progress.
  warming,

  /// Booted, parked stub loaded, ready for runs.
  parked,

  /// A run is currently executing in this VM.
  running,

  /// Boot or run failed (see logs); VM may need a reboot on next run.
  failed,

  /// Explicitly stopped via `stopEntry` / `jl stop`.
  stopped,
}

/// {@template entry_status}
/// Mutable runtime status of one entry.
///
/// Internal to the `jetleaf_vm` library: tracked by [JetleafVM],
/// serialized 1:1 into the `.jetleaf/vm/state.json` array file (4-space indented
/// JSON, one object per entry).
///
/// {@endtemplate}
@internal
final class EntryStatus {
  /// {@macro entry_status}
  EntryStatus({required this.record, this.state = EntryState.discovered});

  /// Static discovery data for the entry.
  EntryRecord record;

  /// Current lifecycle state.
  EntryState state;

  /// OS pid of the entry VM process, when booted.
  int? pid;

  /// Debugger WebSocket URI of the entry VM, when connected.
  String? vmServiceUri;

  /// Absolute path of the entry incremental snapshot, when compiled.
  String? snapshot;

  /// Warm fingerprint assigned at boot, when known.
  String? fingerprint;

  /// ISO-8601 timestamp of the last run, when any.
  String? lastRunAt;

  /// Last failure message, when failed.
  String? lastError;

  /// Project-relative entry file path.
  ///
  /// **Returns:** `record.file`.
  String get file => record.file;

  /// Serializes to a VM state array element.
  ///
  /// **Returns:** `{file, kind, state, pid, vmServiceUri, snapshot,
  /// fingerprint, lastRunAt, lastError}`.
  Map<String, Object?> toJson() => {
        'file': record.file,
        'kind': record.kind.name,
        'state': state.name,
        'pid': pid,
        'vmServiceUri': vmServiceUri,
        'snapshot': snapshot,
        'fingerprint': fingerprint,
        'lastRunAt': lastRunAt,
        'lastError': lastError,
      };
}
