import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks.dart';
import 'tables/transactions.dart';
import 'tables/notes.dart';
import 'tables/reminders.dart';
import 'tables/local_accounts.dart';
import 'tables/profile_data.dart';
import 'tables/transaction_detection.dart';
import 'tables/youtube_playlists.dart';
import 'tables/youtube_videos.dart';
import 'tables/sync_outbox.dart';

// DAOs
import 'daos/task_dao.dart';
import 'daos/money_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/note_dao.dart';
import 'daos/transaction_detection_dao.dart';
import 'daos/youtube_playlist_dao.dart';
import 'daos/local_account_dao.dart';
import 'daos/sync_outbox_dao.dart';

export 'tables/profile.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    MoneyTransactions,
    Notes,
    Reminders,
    LocalAccounts,
    ProfileData,
    TransactionDetectionEvents,
    TransactionCandidates,
    MerchantCategoryRules,
    YoutubePlaylists,
    YoutubeVideos,
    SyncOutbox,
  ],
  daos: [
    TaskDao,
    MoneyDao,
    ReminderDao,
    ProfileDao,
    NoteDao,
    TransactionDetectionDao,
    YoutubePlaylistDao,
    LocalAccountDao,
    SyncOutboxDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Allow injecting a custom executor (e.g. in-memory DB for tests).
  AppDatabase.forTesting(super.executor);

  // Zero means no account context has been activated yet. Callers must await
  // account initialization instead of accidentally reading local account 1.
  int _activeAccountId = 0;
  final StreamController<int> _activeAccountChanges =
      StreamController<int>.broadcast();
  int get activeAccountId => _activeAccountId;
  Stream<int> watchActiveAccountId() async* {
    yield _activeAccountId;
    yield* _activeAccountChanges.stream;
  }

  void setActiveAccountId(int id) {
    if (_activeAccountId == id) return;
    _activeAccountId = id;
    _activeAccountChanges.add(id);
  }

  @override
  Future<void> close() async {
    await _activeAccountChanges.close();
    await super.close();
  }

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.completedAt);
      }
      if (from < 3) {
        await m.addColumn(tasks, tasks.isPlannerEntry);
      }
      if (from < 5) {
        await m.createTable(transactionDetectionEvents);
        await m.createTable(transactionCandidates);
        await m.createTable(merchantCategoryRules);
      }
      if (from < 6) {
        await m.addColumn(
          transactionCandidates,
          transactionCandidates.accountHint,
        );
        await m.addColumn(
          transactionCandidates,
          transactionCandidates.paymentMethod,
        );
        await m.addColumn(
          transactionCandidates,
          transactionCandidates.balanceAfterMinor,
        );
      }
      if (from < 7) {
        await m.addColumn(
          transactionCandidates,
          transactionCandidates.bankConfirmationStatus,
        );
      }
      if (from < 8) {
        await m.createTable(youtubePlaylists);
        await m.createTable(youtubeVideos);
      }
      if (from < 9) {
        // The v9 table definitions are rebuilt below so existing rows are
        // copied into their renamed/expanded columns without recreating the DB.
        await customStatement('PRAGMA foreign_keys = OFF');
        await _migrateV8ToV9(m);
        await customStatement('PRAGMA foreign_keys = ON');
      }
      if (from < 10) {
        await _migrateV9ToV10();
      }
      if (from < 11) {
        await m.createTable(syncOutbox);
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_outbox_identity ON sync_outbox(local_account_id, entity_type, local_row_id)',
        );
      }
      if (from < 12) {
        await m.addColumn(tasks, tasks.remoteUpdatedAt);
      }
      if (from < 13) {
        await m.addColumn(youtubeVideos, youtubeVideos.remoteUpdatedAt);
      }
    },
  );

  Future<void> _migrateV9ToV10() async {
    final syncTables = <String>[
      'local_accounts',
      'profile_data',
      'tasks',
      'reminders',
      'notes',
      'money_transactions',
      'youtube_playlists',
      'youtube_videos',
      'merchant_category_rules',
    ];
    for (final table in syncTables) {
      await customStatement('ALTER TABLE $table ADD COLUMN server_id TEXT');
      await customStatement('ALTER TABLE $table ADD COLUMN deleted_at INTEGER');
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${table}_server_id ON $table(server_id)',
      );
    }
    await customStatement(
      'ALTER TABLE local_accounts ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE local_accounts SET updated_at = created_at WHERE updated_at = 0',
    );
  }

  Future<void> _migrateV8ToV9(Migrator m) async {
    // Obsolete feature tables are intentionally removed in v9.
    for (final table in [
      'class_sessions',
      'study_sessions',
      'courses',
      'document_meta',
    ]) {
      await customStatement('DROP TABLE IF EXISTS $table');
    }
    await m.createTable(localAccounts);
    await m.createTable(profileData);
    // Preserve the old singleton profile before dropping its table. Identity
    // fields move to local_accounts; editable fields move to profile_data.
    await customStatement(
      'INSERT OR IGNORE INTO local_accounts (id, auth_provider, auth_user_id, email, display_name, avatar_url, is_active, created_at) SELECT 1, \'offline\', NULL, NULLIF(email, \'\'), COALESCE(NULLIF(name, \'\'), \'Student\'), photo_path, 1, strftime(\'%s\', \'now\') * 1000 FROM profile WHERE id = 1',
    );
    await customStatement(
      'INSERT OR IGNORE INTO local_accounts (id, auth_provider, is_active, display_name, created_at) VALUES (1, \'offline\', 1, \'Student\', strftime(\'%s\', \'now\') * 1000)',
    );
    await customStatement(
      'INSERT OR IGNORE INTO profile_data (local_account_id, role, phone, college, semester, points, created_at, updated_at) SELECT 1, role, phone, college, semester, points, strftime(\'%s\', \'now\') * 1000, strftime(\'%s\', \'now\') * 1000 FROM profile WHERE id = 1',
    );
    await customStatement(
      'INSERT OR IGNORE INTO profile_data (local_account_id, created_at, updated_at) VALUES (1, strftime(\'%s\', \'now\') * 1000, strftime(\'%s\', \'now\') * 1000)',
    );
    await customStatement('DROP TABLE IF EXISTS profile');

    // Add v9 columns and preserve v8 values. SQLite keeps legacy columns that
    // are not represented by the new Drift model harmlessly until compaction.
    await customStatement(
      'ALTER TABLE tasks RENAME COLUMN due_date TO local_date',
    );
    await customStatement(
      'ALTER TABLE tasks RENAME COLUMN due_time TO due_time_hhmm',
    );
    await customStatement(
      'ALTER TABLE tasks ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE tasks ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE tasks SET updated_at = created_at WHERE updated_at = 0',
    );
    await customStatement(
      'ALTER TABLE reminders ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement('ALTER TABLE reminders ADD COLUMN task_id INTEGER');
    await customStatement(
      'ALTER TABLE reminders ADD COLUMN notification_id INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE reminders ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE reminders ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE reminders SET notification_id = id, created_at = due_at, updated_at = due_at WHERE notification_id = 0',
    );
    await customStatement('ALTER TABLE reminders RENAME TO reminders_v8');
    await customStatement('''
      CREATE TABLE reminders (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        local_account_id INTEGER NOT NULL DEFAULT 1 REFERENCES local_accounts(id),
        task_id INTEGER REFERENCES tasks(id) ON DELETE SET NULL,
        notification_id INTEGER NOT NULL DEFAULT 0 UNIQUE,
        title TEXT NOT NULL,
        due_at INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      INSERT INTO reminders (id, local_account_id, task_id, notification_id, title, due_at, is_enabled, created_at, updated_at)
      SELECT id, local_account_id, task_id, notification_id, title, due_at, is_enabled, created_at, updated_at
      FROM reminders_v8
    ''');
    await customStatement('DROP TABLE reminders_v8');
    await customStatement('CREATE INDEX idx_reminders_account_enabled_due ON reminders(local_account_id, is_enabled, due_at)');
    await customStatement('CREATE INDEX idx_reminders_task_id ON reminders(task_id)');
    await customStatement(
      'ALTER TABLE notes ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE money_transactions RENAME COLUMN amount TO amount_minor',
    );
    await customStatement(
      'ALTER TABLE money_transactions RENAME COLUMN date TO occurred_on',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN currency TEXT NOT NULL DEFAULT \'INR\'',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN counterparty TEXT',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN source TEXT NOT NULL DEFAULT \'manual\'',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN detection_candidate_id TEXT',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE money_transactions ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE money_transactions SET amount_minor = ROUND(amount_minor * 100), created_at = occurred_on, updated_at = occurred_on WHERE created_at = 0',
    );
    await customStatement(
      'ALTER TABLE transaction_detection_events ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE transaction_detection_events ADD COLUMN processed_at INTEGER',
    );
    await customStatement(
      'ALTER TABLE transaction_detection_events ADD COLUMN expires_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE transaction_detection_events SET expires_at = received_at + 2592000000 WHERE expires_at = 0',
    );
    await customStatement(
      'ALTER TABLE transaction_candidates ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE transaction_candidates ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE transaction_candidates ADD COLUMN expires_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE transaction_candidates SET updated_at = created_at, expires_at = occurred_at + 7776000000 WHERE updated_at = 0',
    );
    await customStatement(
      'ALTER TABLE merchant_category_rules ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE merchant_category_rules ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE merchant_category_rules SET created_at = updated_at WHERE created_at = 0',
    );
    await customStatement(
      'ALTER TABLE youtube_playlists ADD COLUMN local_account_id INTEGER NOT NULL DEFAULT 1',
    );
    await customStatement(
      'ALTER TABLE youtube_videos ADD COLUMN progress_updated_at INTEGER',
    );
  }
}

/// Opens the SQLite file in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'dimi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
