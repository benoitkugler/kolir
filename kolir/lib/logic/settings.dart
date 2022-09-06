import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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
]);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

typedef MatiereID = int;

class Matiere {
  /// [index] is the id of the enum value.
  final MatiereID index;
  final String name;
  final String shortName;
  final Color color;
  const Matiere(this.index, this.name, this.shortName, this.color);

  String format({bool dense = false}) {
    return dense ? shortName : name;
  }

  Map<String, dynamic> toJson() {
    return {
      "index": index,
      "name": name,
      "shortName": shortName,
      "color": color.value,
    };
  }

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      json["index"],
      json["name"],
      json["shortName"],
      Color(json["color"] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Matiere &&
      other.runtimeType == runtimeType &&
      other.index == index &&
      other.name == name &&
      other.shortName == shortName &&
      other.color.value == color.value;

  @override
  int get hashCode =>
      index.hashCode + name.hashCode + shortName.hashCode + color.hashCode;
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

const defautMatieres = MatiereProvider([
  Matiere(0, "Mathématiques", "Maths.", Color(0xFF90CAF9)),
  Matiere(1, "Economie, Sociologie, Histoire", "ESH", Color(0xFFA5D6A7)),
  Matiere(2, "Anglais", "Anglais", Color(0xFFFFB74D)),
  Matiere(3, "Allemand", "Allem.", Color(0xFFFFF176)),
  Matiere(4, "Espagnol", "Espa.", Color(0xFFF06292)),
  Matiere(5, "Francais", "Fran.", Color(0xFFBA68C8)),
  Matiere(6, "Philosophie", "Philo.", Color(0xFF4DB6AC)),
]);
