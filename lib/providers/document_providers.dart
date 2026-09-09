import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daos/document_dao.dart';
import '../data/database.dart';
import 'database_provider.dart';

final documentDaoProvider = Provider<DocumentDao>((ref) {
  return ref.watch(databaseProvider).documentDao;
});

final allDocumentsProvider = StreamProvider<List<DocumentMetaData>>((ref) {
  return ref.watch(documentDaoProvider).watchAllDocuments();
});

final documentsByTypeProvider =
    StreamProvider.family<List<DocumentMetaData>, String>((ref, fileType) {
      return ref.watch(documentDaoProvider).watchByFileType(fileType);
    });
