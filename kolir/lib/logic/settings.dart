import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kolir/logic/utils.dart';

class CreneauHoraireData {
  final int hour;
  final int minute;
  final int lengthInMinutes;
  const CreneauHoraireData(this.hour, this.minute, {this.lengthInMinutes = 60});

  Map<String, dynamic> toJson() {
    return {
      "hour": hour,
      "minute": minute,
      "lengthInMinutes": lengthInMinutes,
    };
  }

  factory CreneauHoraireData.fromJson(Map<String, dynamic> json) {
    return CreneauHoraireData(json["hour"], json["minute"],
        lengthInMinutes: json["lengthInMinutes"] ?? 60);
  }

  @override
  bool operator ==(Object other) =>
      other is CreneauHoraireData &&
      other.runtimeType == runtimeType &&
      other.hour == hour &&
      other.minute == minute &&
      other.lengthInMinutes == lengthInMinutes;

  @override
  int get hashCode =>
      hour.hashCode + minute.hashCode + lengthInMinutes.hashCode;
}

class CreneauHoraireProvider {
  final List<CreneauHoraireData> values;
  const CreneauHoraireProvider(this.values);

  List<dynamic> toJson() {
    return values.map((e) => e.toJson()).toList();
  }

  factory CreneauHoraireProvider.fromJson(dynamic json) {
    return CreneauHoraireProvider(
        (json as List).map((e) => CreneauHoraireData.fromJson(e)).toList());
  }

  CreneauHoraireProvider copy() {
    return CreneauHoraireProvider(values.map((e) => e).toList());
  }

  bool equals(CreneauHoraireProvider other) {
    return values.equals(other.values);
  }

  int get firstHour => values.first.hour;
  int get lastHour {
    final last = values.last;
    return (last.hour.toDouble() + (last.minute + last.lengthInMinutes) / 60)
        .ceil();
  }

  double get oneHourRatio => 1 / (lastHour - firstHour);
}

const defautHoraires = CreneauHoraireProvider([
  CreneauHoraireData(8, 15),
  CreneauHoraireData(9, 15),
  CreneauHoraireData(10, 20),
  CreneauHoraireData(11, 20),
  CreneauHoraireData(12, 25),
  CreneauHoraireData(13, 25),
  CreneauHoraireData(14, 25),
  CreneauHoraireData(15, 30),
  CreneauHoraireData(16, 30),
  CreneauHoraireData(17, 30),
  CreneauHoraireData(18, 30),
]);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

typedef MatiereID = int;

class Matiere {
  /// [index] est l'identifiant unique
  final MatiereID index;
  final String name;
  final String shortName;
  final Color color;

  /// [colleDuree] est la durée d'une colle, en minute
  final int colleDuree;
  const Matiere(this.index, this.name, this.shortName, this.color,
      {this.colleDuree = 55});

  String format({bool dense = false}) {
    return dense ? shortName : name;
  }

  Map<String, dynamic> toJson() {
    return {
      "index": index,
      "name": name,
      "shortName": shortName,
      "color": color.value,
      "colleDuree": colleDuree,
    };
  }

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      json["index"],
      json["name"],
      json["shortName"],
      Color(json["color"] as int),
      colleDuree: json["colleDuree"] ?? 55,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Matiere &&
      other.runtimeType == runtimeType &&
      other.index == index &&
      other.name == name &&
      other.shortName == shortName &&
      other.color.value == color.value &&
      other.colleDuree == colleDuree;

  @override
  int get hashCode =>
      index.hashCode +
      name.hashCode +
      shortName.hashCode +
      color.hashCode +
      colleDuree.hashCode;
}

class MatiereProvider {
  final List<Matiere> values;
  const MatiereProvider(this.values);

  List<dynamic> toJson() {
    return values.map((e) => e.toJson()).toList();
  }

  factory MatiereProvider.fromJson(dynamic json) {
    return MatiereProvider(
        (json as List).map((e) => Matiere.fromJson(e)).toList());
  }

  MatiereProvider copy() {
    return MatiereProvider(values.map((e) => e).toList());
  }

  bool equals(MatiereProvider other) {
    return values.equals(other.values);
  }
}

const MatiereID informatiqueID = 7;

const defautMatieres = MatiereProvider([
  Matiere(0, "Mathématiques", "Maths.", Color.fromRGBO(59, 76, 230, 1)),
  Matiere(1, "Economie, Sociologie, Histoire", "ESH",
      Color.fromARGB(255, 199, 25, 184),
      colleDuree: 80),
  Matiere(2, "Anglais", "Anglais", Color(0xFFFFB74D)),
  Matiere(3, "Allemand", "Allem.", Color(0xFFFFF176)),
  Matiere(4, "Espagnol", "Espa.", Color.fromARGB(255, 235, 107, 107)),
  Matiere(5, "Francais", "Fran.", Color.fromARGB(255, 90, 185, 103)),
  Matiere(6, "Philosophie", "Philo.", Color.fromARGB(255, 10, 235, 58)),
  Matiere(informatiqueID, "Informatique (TP)", "Info.",
      Color.fromRGBO(18, 203, 228, 1))
]);

final _defautFirstMonday = DateTime(2023, DateTime.september, 4);

/// [SemaineProvider] spécifie le jour du calendrier réel
/// associé à chaque lundi, permettant de prendre en compte
/// les vacances tout en raisonnant simplement en terme de semaines
/// effectivement travaillées.
/// Seule la première semaine doit être spécifiée, les suivantes
/// étant par défaut considérées comme consécutives.
/// Si elle ne l'est pas une date arbitraire est utilisée
class SemaineProvider {
  final Map<int, DateTime> mondays;
  const SemaineProvider(this.mondays);

  Map<String, dynamic> toJson() {
    return mondays.map((k, v) => MapEntry(k.toString(), v.toIso8601String()));
  }

  factory SemaineProvider.fromJson(dynamic json) {
    return SemaineProvider((json as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), DateTime.parse(v))));
  }

  SemaineProvider copy() {
    return SemaineProvider(mondays.map((k, v) => MapEntry(k, v)));
  }

  bool equals(SemaineProvider other) {
    return mapEquals(mondays, other.mondays);
  }

  /// [dateFor] renvoie le jour réel pour la semaine et le jour donnés
  DateTime dateFor(int semaine, int weekday) {
    // on considère uniquement les semaines avant celle demandée
    final providedWeeks = mondays.keys.where((s) => s <= semaine).toList();

    final int refWeek;
    final DateTime monday;
    if (providedWeeks.isEmpty) {
      // utilise un début arbitraire
      refWeek = 1;
      monday = _defautFirstMonday;
    } else {
      // trouve la semaine donnée juste avant la semaine demandée
      refWeek = providedWeeks.max;
      monday = mondays[refWeek]!;
    }

    // calcule le jour réel par rapport à la référence
    final offsetWeek = semaine - refWeek;
    final offsetDay = weekday - 1; // lundi
    return monday.add(Duration(days: offsetWeek * 7 + offsetDay));
  }
}

//
// Informatique
//

class InformatiqueParams {
  final List<DateHeure> creneauxCandidats; // la semaine est ignorée
  final int nbCreneauToAssign; // le nombre de créneaux à définir par semaine
  final int colleDuree; // durée d'une séance, en minutes (typiquement 55)
  const InformatiqueParams(
      this.creneauxCandidats, this.nbCreneauToAssign, this.colleDuree);
}
