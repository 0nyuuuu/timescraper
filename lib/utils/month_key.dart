String monthKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  return '$y-$m';
}

List<DateTime> monthsBetween(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month);
  final e = DateTime(end.year, end.month);

  final out = <DateTime>[];
  var cur = s;
  while (!cur.isAfter(e)) {
    out.add(cur);
    cur = DateTime(cur.year, cur.month + 1);
  }
  return out;
}
