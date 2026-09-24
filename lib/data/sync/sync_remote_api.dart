import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SyncRemoteApi {
  Future<Map<String, dynamic>?> getRow(String table, String serverId);

  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  );

  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  );

  Future<List<Map<String, dynamic>>> pullRows(
    String table,
    String userId,
    DateTime? after,
  );
}

class SupabaseSyncRemoteApi implements SyncRemoteApi {
  const SupabaseSyncRemoteApi(this.client);

  final SupabaseClient client;

  @override
  Future<Map<String, dynamic>?> getRow(String table, String serverId) async {
    debugPrint('[DIMI sync remote] get table=$table id=$serverId');
    final row = await client.from(table).select().eq('id', serverId).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('[DIMI sync remote] insert table=$table id=${payload['id']} user=${payload['user_id']}');
    final row = await client.from(table).insert(payload).select().single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  ) async {
    debugPrint(
      '[DIMI sync remote] CAS update table=$table id=$serverId '
      'expected=$expectedUpdatedAt completed=${payload['completed']} '
      'payload=$payload',
    );
    final rows = await client
        .from(table)
        .update(payload)
        .eq('id', serverId)
        .eq('updated_at', expectedUpdatedAt.toUtc().toIso8601String())
        .select();
    if (rows.isEmpty) {
      debugPrint(
        '[DIMI sync remote] CAS update returned 0 rows '
        'table=$table id=$serverId',
      );
      return null;
    }
    debugPrint(
      '[DIMI sync remote] CAS update returned '
      'table=$table id=$serverId completed=${rows.first['completed']} '
      'updatedAt=${rows.first['updated_at']}',
    );
    return Map<String, dynamic>.from(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> pullRows(
    String table,
    String userId,
    DateTime? after,
  ) async {
    debugPrint('[DIMI sync remote] pull table=$table user=$userId after=$after');
    var query = client.from(table).select().eq('user_id', userId);
    if (after != null) {
      // Include the boundary because PostgreSQL timestamps can tie. The
      // worker deduplicates equal server versions locally.
      query = query.gte(
        'updated_at',
        after.subtract(const Duration(microseconds: 1)).toIso8601String(),
      );
    }
    final rows = await query.order('updated_at');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
