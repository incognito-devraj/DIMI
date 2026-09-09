import 'package:drift/drift.dart';

/// A user note (lecture, personal, or idea).
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();

  /// "Lecture" | "Personal" | "Ideas"
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
