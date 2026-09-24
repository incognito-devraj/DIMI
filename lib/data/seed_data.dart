// ignore_for_file: avoid_print
import 'package:drift/drift.dart';

import 'database.dart';

/// Inserts representative sample data so every screen has something to render
/// during development. Debug-only — called once when DB is freshly created.
Future<void> seedDatabase(AppDatabase db) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // ── Profile ──────────────────────────────────────────────────────────────
  await db.profileDao.upsertProfile(
    const ProfileTableCompanion(
      id: Value(1),
      name: Value('Student'),
      role: Value(''),
      email: Value(''),
      phone: Value(''),
      college: Value(''),
      semester: Value(''),
      quote: Value('A better you, One day at a time.'),
      points: Value(320),
    ),
  );

  // ── Tasks ────────────────────────────────────────────────────────────────
  await db.taskDao.insertTask(
    TasksCompanion(
      title: const Value('DBMS Assignment'),
      category: const Value('Study'),
      dueDate: Value(today),
      dueTime: const Value('23:59'),
      isCompleted: const Value(false),
      createdAt: Value(now),
    ),
  );
  await db.taskDao.insertTask(
    TasksCompanion(
      title: const Value('Read OS Chapter 7'),
      category: const Value('Study'),
      dueDate: Value(today),
      dueTime: const Value('18:00'),
      isCompleted: const Value(true),
      completedAt: Value(now.subtract(const Duration(hours: 1))),
      createdAt: Value(now.subtract(const Duration(hours: 2))),
    ),
  );
  await db.taskDao.insertTask(
    TasksCompanion(
      title: const Value('Buy groceries'),
      category: const Value('Personal'),
      dueDate: Value(today.add(const Duration(days: 1))),
      isCompleted: const Value(false),
      createdAt: Value(now),
    ),
  );
  await db.taskDao.insertTask(
    TasksCompanion(
      title: const Value('Submit lab report'),
      category: const Value('Study'),
      dueDate: Value(today.add(const Duration(days: 2))),
      dueTime: const Value('17:00'),
      isCompleted: const Value(false),
      createdAt: Value(now),
    ),
  );
  await db.taskDao.insertTask(
    TasksCompanion(
      title: const Value('Workout'),
      category: const Value('Health'),
      dueDate: Value(today),
      dueTime: const Value('06:30'),
      isCompleted: const Value(false),
      createdAt: Value(now),
    ),
  );

  // ── Money Transactions ───────────────────────────────────────────────────
  await db.moneyDao.insertTransaction(
    MoneyTransactionsCompanion(
      type: const Value('expense'),
      amount: const Value(12000),
      category: const Value('Food & Dining'),
      note: const Value('Lunch at canteen'),
      date: Value(today),
    ),
  );
  await db.moneyDao.insertTransaction(
    MoneyTransactionsCompanion(
      type: const Value('expense'),
      amount: const Value(35000),
      category: const Value('Shopping'),
      note: const Value('Stationery'),
      date: Value(today.subtract(const Duration(days: 1))),
    ),
  );
  await db.moneyDao.insertTransaction(
    MoneyTransactionsCompanion(
      type: const Value('expense'),
      amount: const Value(8000),
      category: const Value('Transport'),
      note: const Value('Auto to college'),
      date: Value(today.subtract(const Duration(days: 2))),
    ),
  );
  await db.moneyDao.insertTransaction(
    MoneyTransactionsCompanion(
      type: const Value('income'),
      amount: const Value(500000),
      category: const Value('Allowance'),
      note: const Value('Monthly pocket money'),
      date: Value(today.subtract(const Duration(days: 3))),
    ),
  );
  await db.moneyDao.insertTransaction(
    MoneyTransactionsCompanion(
      type: const Value('lent'),
      amount: const Value(20000),
      category: const Value('Lent'),
      note: const Value('Lent to Rahul'),
      date: Value(today.subtract(const Duration(days: 2))),
    ),
  );

  // ── Reminders ────────────────────────────────────────────────────────────
  await db.reminderDao.insertReminder(
    RemindersCompanion(
      title: const Value('Submit assignment'),
      dueAt: Value(DateTime(today.year, today.month, today.day, 23, 0)),
      isEnabled: const Value(true),
    ),
  );
  await db.reminderDao.insertReminder(
    RemindersCompanion(
      title: const Value('Morning workout'),
      dueAt: Value(DateTime(today.year, today.month, today.day + 1, 6, 30)),
      isEnabled: const Value(true),
    ),
  );
  await db.reminderDao.insertReminder(
    RemindersCompanion(
      title: const Value('College fee deadline'),
      dueAt: Value(today.add(const Duration(days: 5, hours: 17))),
      isEnabled: const Value(true),
    ),
  );

  print('[DIMI seed] Sample data inserted successfully.');
}
