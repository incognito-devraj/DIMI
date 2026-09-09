// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_dao.dart';

// ignore_for_file: type=lint
mixin _$StudyDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudySessionsTable get studySessions => attachedDatabase.studySessions;
  $CoursesTable get courses => attachedDatabase.courses;
  StudyDaoManager get managers => StudyDaoManager(this);
}

class StudyDaoManager {
  final _$StudyDaoMixin _db;
  StudyDaoManager(this._db);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db.attachedDatabase, _db.studySessions);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db.attachedDatabase, _db.courses);
}
