// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_dao.dart';

// ignore_for_file: type=lint
mixin _$ClassDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClassSessionsTable get classSessions => attachedDatabase.classSessions;
  ClassDaoManager get managers => ClassDaoManager(this);
}

class ClassDaoManager {
  final _$ClassDaoMixin _db;
  ClassDaoManager(this._db);
  $$ClassSessionsTableTableManager get classSessions =>
      $$ClassSessionsTableTableManager(_db.attachedDatabase, _db.classSessions);
}
