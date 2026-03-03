class WorkShift {
  final DateTime start;
  final DateTime end;

  WorkShift({required this.start, required this.end}) {
    if (!end.isAfter(start)) {
      throw ArgumentError('WorkShift end must be after start');
    }
  }

  bool overlaps(DateTime from, DateTime to) {
    // overlap tra [start,end) e [from,to)
    return start.isBefore(to) && end.isAfter(from);
  }
}
