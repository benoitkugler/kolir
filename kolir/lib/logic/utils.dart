const _days = [
  "",
  "Lun",
  "Mar",
  "Mer",
  "Jeu",
  "Ven",
  "Sam",
  "Dim",
];

const _daysLong = [
  "",
  "Lundi",
  "Mardi",
  "Mercredi",
  "Jeudi",
  "Vendredi",
  "Samedi",
  "Dimanche",
];

String formatWeekday(int weekday, {dense = true}) {
  if (dense) {
    return _days[weekday];
  }
  return _daysLong[weekday];
}

String _formatHeure(int hour, int minute) {
  return "${hour}h${minute.toString().padLeft(2, "0")}";
}

DateHeure emptyDate() {
  return const DateHeure(-1, 0, 0, 0);
}

bool isEmptyDate(DateHeure dt) {
  return dt == const DateHeure(-1, 0, 0, 0);
}

/// DateHeure est une version simplifiée de DateTime,
/// qui se réfère aux semaines du colloscope.
class DateHeure implements Comparable<DateHeure> {
  /// comme affichée à l'écran
  final int semaine;
  final int weekday;
  final int hour;
  final int minute;
  const DateHeure(this.semaine, this.weekday, this.hour, this.minute);

  @override
  bool operator ==(Object other) =>
      other is DateHeure &&
      other.runtimeType == runtimeType &&
      other.semaine == semaine &&
      other.weekday == weekday &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode =>
      semaine.hashCode + weekday.hashCode + hour.hashCode + minute.hashCode;

  @override
  int compareTo(DateHeure other) {
    final diffSemaine = semaine - other.semaine;
    if (diffSemaine != 0) {
      return diffSemaine;
    }
    final diffDay = weekday - other.weekday;
    if (diffDay != 0) {
      return diffDay;
    }
    final diffHour = hour - other.hour;
    if (diffHour != 0) {
      return diffHour;
    }
    return minute - other.minute;
  }

  Map<String, dynamic> toJson() {
    return {
      "semaine": semaine,
      "weekday": weekday,
      "hour": hour,
      "minute": minute,
    };
  }

  factory DateHeure.fromJson(Map<String, dynamic> json) {
    return DateHeure(
        json["semaine"], json["weekday"], json["hour"], json["minute"]);
  }

  /// ignore week and day
  String formatHeure() {
    return _formatHeure(hour, minute);
  }

  /// ignore week
  String formatDateHeure({dense = false}) {
    if (dense) {
      return "${formatWeekday(weekday)} ${_formatHeure(hour, minute)}";
    }
    return "${formatWeekday(weekday)} à ${_formatHeure(hour, minute)}";
  }

  /// [toDateTime] returns the [DateTime] with base year 2000
  /// beware that it does not preserve weekdays
  DateTime toDateTime() {
    return DateTime(2000).add(
        Duration(days: 7 * semaine + weekday, hours: hour, minutes: minute));
  }
}
