import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/daos/note_dao.dart';
import 'package:dimi_app/data/daos/sync_outbox_dao.dart';

import 'dart:io';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.localAccountDao.ensureOfflineAccount();
  });

  tearDown(() => db.close());

  test(
    'v9 schema has no obsolete tables and stores finance in minor units',
    () async {
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      expect(names, isNot(contains('class_sessions')));
      expect(names, isNot(contains('study_sessions')));
      expect(names, isNot(contains('courses')));
      expect(names, isNot(contains('document_meta')));

      await db.moneyDao.insertTransaction(
        MoneyTransactionsCompanion.insert(
          type: 'expense',
          amount: 80000,
          category: 'Other',
          note: const Value('Took a loan from Priyanshu'),
          date: DateTime.now(),
        ),
      );
      await db.moneyDao.insertTransaction(
        MoneyTransactionsCompanion.insert(
          type: 'lent',
          amount: 50000,
          category: 'Lent',
          note: const Value('Gave ₹500 to Rahul'),
          date: DateTime.now(),
        ),
      );
      expect(await db.moneyDao.totalForType('expense'), 80000);
      expect(await db.moneyDao.totalForType('lent'), 50000);
    },
  );

  test('account switching isolates task data', () async {
    final accountB = await db
        .into(db.localAccounts)
        .insert(
          LocalAccountsCompanion.insert(
            authProvider: 'offline-test',
            displayName: const Value('B'),
            createdAt: DateTime.now(),
          ),
        );
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'A task',
        category: 'Personal',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await db.localAccountDao.activate(accountB);
    expect(await db.taskDao.watchAllTasks().first, isEmpty);
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'B task',
        category: 'Personal',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await db.localAccountDao.activate(1);
    expect((await db.taskDao.watchAllTasks().first).single.title, 'A task');
  });

  test('authenticated identities get separate local accounts and logout returns offline', () async {
    final alice = await db.localAccountDao.ensureAuthenticatedAccount(
      userId: 'auth-alice',
      email: 'alice@example.com',
      displayName: 'Alice',
      avatarUrl: null,
    );
    final bob = await db.localAccountDao.ensureAuthenticatedAccount(
      userId: 'auth-bob',
      email: 'bob@example.com',
      displayName: 'Bob',
      avatarUrl: null,
    );
    expect(alice, isNot(bob));
    expect(db.activeAccountId, bob);
    await db.localAccountDao.ensureOfflineAccount();
    expect((await db.localAccountDao.getActive())?.authProvider, 'offline');
  });

  test(
    'profile writes stay on the active account and keep one active account',
    () async {
      final accountB = await db.localAccountDao.ensureAuthenticatedAccount(
        userId: 'profile-b',
        email: 'profile-b@example.com',
        displayName: 'Profile B',
        avatarUrl: null,
      );
      await db.profileDao.upsertProfile(
        ProfileTableCompanion(
          id: const Value(1),
          name: const Value('Should belong to B'),
          role: const Value('Student'),
        ),
      );

      expect(db.activeAccountId, accountB);
      expect((await db.profileDao.getProfile())?.name, 'Should belong to B');
      expect(
        await (db.select(
          db.localAccounts,
        )..where((account) => account.isActive.equals(true))).get(),
        hasLength(1),
      );
      expect(
        await (db.select(db.profileData)
              ..where((profile) => profile.localAccountId.equals(accountB)))
            .getSingle(),
        isNotNull,
      );

      await db.localAccountDao.activate(1);
      final offlineProfile = await db.profileDao.getProfile();
      expect(offlineProfile?.name, 'Student');
      expect(offlineProfile?.role, isEmpty);
    },
  );

  test(
    'account activation gates scoped work and keeps outbox ownership isolated',
    () async {
      final alice = await db.localAccountDao.ensureAuthenticatedAccount(
        userId: 'gate-alice',
        email: 'alice@gate.test',
        displayName: 'Alice',
        avatarUrl: null,
      );
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          title: 'Alice task',
          category: 'Test',
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      final bob = await db.localAccountDao.ensureAuthenticatedAccount(
        userId: 'gate-bob',
        email: 'bob@gate.test',
        displayName: 'Bob',
        avatarUrl: null,
      );
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          title: 'Bob task',
          category: 'Test',
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      expect(db.activeAccountId, bob);
      expect(
        (await db.syncOutboxDao.pendingCount(alice)),
        greaterThanOrEqualTo(2),
      );
      expect(
        (await db.syncOutboxDao.pendingCount(bob)),
        greaterThanOrEqualTo(2),
      );
      await db.localAccountDao.activate(alice);
      expect(db.activeAccountId, alice);
      expect(
        (await db.taskDao.watchAllTasks().first).single.title,
        'Alice task',
      );
      await db.localAccountDao.ensureOfflineAccount();
      expect((await db.localAccountDao.getActive())?.authProvider, 'offline');
      expect(db.activeAccountId, isNot(alice));
    },
  );

  test('v9 finance types use minor units and no loan schema remains', () async {
    await db.moneyDao.insertTransaction(
      MoneyTransactionsCompanion.insert(
        type: 'lent',
        amount: 12550,
        category: 'Lent',
        date: DateTime.now(),
      ),
    );
    await db.moneyDao.insertTransaction(
      MoneyTransactionsCompanion.insert(
        type: 'borrowed',
        amount: 20000,
        category: 'Borrowed',
        date: DateTime.now(),
      ),
    );
    expect(await db.moneyDao.totalForType('lent'), 12550);
    expect(await db.moneyDao.totalForType('borrowed'), 20000);
    final columns = await db
        .customSelect('PRAGMA table_info(money_transactions)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      isNot(contains('loan_id')),
    );
  });

  test(
    'finance update returns bool while preserving Drift write semantics',
    () async {
      final id = await db.moneyDao.insertTransaction(
        MoneyTransactionsCompanion.insert(
          type: 'expense',
          amount: 100,
          category: 'Test',
          date: DateTime(2020),
        ),
      );
      expect(
        await db.moneyDao.updateTransaction(
          MoneyTransactionsCompanion(
            id: Value(id),
            type: const Value('income'),
            amount: const Value(200),
            category: const Value('Updated'),
            date: Value(DateTime(2020, 1, 2)),
          ),
        ),
        isTrue,
      );
      expect(
        (await db.moneyDao.watchAllTransactions().first).single.type,
        'income',
      );
      expect(
        await db.moneyDao.updateTransaction(
          const MoneyTransactionsCompanion(id: Value(999999)),
        ),
        isFalse,
      );
    },
  );

  test('note update returns bool and ignores tombstoned rows', () async {
    final noteDao = NoteDao(db);
    final id = await noteDao.insertNote(
      NotesCompanion.insert(
        title: 'Original',
        content: 'Body',
        category: 'Test',
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
      ),
    );
    expect(
      await noteDao.updateNote(
        NotesCompanion(
          id: Value(id),
          title: const Value('Updated'),
          content: const Value('Body 2'),
          category: const Value('Test'),
        ),
      ),
      isTrue,
    );
    expect((await noteDao.watchAllNotes().first).single.title, 'Updated');
    await noteDao.deleteNote(id);
    expect(
      await noteDao.updateNote(
        NotesCompanion(id: Value(id), title: const Value('No update')),
      ),
      isFalse,
    );
  });

  test('local mutations create one coalesced outbox operation', () async {
    final taskId = await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Outbox task',
        category: 'Test',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    expect(await db.syncOutboxDao.pendingCount(db.activeAccountId), 1);
    await db.taskDao.updateTask(
      TasksCompanion(id: Value(taskId), title: const Value('Updated')),
    );
    expect(await db.syncOutboxDao.pendingCount(db.activeAccountId), 1);
    final row = await (db.select(
      db.syncOutbox,
    )..where((o) => o.localRowId.equals(taskId))).getSingle();
    expect(row.operation, OutboxOperation.create);
    await db.taskDao.deleteTask(taskId);
    final deleted = await (db.select(
      db.syncOutbox,
    )..where((o) => o.localRowId.equals(taskId))).getSingle();
    expect(deleted.operation, OutboxOperation.delete);
  });

  test('authenticated account and profile mutations are represented', () async {
    final accountId = await db.localAccountDao.ensureAuthenticatedAccount(
      userId: 'outbox-auth-user',
      email: 'outbox@example.com',
      displayName: 'Outbox User',
      avatarUrl: null,
    );
    await db.profileDao.upsertProfile(
      ProfileTableCompanion(
        id: Value(accountId),
        name: const Value('Outbox User'),
        role: const Value('Student'),
      ),
    );
    final rows = await (db.select(
      db.syncOutbox,
    )..where((o) => o.localAccountId.equals(accountId))).get();
    expect(
      rows.map((row) => row.entityType),
      containsAll([OutboxEntity.account, OutboxEntity.profile]),
    );
  });

  test(
    'outbox preserves relationship order and retry/completion state',
    () async {
      final taskId = await db.taskDao.insertTask(
        TasksCompanion.insert(
          title: 'Parent',
          category: 'Test',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
      );
      final reminderId = await db.reminderDao.insertReminder(
        RemindersCompanion.insert(
          taskId: Value(taskId),
          title: 'Child',
          dueAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      final entries = await (db.select(
        db.syncOutbox,
      )..where((o) => o.localAccountId.equals(db.activeAccountId))).get();
      final task = entries.singleWhere(
        (e) => e.localRowId == taskId && e.entityType == OutboxEntity.task,
      );
      final reminder = entries.singleWhere(
        (e) =>
            e.localRowId == reminderId && e.entityType == OutboxEntity.reminder,
      );
      expect(task.dependencyRank, lessThan(reminder.dependencyRank));
      await db.syncOutboxDao.markProcessing(task.id);
      await db.syncOutboxDao.markRetryable(
        task.id,
        'offline',
        delay: Duration.zero,
      );
      final retry = await (db.select(
        db.syncOutbox,
      )..where((o) => o.id.equals(task.id))).getSingle();
      expect(retry.state, OutboxState.retryableError);
      expect(retry.attemptCount, 1);
      await db.syncOutboxDao.markCompleted(task.id);
      expect(
        (await (db.select(
          db.syncOutbox,
        )..where((o) => o.id.equals(task.id))).getSingle()).state,
        OutboxState.completed,
      );
      expect(await db.syncOutboxDao.removeCompleted(), 1);
    },
  );

  test('pending outbox survives database reopen', () async {
    final dir = await Directory.systemTemp.createTemp('dimi-outbox-test-');
    final file = File('${dir.path}${Platform.pathSeparator}dimi.sqlite');
    final first = AppDatabase.forTesting(NativeDatabase(file));
    await first.localAccountDao.ensureOfflineAccount();
    await first.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Persistent outbox task',
        category: 'Test',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await first.close();
    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    expect(await reopened.syncOutboxDao.pendingCount(1), 1);
    await reopened.close();
    await dir.delete(recursive: true);
  });

  test('reminders link to planner tasks and delete transactionally', () async {
    final taskId = await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Future event',
        category: 'Study',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        dueTime: const Value('10:00'),
        isPlannerEntry: const Value(true),
        createdAt: DateTime.now(),
      ),
    );
    final reminderId = await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        taskId: Value(taskId),
        title: 'Future event',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      ),
    );
    expect((await db.reminderDao.getByTaskId(taskId))?.id, reminderId);
    final notificationId = await db.taskDao.deleteTaskWithReminder(taskId);
    expect(notificationId, isNotNull);
    expect(await db.reminderDao.getByTaskId(taskId), isNull);
  });

  test('heatmap query is bounded to requested planner range', () async {
    final now = DateTime.now();
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Old',
        category: 'Study',
        dueDate: DateTime(2020),
        isPlannerEntry: const Value(true),
        createdAt: now,
      ),
    );
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Recent',
        category: 'Study',
        dueDate: now,
        isPlannerEntry: const Value(true),
        createdAt: now,
      ),
    );
    final rows = await db.taskDao
        .watchPlannerEntriesInRange(
          DateTime(now.year - 1),
          DateTime(now.year + 1),
        )
        .first;
    expect(rows.map((row) => row.title), contains('Recent'));
    expect(rows.map((row) => row.title), isNot(contains('Old')));
  });

  test('youtube playlists and progress are isolated by account', () async {
    final playlistId = await db.youtubePlaylistDao.savePlaylist(
      playlist: YoutubePlaylistsCompanion.insert(
        youtubePlaylistId: 'PL1234567890123',
        title: 'A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      videos: [
        YoutubeVideosCompanion.insert(
          playlistLocalId: 0,
          youtubeVideoId: 'video-a',
          title: 'Video A',
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
    );
    final video = (await db.youtubePlaylistDao.getVideos(playlistId)).single;
    await db.youtubePlaylistDao.setCompleted(video.id, true);
    expect(
      (await db.youtubePlaylistDao.getVideos(playlistId)).single.completed,
      isTrue,
    );
    final accountB = await db
        .into(db.localAccounts)
        .insert(
          LocalAccountsCompanion.insert(
            authProvider: 'offline-test',
            displayName: const Value('B'),
            createdAt: DateTime.now(),
          ),
        );
    await db.localAccountDao.activate(accountB);
    expect(await db.youtubePlaylistDao.getVideos(playlistId), isEmpty);
  });

  test('reminders carry the local account foreign key', () async {
    final foreignKeys = await db
        .customSelect('PRAGMA foreign_key_list(reminders)')
        .get();
    expect(
      foreignKeys.map((row) => row.read<String>('table')),
      contains('local_accounts'),
    );
  });

  test('phase 1 sync metadata is additive', () async {
    const syncTables = [
      'local_accounts',
      'profile_data',
      'tasks',
      'reminders',
      'notes',
      'money_transactions',
      'youtube_playlists',
      'youtube_videos',
    ];
    for (final table in syncTables) {
      final columns = await db.customSelect('PRAGMA table_info($table)').get();
      final names = columns.map((row) => row.read<String>('name')).toSet();
      expect(names, contains('server_id'), reason: table);
      expect(names, contains('updated_at'), reason: table);
      expect(names, contains('deleted_at'), reason: table);
    }
    // Detection tables (transaction_detection_events, transaction_candidates,
    // merchant_category_rules) were dropped in schema v14 and no longer exist.
    final eventColumns = await db
        .customSelect('PRAGMA table_info(transaction_detection_events)')
        .get();
    expect(
      eventColumns,
      isEmpty,
      reason:
          'transaction_detection_events should not exist after v14 migration',
    );
  });

  test('task deletion tombstones the task and linked reminder', () async {
    final old = DateTime(2020);
    final taskId = await db.taskDao.insertTask(
      TasksCompanion.insert(
        title: 'Tombstone task',
        category: 'Test',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isPlannerEntry: const Value(true),
        createdAt: old,
        updatedAt: Value(old),
        serverId: const Value('task-server-id'),
      ),
    );
    final reminderId = await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        taskId: Value(taskId),
        title: 'Tombstone reminder',
        dueAt: DateTime.now().add(const Duration(days: 2)),
        serverId: const Value('reminder-server-id'),
        updatedAt: Value(old),
      ),
    );

    final before = DateTime.now();
    await db.taskDao.deleteTaskWithReminder(taskId);
    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingle();
    final reminder = await (db.select(
      db.reminders,
    )..where((r) => r.id.equals(reminderId))).getSingle();

    expect(task.serverId, 'task-server-id');
    expect(task.deletedAt, isNotNull);
    expect(
      task.updatedAt.isAfter(before) || task.updatedAt.isAtSameMomentAs(before),
      isTrue,
    );
    expect(reminder.serverId, 'reminder-server-id');
    expect(reminder.deletedAt, isNotNull);
    expect(
      await db.taskDao
          .watchPlannerEntriesInRange(DateTime(2019), DateTime(2030))
          .first,
      isEmpty,
    );
    expect(await db.reminderDao.getByTaskId(taskId), isNull);
  });

  test('playlist deletion tombstones playlist and videos without losing progress fields', () async {
    final playlistId = await db.youtubePlaylistDao.savePlaylist(
      playlist: YoutubePlaylistsCompanion.insert(
        youtubePlaylistId: 'PL-TOMBSTONE',
        title: 'Tombstone playlist',
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
        serverId: const Value('playlist-server-id'),
      ),
      videos: [
        YoutubeVideosCompanion.insert(
          playlistLocalId: 0,
          youtubeVideoId: 'video-tombstone',
          title: 'Video',
          position: 0,
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
          serverId: const Value('video-server-id'),
        ),
      ],
    );
    final video = (await db.youtubePlaylistDao.getVideos(playlistId)).single;
    await db.youtubePlaylistDao.setCompleted(video.id, true);
    final before = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(video.id))).getSingle();
    await db.youtubePlaylistDao.deletePlaylist(playlistId);

    final playlist = await (db.select(
      db.youtubePlaylists,
    )..where((p) => p.id.equals(playlistId))).getSingle();
    final deletedVideo = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(video.id))).getSingle();
    expect(playlist.serverId, 'playlist-server-id');
    expect(playlist.deletedAt, isNotNull);
    expect(deletedVideo.serverId, 'video-server-id');
    expect(deletedVideo.deletedAt, isNotNull);
    expect(deletedVideo.completed, before.completed);
    expect(deletedVideo.progressUpdatedAt, before.progressUpdatedAt);
    expect(await db.youtubePlaylistDao.watchForUser('ignored').first, isEmpty);
    expect(await db.youtubePlaylistDao.getVideos(playlistId), isEmpty);
  });
}
