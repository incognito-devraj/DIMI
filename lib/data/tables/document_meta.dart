import 'package:drift/drift.dart';

/// Metadata for a locally stored document (PDF, image, etc.).
/// The actual file is copied into app storage; only the path is stored here.
class DocumentMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();

  /// "pdf" | "image" | "doc" | "other"
  TextColumn get fileType => text()();

  /// Absolute path inside the app's documents directory.
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get addedAt => dateTime()();
}
