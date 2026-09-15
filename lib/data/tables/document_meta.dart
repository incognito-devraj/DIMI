import 'package:drift/drift.dart';

class DocumentMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  TextColumn get fileType => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get addedAt => dateTime()();
}
