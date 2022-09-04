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

String formatHeure(DateTime dt) {
  return _formatHeure(dt.hour, dt.minute);
}

String formatDateHeure(DateTime dt, {dense = false}) {
  if (dense) {
    return "${formatWeekday(dt.weekday)} ${formatHeure(dt)}";
  }
  return "${formatWeekday(dt.weekday)} à ${formatHeure(dt)}";
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

DateTime emptyDate() {
  return DateTime.fromMillisecondsSinceEpoch(0);
}

bool isEmptyDate(DateTime dt) {
  return dt.millisecondsSinceEpoch == 0;
}

class DateHeure {
  /// comme affichée à l'écran
  final int semaine;
  final int weekday;
  final int heure;
  final int minute;
  const DateHeure(this.semaine, this.weekday, this.heure, this.minute);

  @override
  bool operator ==(Object other) =>
      other is DateHeure &&
      other.runtimeType == runtimeType &&
      other.semaine == semaine &&
      other.weekday == weekday &&
      other.heure == heure &&
      other.minute == minute;

  @override
  int get hashCode =>
      semaine.hashCode + weekday.hashCode + heure.hashCode + minute.hashCode;

  String formatDateHeure({dense = false}) {
    if (dense) {
      return "${formatWeekday(weekday)} ${_formatHeure(heure, minute)}";
    }
    return "${formatWeekday(weekday)} à ${_formatHeure(heure, minute)}";
  }
}
