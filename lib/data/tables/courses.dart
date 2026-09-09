import 'package:drift/drift.dart';

/// A study course with a denormalized running total of logged minutes.
/// [totalLoggedMinutes] is updated by [StudyDao] each time a session is saved.
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get totalLoggedMinutes =>
      integer().withDefault(const Constant(0))();
}
