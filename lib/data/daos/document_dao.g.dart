// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentMetaTable get documentMeta => attachedDatabase.documentMeta;
  DocumentDaoManager get managers => DocumentDaoManager(this);
}

class DocumentDaoManager {
  final _$DocumentDaoMixin _db;
  DocumentDaoManager(this._db);
  $$DocumentMetaTableTableManager get documentMeta =>
      $$DocumentMetaTableTableManager(_db.attachedDatabase, _db.documentMeta);
}
