import 'package:drift/drift.dart';

/// Compatibility view model for the profile screen. Identity fields live in
/// local_accounts; editable profile fields live in profile_data.
class ProfileTableData {
  const ProfileTableData({required this.id, required this.name, required this.role, required this.email, required this.phone, required this.college, required this.semester, required this.photoPath, required this.points});
  final int id;
  final String name, role, email, phone, college, semester;
  final String? photoPath;
  final int points;
}

class ProfileTableCompanion {
  const ProfileTableCompanion({this.id = const Value(1), this.name = const Value.absent(), this.role = const Value.absent(), this.email = const Value.absent(), this.phone = const Value.absent(), this.college = const Value.absent(), this.semester = const Value.absent(), this.photoPath = const Value.absent(), this.quote = const Value.absent(), this.points = const Value.absent()});
  final Value<int> id;
  final Value<String> name, role, email, phone, college, semester;
  final Value<String?> photoPath, quote;
  final Value<int> points;
}
