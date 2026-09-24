import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

import '../config/supabase_config.dart';
import '../data/database.dart';
import '../data/daos/sync_outbox_dao.dart';
import '../data/sync/sync_remote_api.dart';
import '../data/sync/sync_version_protocol.dart';
import '../data/sync/sync_timestamp.dart';
import 'auth_service.dart';

class SyncService {
  SyncService(
    this.db, {
    this._remote,
    this._preferences,
    ({int localAccountId, String authUserId, int generation})? testContext,
  }) : _testContext = testContext;

  final AppDatabase db;
  final SyncRemoteApi? _remote;
  final SharedPreferences? _preferences;
  // Injected by tests to bypass the Supabase auth guard.
  final ({int localAccountId, String authUserId, int generation})? _testContext;
  Future<void>? _running;

  Future<void> syncNow() {
    final current = _running;
    if (current != null) return current;
    final run = _run();
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  Future<void> _run() async {
    final context =
        _testContext ??
        await AuthService.instance.awaitAuthenticatedContext(db);
    if (context == null) {
      _log('skip: no authenticated local account context');
      return;
    }
    final client =
        _remote ??
        (SupabaseBootstrap.client == null
            ? null
            : SupabaseSyncRemoteApi(SupabaseBootstrap.client!));
    if (client == null) {
      _log('skip: Supabase client is unavailable/configuration is missing');
      return;
    }
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _log('start account=${context.localAccountId} user=${context.authUserId}');
    try {
      await _push(client, context);
      await _pull(client, prefs, context);
      await db.syncOutboxDao.removeCompleted(
        localAccountId: context.localAccountId,
      );
      _log('complete account=${context.localAccountId}');
    } on _ContextChanged {
      _log('stopped account context changed');
    } catch (error, stackTrace) {
      _log('failed account=${context.localAccountId} error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _push(
    SyncRemoteApi remote,
    ({int localAccountId, String authUserId, int generation}) context,
  ) async {
    while (true) {
      _ensureContext(context);
      final ready = await db.syncOutboxDao
          .watchReady(localAccountId: context.localAccountId)
          .first;
      if (ready.isEmpty) return;
      for (final item in ready) {
        _ensureContext(context);
        _log(
          'push outbox=${item.id} entity=${item.entityType} '
          'local=${item.localRowId} server=${item.serverId} '
          'operation=${item.operation} base=${item.baseRemoteUpdatedAt}',
        );
        if (item.localAccountId != context.localAccountId ||
            item.authUserId != null && item.authUserId != context.authUserId) {
          continue;
        }
        await db.syncOutboxDao.markProcessing(item.id);
        try {
          await _pushOne(remote, item, context);
          await db.syncOutboxDao.markCompletedIfCurrent(item.id, item.updatedAt);
        } on _TransientSyncError catch (error) {
          _log(
            'retry entity=${item.entityType} local=${item.localRowId} error=$error',
          );
          await db.syncOutboxDao.markRetryable(item.id, error.toString());
        } on _ContextChanged {
          rethrow;
        } on PostgrestException catch (error) {
          _log(
            'retry entity=${item.entityType} local=${item.localRowId} '
            'status=${error.code} message=${error.message} details=${error.details} hint=${error.hint}',
          );
          await db.syncOutboxDao.markRetryable(item.id, error.message);
        } catch (error) {
          _log(
            'permanent entity=${item.entityType} local=${item.localRowId} error=$error',
          );
          await db.syncOutboxDao.markPermanent(item.id, error.toString());
        }
      }
    }
  }

  Future<void> _pushOne(
    SyncRemoteApi remote,
    SyncOutboxData item,
    ({int localAccountId, String authUserId, int generation}) context,
  ) async {
    final spec = _specs[item.entityType];
    if (spec == null)
      throw StateError('Unsupported sync entity ${item.entityType}');
    final local = await _readLocal(spec, item.localRowId, context.localAccountId);
    if (local == null)
      throw StateError(
        'Missing local row ${item.entityType}:${item.localRowId}',
      );
    // Create-then-delete before the first push: the Drift tombstone is kept
    // for history, but there is no remote identity to delete or create.
    if (item.operation == OutboxOperation.delete &&
        local['server_id'] == null) {
      return;
    }
    final serverId = local['server_id'] as String? ?? _uuid();
    if (local['server_id'] == null) {
      await _setLocalMetadata(
        spec,
        item.localRowId,
        serverId,
        null,
        accountId: context.localAccountId,
      );
    }
    final localVersion = _date(local['updated_at']);
    final exactRemoteVersion = spec.localTable == 'tasks' ||
            spec.localTable == 'youtube_videos'
        ? _date(local['remote_updated_at'])
        : null;
    final payload = await _toRemote(spec, local, serverId, context.authUserId);
    if (spec.localTable == 'youtube_videos') {
      _log(
        'youtube payload local=${item.localRowId} account=${context.localAccountId} '
        'server=$serverId operation=${item.operation} '
        'completed=${payload['completed']} playlistId=${payload['playlist_id']} '
        'base=${exactRemoteVersion ?? item.baseRemoteUpdatedAt}',
      );
    }
    Map<String, dynamic>? remoteRow;
    if (item.operation == OutboxOperation.create) {
      remoteRow = await remote.getRow(spec.remoteTable, serverId);
      if (remoteRow == null) {
        final result = await remote.insertRow(spec.remoteTable, payload);
        await _ackPush(spec, item, result, context, localVersion);
        return;
      }
      // A create entry survived after the remote row was already created.
      // From this point this identity must use UPDATE, never another CREATE.
      await db.syncOutboxDao.promoteCreateToUpdate(item.id);
      _log(
        'normalized stale create to update entity=${item.entityType} '
        'local=${item.localRowId} server=$serverId',
      );
    } else {
      remoteRow = await remote.getRow(spec.remoteTable, serverId);
    }
    if (remoteRow == null) {
      if (item.operation == OutboxOperation.delete) {
        // A remotely compacted row is already absent; the local tombstone is
        // retained until normal tombstone cleanup is implemented.
        return;
      }
      final result = await remote.insertRow(spec.remoteTable, payload);
      await _ackPush(spec, item, result, context, localVersion);
      return;
    }
    final remoteVersion = _date(remoteRow['updated_at']);
    if (remoteVersion == null) {
      throw StateError('Remote ${spec.remoteTable} row has no updated_at');
    }
    final relation = SyncVersionProtocol.classifyPendingPush(
      baseRemoteUpdatedAt: exactRemoteVersion ?? item.baseRemoteUpdatedAt,
      remoteUpdatedAt: remoteVersion,
    );
    if (relation == SyncVersionRelation.localNewer) {
      final result = await remote.updateRow(
        spec.remoteTable,
        serverId,
        remoteVersion,
        payload,
      );
      if (result == null) throw _TransientSyncError('CAS conflict');
      if (spec.localTable == 'youtube_videos') {
        _log(
          'youtube response local=${item.localRowId} server=$serverId '
          'completed=${result['completed']} updatedAt=${result['updated_at']}',
        );
      }
      await _ackPush(spec, item, result, context, localVersion);
      return;
    }

    if (item.operation == OutboxOperation.delete) {
      final result = await remote.updateRow(
        spec.remoteTable,
        serverId,
        remoteVersion,
        _withTombstone(payload),
      );
      if (result == null) throw _TransientSyncError('tombstone CAS conflict');
      await _ackPush(spec, item, result, context, localVersion);
      return;
    }

    final currentLocal = await _readLocal(
      spec,
      item.localRowId,
      context.localAccountId,
    );
    if (_date(currentLocal?['updated_at']) != localVersion) {
      // A newer local edit happened while the remote row was being read.
      // Leave the coalesced outbox item pending for the next pass.
      return;
    }
    await _applyRemote(
      spec,
      remoteRow,
      context.localAccountId,
      context.authUserId,
    );
  }

  Future<void> _pull(
    SyncRemoteApi remote,
    SharedPreferences prefs,
    ({int localAccountId, String authUserId, int generation}) context,
  ) async {
    for (final spec in _pullOrder) {
      _ensureContext(context);
      final key =
          'dimi_sync_cursor_${context.localAccountId}_${spec.remoteTable}';
      final cursor = _date(prefs.getString(key));
      final rows = await remote.pullRows(
        spec.remoteTable,
        context.authUserId,
        cursor,
      );
      DateTime? newest = cursor;
      for (final remoteRow in rows) {
        _ensureContext(context);
        final version = _date(remoteRow['updated_at']);
        if (version != null && (newest == null || version.isAfter(newest)))
          newest = version;
        final serverId = remoteRow['id'] as String?;
        if (serverId == null) continue;
        if (spec.localTable == 'youtube_videos') {
          _log(
            'youtube pull server=$serverId completed=${remoteRow['completed']} '
            'updatedAt=${remoteRow['updated_at']}',
          );
        }
        final pending = await db.syncOutboxDao.findByServerId(
          context.localAccountId,
          spec.localTable,
          serverId,
        );
        if (pending != null) {
          final pendingBase = spec.localTable == 'tasks' ||
                  spec.localTable == 'youtube_videos'
              ? await _remoteVersionForPending(
                  spec,
                  context.localAccountId,
                  serverId,
                )
              : null;
          final relation = SyncVersionProtocol.classifyPendingPush(
            baseRemoteUpdatedAt: pendingBase ?? pending.baseRemoteUpdatedAt,
            remoteUpdatedAt: version,
          );
          // The remote row is still the local mutation's base. Keep SQLite's
          // pending payload intact and let the push phase perform CAS.
          if (relation == SyncVersionRelation.localNewer ||
              pending.operation == OutboxOperation.delete) {
            continue;
          }
          // Coalescing may have replaced the item while this row was being
          // inspected. Never let this pull apply over the newer mutation.
          final currentPending = await db.syncOutboxDao.findByServerId(
            context.localAccountId,
            spec.localTable,
            serverId,
          );
          if (currentPending == null ||
              currentPending.updatedAt != pending.updatedAt) {
            continue;
          }
          // A true normal-entity conflict is remote-wins; the remote row is
          // applied below and the discarded mutation is then completed.
        }
        try {
          await _applyRemote(
            spec,
            remoteRow,
            context.localAccountId,
            context.authUserId,
          );
        } catch (error, stackTrace) {
          if (spec.localTable != 'profile_data') rethrow;
          _log('profile pull skipped after local mapping error: $error');
          debugPrintStack(stackTrace: stackTrace);
          continue;
        }
        if (pending != null) {
          await db.syncOutboxDao.markCompletedIfCurrent(
            pending.id,
            pending.updatedAt,
          );
        }
      }
      if (newest != null)
        await prefs.setString(key, newest.toUtc().toIso8601String());
    }
  }

  Future<Map<String, dynamic>?> _readLocal(
    _SyncSpec spec,
    int localId,
    int accountId,
  ) async {
    final key = spec.localKey;
    final owner = spec.ownerColumn;
    final where = owner == null
        ? '$key = ?'
        : '$key = ? AND $owner = ?';
    final rows = await db
        .customSelect(
          'SELECT * FROM ${spec.localTable} WHERE $where',
          variables: owner == null
              ? [Variable.withInt(localId)]
              : [Variable.withInt(localId), Variable.withInt(accountId)],
        )
        .get();
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first.data);
  }

  Future<DateTime?> _remoteVersionForPending(
    _SyncSpec spec,
    int accountId,
    String serverId,
  ) async {
    final ownership = spec.localTable == 'tasks'
        ? 'local_account_id = ?'
        : 'id IN (SELECT playlist_local_id FROM youtube_playlists WHERE local_account_id = ?)';
    final rows = await db.customSelect(
      'SELECT remote_updated_at FROM ${spec.localTable} WHERE server_id = ? AND $ownership',
      variables: [
        Variable.withString(serverId),
        Variable.withInt(accountId),
      ],
    ).get();
    return rows.isEmpty
        ? null
        : _date(rows.first.read<String?>('remote_updated_at'));
  }

  Future<Map<String, dynamic>> _toRemote(
    _SyncSpec spec,
    Map<String, dynamic> row,
    String serverId,
    String userId,
  ) async {
    final result = <String, dynamic>{'id': serverId, 'user_id': userId};
    for (final field in spec.fields) {
      // Supabase default/trigger owns this value. Sending the device value
      // would turn the provisional local timestamp into remote authority.
      if (field.remote == 'updated_at') continue;
      var value = row[field.local];
      var remoteName = field.remote;
      if (field.local == 'task_id' && value != null) {
        value = await _serverId('tasks', value as int);
      }
      if (field.local == 'playlist_local_id') {
        value = await _serverId('youtube_playlists', value as int);
        remoteName = 'playlist_id';
      }
      if (field.dateOnly) {
        result[remoteName] = _localCalendarDate(value);
      } else if (_isBooleanRemoteField(field.remote)) {
        // Drift's raw SQLite rows represent booleans as 0/1. Supabase
        // boolean columns must receive Dart JSON booleans; otherwise a pull
        // can return false for is_planner_entry and make a local event vanish
        // from planner queries even though the remote row still exists.
        result[remoteName] = value is int ? value != 0 : value;
      } else {
        result[remoteName] = field.date
            ? SyncTimestamp.toUtcIso8601(value)
            : value;
      }
    }
    return result;
  }

  static bool _isBooleanRemoteField(String field) =>
      field == 'is_planner_entry' ||
      field == 'is_completed' ||
      field == 'is_enabled' ||
      field == 'completed';

  Future<String?> _serverId(String table, int localId) async {
    final rows = await db
        .customSelect(
          'SELECT server_id FROM $table WHERE id = ?',
          variables: [Variable.withInt(localId)],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String?>('server_id');
  }

  Future<bool> _ackLocal(
    _SyncSpec spec,
    int localId,
    Map<String, dynamic> remote,
    int accountId,
    DateTime? expectedLocalUpdatedAt,
  ) async {
    return _setLocalMetadata(
      spec,
      localId,
      remote['id'] as String?,
      _date(remote['updated_at']),
      accountId: accountId,
      expectedLocalUpdatedAt: expectedLocalUpdatedAt,
      remoteUpdatedAt: remote['updated_at']?.toString(),
    );
  }

  Future<bool> _ackPush(
    _SyncSpec spec,
    SyncOutboxData item,
    Map<String, dynamic> remote,
    ({int localAccountId, String authUserId, int generation}) context,
    DateTime? expectedLocalUpdatedAt,
  ) async {
    final applied = await _ackLocal(
      spec,
      item.localRowId,
      remote,
      context.localAccountId,
      expectedLocalUpdatedAt,
    );
    if (!applied) {
      final remoteUpdatedAt = _date(remote['updated_at']);
      if (remoteUpdatedAt != null) {
        await db.syncOutboxDao.rebaseIfCurrent(
          item.id,
          item.updatedAt,
          remoteUpdatedAt,
        );
      }
    }
    return applied;
  }

  Future<bool> _setLocalMetadata(
    _SyncSpec spec,
    int localId,
    String? serverId,
    DateTime? updatedAt,
    {
      int? accountId,
      DateTime? expectedLocalUpdatedAt,
      String? remoteUpdatedAt,
    }
  ) async {
    if (serverId == null && updatedAt == null && remoteUpdatedAt == null) {
      return false;
    }
    final assignments = <String>[];
    final vars = <Variable<Object>>[];
    if (serverId != null) {
      assignments.add('server_id = ?');
      vars.add(Variable.withString(serverId));
    }
    if (updatedAt != null) {
      assignments.add('updated_at = ?');
      // customStatement sends raw values to sqlite3; use Unix seconds int
      // matching Drift's default NativeDatabase DateTimeColumn encoding.
      vars.add(
        Variable.withInt(updatedAt.toUtc().millisecondsSinceEpoch ~/ 1000),
      );
    }
    if ((spec.localTable == 'tasks' || spec.localTable == 'youtube_videos') &&
        remoteUpdatedAt != null) {
      assignments.add('remote_updated_at = ?');
      vars.add(Variable.withString(remoteUpdatedAt));
    }
    final where = <String>['${spec.localKey} = ?'];
    vars.add(Variable.withInt(localId));
    if (spec.ownerColumn != null && accountId != null) {
      where.add('${spec.ownerColumn} = ?');
      vars.add(Variable.withInt(accountId));
    }
    if (expectedLocalUpdatedAt != null) {
      where.add('updated_at = ?');
      vars.add(Variable.withInt(
        expectedLocalUpdatedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
      ));
    }
    final changed = await db.customUpdate(
      'UPDATE ${spec.localTable} SET ${assignments.join(', ')} WHERE ${where.join(' AND ')}',
      variables: vars,
      updates: spec.localTable == 'tasks'
          ? {db.tasks}
          : spec.localTable == 'youtube_videos'
          ? {db.youtubeVideos}
          : null,
    );
    return changed > 0;
  }

  Future<void> _applyRemote(
    _SyncSpec spec,
    Map<String, dynamic> remote,
    int accountId,
    String userId,
  ) async {
    final serverId = remote['id'] as String?;
    if (serverId == null) return;
    final existing = spec.localTable == 'profile_data'
        ? await db
              .customSelect(
                'SELECT local_account_id FROM profile_data WHERE local_account_id = ?',
                variables: [Variable.withInt(accountId)],
              )
              .get()
        : spec.localTable == 'local_accounts'
        ? await db
              .customSelect(
                'SELECT id FROM local_accounts WHERE id = ?',
                variables: [Variable.withInt(accountId)],
              )
              .get()
        : spec.ownerColumn == null
        // Tables with indirect ownership (e.g. youtube_videos) are looked
        // up by server_id alone; account scoping is enforced by the FK chain.
        ? await db
              .customSelect(
                'SELECT ${spec.localKey} FROM ${spec.localTable} WHERE server_id = ?',
                variables: [Variable.withString(serverId)],
              )
              .get()
        : await db
              .customSelect(
                'SELECT ${spec.localKey} FROM ${spec.localTable} WHERE server_id = ? AND ${spec.ownerColumn} = ?',
                variables: [
                  Variable.withString(serverId),
                  Variable.withInt(accountId),
                ],
              )
              .get();
    final values = <String, Object?>{};
    final isUpdate = existing.isNotEmpty;
    for (final field in spec.fields) {
      // Progress fields marked preserveOnRemoteApply are owned locally.
      // Skip them when updating an existing row so that a remote metadata
      // refresh or a conflict-resolution pull cannot reset user progress
      // (e.g. completed, watched_at) that was written on this device.
      // These fields are still included in the push payload (_toRemote) so
      // they will be correct on Supabase after a successful push.
      if (isUpdate && field.preserveOnRemoteApply) continue;
      var value = remote[field.remote];
      if (field.remote == 'task_id' && value is String)
        value = await _localId('tasks', value, accountId);
      if (field.remote == 'playlist_id' && value is String)
        value = await _localId('youtube_playlists', value, accountId);
      if (field.dateOnly) {
        // Supabase `date` values are calendar dates, not instants. Parsing
        // them as UTC timestamps makes Planner range queries depend on the
        // device timezone after a pull.
        value = _calendarDate(value);
      } else if (field.date) {
        value = _date(value);
      }
      value = _coerceRemoteValue(spec, field, value);
      values[field.local] = value;
    }
    values['server_id'] = serverId;
    if ((spec.localTable == 'tasks' || spec.localTable == 'youtube_videos') &&
        remote['updated_at'] != null) {
      values['remote_updated_at'] = remote['updated_at'].toString();
    }
    // Only set the ownerColumn value when the table has a direct one.
    if (spec.ownerColumn != null) values[spec.ownerColumn!] = accountId;
    if (existing.isEmpty && spec.localTable == 'profile_data')
      values['local_account_id'] = accountId;
    if (existing.isEmpty) {
      final columns = values.keys.toList();
      final vars = columns.map((column) => _variable(values[column])).toList();
      await db.customStatement(
        'INSERT OR IGNORE INTO ${spec.localTable} (${columns.join(',')}) VALUES (${List.filled(columns.length, '?').join(',')})',
        vars.map((v) => v.value).toList(),
      );
    } else {
      final ownerCol = spec.ownerColumn;
      final columns = values.keys
          .where((c) => ownerCol == null || c != ownerCol)
          .toList();
      final vars = columns.map((c) => _variable(values[c])).toList();
      final whereParts = <String>[];
      if (spec.localTable == 'profile_data') {
        whereParts.add('local_account_id = ?');
        vars.add(Variable.withInt(accountId));
      } else {
        whereParts.add('server_id = ?');
        vars.add(Variable.withString(serverId));
      }
      if (spec.ownerColumn != null &&
          spec.localTable != 'local_accounts' &&
          spec.localTable != 'profile_data') {
        whereParts.add('${spec.ownerColumn} = ?');
        vars.add(Variable.withInt(accountId));
      }
      await db.customStatement(
        'UPDATE ${spec.localTable} SET ${columns.map((c) => '$c = ?').join(', ')} WHERE ${whereParts.join(' AND ')}',
        vars.map((v) => v.value).toList(),
      );
    }
  }

  Future<int?> _localId(String table, String serverId, int accountId) async {
    final rows = await db
        .customSelect(
          'SELECT id FROM $table WHERE server_id = ? AND local_account_id = ?',
          variables: [
            Variable.withString(serverId),
            Variable.withInt(accountId),
          ],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<int>('id');
  }

  Variable<Object> _variable(Object? value) {
    if (value == null) return const Variable<Object>(null);
    if (value is DateTime) {
      // customStatement passes raw values directly to sqlite3, which does not
      // accept DateTime objects.  Drift's default NativeDatabase datetime mode
      // stores DateTimeColumn as Unix seconds (integer), matching the boundary
      // check in SyncTimestamp.parse (< 100000000000 → treat as seconds).
      return Variable.withInt(value.toUtc().millisecondsSinceEpoch ~/ 1000);
    }
    if (value is bool) return Variable.withBool(value);
    if (value is int) return Variable.withInt(value);
    return Variable.withString(value.toString());
  }

  Object? _coerceRemoteValue(
    _SyncSpec spec,
    _Field field,
    Object? value,
  ) {
    if (spec.localTable != 'profile_data') return value;
    if (field.local == 'points') {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }
    if (field.local == 'role' ||
        field.local == 'phone' ||
        field.local == 'college' ||
        field.local == 'semester') {
      return value?.toString() ?? '';
    }
    return value;
  }

  Map<String, dynamic> _withTombstone(Map<String, dynamic> payload) => payload;

  void _ensureContext(
    ({int localAccountId, String authUserId, int generation}) context,
  ) {
    // When a test context is injected the auth guard is already bypassed;
    // the generation/currentUser check is skipped to avoid a Supabase
    // dependency in unit tests.
    if (_testContext != null) return;
    if (!AuthService.instance.isContextCurrent(
      context.generation,
      context.localAccountId,
      db,
    ))
      throw _ContextChanged();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[DIMI sync] $message');
  }

  static DateTime? _date(Object? value) {
    return SyncTimestamp.parse(value);
  }

  static DateTime? _calendarDate(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    final dateText = text.length >= 10 ? text.substring(0, 10) : text;
    final parts = dateText.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static String? _localCalendarDate(Object? value) {
    if (value == null) return null;
    final date = value is DateTime
        ? value
        : value is int
        ? DateTime.fromMillisecondsSinceEpoch(
            (value.abs() < 100000000000 ? value * 1000 : value),
          )
        : DateTime.tryParse(value.toString());
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class _TransientSyncError implements Exception {
  const _TransientSyncError(this.message);
  final String message;
  @override
  String toString() => message;
}

class _ContextChanged implements Exception {}

class _Field {
  const _Field(
    this.local,
    this.remote, {
    this.date = false,
    this.dateOnly = false,
    // When true this field is included in the push payload (→ Supabase) but
    // is NEVER overwritten during _applyRemote (← Supabase).  Use this for
    // user-progress fields that are owned locally — completion state,
    // watch progress, etc. — so that a metadata refresh or a conflict pull
    // cannot reset local progress.
    this.preserveOnRemoteApply = false,
  });
  final String local;
  final String remote;
  final bool date;
  final bool dateOnly;
  final bool preserveOnRemoteApply;
  _Field copy({String? remote}) => _Field(
    local,
    remote ?? this.remote,
    date: date,
    dateOnly: dateOnly,
    preserveOnRemoteApply: preserveOnRemoteApply,
  );
}

class _SyncSpec {
  const _SyncSpec(
    this.localTable,
    this.remoteTable,
    this.fields, {
    this.localKey = 'id',
    // The column used to scope rows to a local account. Set to null for tables
    // whose account ownership is indirect (e.g. youtube_videos is owned via
    // playlist_local_id → youtube_playlists.local_account_id).
    this.ownerColumn = 'local_account_id',
  });
  final String localTable;
  final String remoteTable;
  final List<_Field> fields;
  final String localKey;
  final String? ownerColumn;
}

final _specs = <String, _SyncSpec>{
  OutboxEntity.account: const _SyncSpec('local_accounts', 'dim_accounts', [
    _Field('auth_user_id', 'user_id'),
    _Field('display_name', 'display_name'),
    _Field('avatar_url', 'avatar_url'),
    _Field('created_at', 'created_at', date: true),
    _Field('last_login_at', 'last_login_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
  ], ownerColumn: 'id'),
  OutboxEntity.profile: const _SyncSpec('profile_data', 'dim_profile_data', [
    _Field('role', 'role'),
    _Field('phone', 'phone'),
    _Field('college', 'college'),
    _Field('semester', 'semester'),
    _Field('points', 'points'),
    _Field('created_at', 'created_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
  ], localKey: 'local_account_id'),
  OutboxEntity.task: const _SyncSpec('tasks', 'dim_tasks', [
    _Field('title', 'title'),
    _Field('description', 'description'),
    _Field('category', 'category'),
    // Planner classification is local entity identity. Preserve it on an
    // existing row so a stale/legacy remote false cannot hide an event from
    // the planner after navigation or a pull refresh.
    _Field('is_planner_entry', 'is_planner_entry', preserveOnRemoteApply: true),
    _Field('local_date', 'local_date', date: true, dateOnly: true),
    _Field('due_time_hhmm', 'due_time_hhmm'),
    _Field('is_completed', 'is_completed'),
    _Field('completed_at', 'completed_at', date: true),
    _Field('created_at', 'created_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
  ]),
  OutboxEntity.reminder: const _SyncSpec('reminders', 'dim_reminders', [
    _Field('task_id', 'task_id'),
    _Field('title', 'title'),
    _Field('due_at', 'due_at', date: true),
    _Field('is_enabled', 'is_enabled'),
    _Field('created_at', 'created_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
  ]),
  OutboxEntity.note: const _SyncSpec('notes', 'dim_notes', [
    _Field('title', 'title'),
    _Field('content', 'content'),
    _Field('category', 'category'),
    _Field('created_at', 'created_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
  ]),
  OutboxEntity.moneyTransaction: const _SyncSpec(
    'money_transactions',
    'dim_money_transactions',
    [
      _Field('type', 'type'),
      _Field('amount_minor', 'amount_minor'),
      _Field('currency', 'currency'),
      _Field('category', 'category'),
      _Field('note', 'note'),
      _Field('counterparty', 'counterparty'),
      _Field('occurred_on', 'occurred_on', date: true),
      _Field('source', 'source'),
      _Field('created_at', 'created_at', date: true),
      _Field('updated_at', 'updated_at', date: true),
      _Field('deleted_at', 'deleted_at', date: true),
    ],
  ),
  OutboxEntity.merchantRule: const _SyncSpec(
    'merchant_category_rules',
    'dim_merchant_category_rules',
    [
      _Field('merchant_identity', 'merchant_identity'),
      _Field('category', 'category'),
      _Field('created_at', 'created_at', date: true),
      _Field('updated_at', 'updated_at', date: true),
      _Field('deleted_at', 'deleted_at', date: true),
    ],
  ),
  OutboxEntity.playlist: const _SyncSpec(
    'youtube_playlists',
    'dim_youtube_playlists',
    [
      _Field('youtube_playlist_id', 'youtube_playlist_id'),
      _Field('title', 'title'),
      _Field('description', 'description'),
      _Field('channel_title', 'channel_title'),
      _Field('thumbnail_url', 'thumbnail_url'),
      _Field('total_videos', 'total_videos'),
      _Field('total_duration_seconds', 'total_duration_seconds'),
      _Field('last_synced_at', 'last_synced_at', date: true),
      _Field('created_at', 'created_at', date: true),
      _Field('updated_at', 'updated_at', date: true),
      _Field('deleted_at', 'deleted_at', date: true),
    ],
  ),
  OutboxEntity.video: const _SyncSpec('youtube_videos', 'dim_youtube_videos', [
    _Field('playlist_local_id', 'playlist_id'),
    _Field('youtube_video_id', 'youtube_video_id'),
    _Field('title', 'title'),
    _Field('thumbnail_url', 'thumbnail_url'),
    _Field('position', 'position'),
    _Field('duration_seconds', 'duration_seconds'),
    _Field('duration_iso', 'duration_iso'),
    // User-progress fields: pushed to Supabase in the normal push path but
    // never overwritten by _applyRemote on an existing local row.  This
    // prevents a metadata refresh or a conflict-resolution pull from
    // resetting locally-recorded completion state back to false.
    _Field('completed', 'completed', preserveOnRemoteApply: true),
    _Field('watched_at', 'watched_at', date: true, preserveOnRemoteApply: true),
    _Field(
      'last_position_seconds',
      'last_position_seconds',
      preserveOnRemoteApply: true,
    ),
    _Field(
      'progress_updated_at',
      'progress_updated_at',
      date: true,
      preserveOnRemoteApply: true,
    ),
    _Field('created_at', 'created_at', date: true),
    _Field('updated_at', 'updated_at', date: true),
    _Field('deleted_at', 'deleted_at', date: true),
    // youtube_videos has no direct local_account_id column; ownership is
    // indirect through playlist_local_id → youtube_playlists.local_account_id.
  ], ownerColumn: null),
};

final _pullOrder = <_SyncSpec>[
  _specs[OutboxEntity.account]!,
  _specs[OutboxEntity.profile]!,
  _specs[OutboxEntity.task]!,
  _specs[OutboxEntity.note]!,
  _specs[OutboxEntity.moneyTransaction]!,
  _specs[OutboxEntity.merchantRule]!,
  _specs[OutboxEntity.playlist]!,
  _specs[OutboxEntity.reminder]!,
  _specs[OutboxEntity.video]!,
];
