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

String formatHeure(DateTime dt) {
  return "${dt.hour}h${dt.minute.toString().padLeft(2, "0")}";
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
