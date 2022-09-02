import 'package:kolir/logic/colloscope.dart';

const _days = [
  "",
  "Lundi",
  "Mardi",
  "Mercredi",
  "Jeudi",
  "Vendredi",
  "Samedi",
  "Dimanche",
];

String formatWeekday(int weekday) {
  return _days[weekday];
}

String formatHeure(DateTime dt) {
  return "${dt.hour}h${dt.minute.toString().padLeft(2, "0")}";
}

String formatDateHeure(DateTime dt) {
  return "${formatWeekday(dt.weekday)} à ${formatHeure(dt)}";
}

String formatMatiere(Matiere mat) {
  switch (mat) {
    case Matiere.maths:
      return "Maths";
    case Matiere.esh:
      return "ESH";
    case Matiere.anglais:
      return "Anglais";
    case Matiere.allemand:
      return "Allemand";
    case Matiere.espagnol:
      return "Espagnol";
    case Matiere.francais:
      return "Francais";
    case Matiere.philo:
      return "Philo.";
  }
}
