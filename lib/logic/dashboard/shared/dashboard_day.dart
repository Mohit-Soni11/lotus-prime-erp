class DashboardDay {
  final DateTime start;
  final DateTime end;

  DashboardDay(DateTime date)
      : start = DateTime(date.year, date.month, date.day),
        end = DateTime(date.year, date.month, date.day + 1);
}
