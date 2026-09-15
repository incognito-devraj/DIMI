/// Capitalizes the first letter of every To-Do word while preserving the
/// remaining letters exactly as entered.
String formatTodoTitle(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return text
      .split(RegExp(r'\s+'))
      .map((word) => word.trim().isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

int countWords(String value) => value.trim().isEmpty
    ? 0
    : value.trim().split(RegExp(r'\s+')).length;
