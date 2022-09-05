import 'package:kolir/logic/colloscope.dart';

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

String formatWeekday(int weekday) {
  return _days[weekday];
}

String _formatHeure(int hour, int minute) {
  return "${hour}h${minute.toString().padLeft(2, "0")}";
}

String formatMatiere(Matiere mat, {dense = false}) {
  switch (mat) {
    case Matiere.maths:
      if (dense) {
        return "Maths.";
      }
      return "Mathématiques";
    case Matiere.esh:
      if (dense) {
        return "ESH";
      }
      return "Economie, Sociologie, Histoire";
    case Matiere.anglais:
      return "Anglais";
    case Matiere.allemand:
      if (dense) {
        return "Allem.";
      }
      return "Allemand";
    case Matiere.espagnol:
      if (dense) {
        return "Espa.";
      }
      return "Espagnol";
    case Matiere.francais:
      if (dense) {
        return "Fran.";
      }
      return "Francais";
    case Matiere.philo:
      if (dense) {
        return "Philo.";
      }
      return "Philosophie";
  }
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
}
