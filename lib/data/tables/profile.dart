import 'package:drift/drift.dart';

/// Single-row user profile. id is always 1.
class ProfileTable extends Table {
  @override
  String get tableName => 'profile';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get college => text()();
  TextColumn get semester => text()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get quote => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
