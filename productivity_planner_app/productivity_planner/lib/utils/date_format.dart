// Shared helpers for displaying task due dates consistently across the app.
//
// Tasks store dueDate as a plain "YYYY-MM-DD" string (no time component), so
// these helpers work in whole-day granularity.

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// "2026-01-05" -> "Jan 5, 2026". Returns the raw string if it can't be parsed.
String formatDuePretty(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return '${_monthAbbr[d.month - 1]} ${d.day}, ${d.year}';
}

// Whole calendar days from today to the given date. Negative = overdue.
int daysUntil(String isoDate) {
  final due = DateTime.tryParse(isoDate);
  if (due == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  return dueDay.difference(today).inDays;
}

// Full label, e.g.:
//   "Due today (Jan 5, 2026)"
//   "Due tomorrow (Jan 6, 2026)"
//   "Due in 4 days (Jan 9, 2026)"
//   "Overdue by 2 days (Jan 3, 2026)"
String dueLabel(String isoDate) {
  final pretty = formatDuePretty(isoDate);
  final days = daysUntil(isoDate);
  if (days == 0) return 'Due today ($pretty)';
  if (days == 1) return 'Due tomorrow ($pretty)';
  if (days == -1) return 'Overdue by 1 day ($pretty)';
  if (days < 0) return 'Overdue by ${-days} days ($pretty)';
  return 'Due in $days days ($pretty)';
}