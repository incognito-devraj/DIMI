import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/document_meta.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [DocumentMeta])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<DocumentMetaData>> watchAllDocuments() => (select(
    documentMeta,
  )..orderBy([(d) => OrderingTerm.desc(d.addedAt)])).watch();

  Stream<List<DocumentMetaData>> watchByFileType(String fileType) =>
      (select(documentMeta)
            ..where((d) => d.fileType.equals(fileType))
            ..orderBy([(d) => OrderingTerm.desc(d.addedAt)]))
          .watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertDocument(DocumentMetaCompanion entry) =>
      into(documentMeta).insert(entry);

  Future<int> deleteDocument(int id) =>
      (delete(documentMeta)..where((d) => d.id.equals(id))).go();
}
