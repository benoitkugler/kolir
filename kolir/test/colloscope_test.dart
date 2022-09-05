import 'dart:convert';
import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/groupes.dart';
import 'package:kolir/logic/export/matieres.dart';
import 'package:kolir/logic/export/semaines.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';
import 'package:test/test.dart';

const l1 = [
  DateHeure(1, 3, 6, 0),
  DateHeure(1, 3, 13, 0),
  DateHeure(1, 3, 20, 0)
];
const l2 = [
  DateHeure(1, 3, 7, 0),
  DateHeure(1, 3, 14, 0),
  DateHeure(2, 3, 21, 0)
];

final sample = Colloscope({
  "G1": {
    Matiere.maths: l1,
    Matiere.esh: l1,
    Matiere.espagnol: l1,
    Matiere.allemand: l1,
    Matiere.anglais: l1,
    Matiere.philo: l1,
    Matiere.francais: l1,
  },
  "G2": {
    Matiere.maths: l2,
    Matiere.esh: l2,
    Matiere.espagnol: l2,
    Matiere.allemand: l2,
    Matiere.anglais: l2,
    Matiere.philo: l2,
    Matiere.francais: l2,
  },
  "G3": {
    Matiere.maths: l1,
    Matiere.allemand: l1,
  }
});

void main() {
  test("Colloscope JSON", () {
    final cl = sample;
    final json = jsonEncode(cl.toJson());
    final cl2 = Colloscope.fromJson(jsonDecode(json));
    expect(cl.parGroupe().length, equals(cl2.parGroupe().length));
    expect(cl.notes, equals(cl2.notes));
  });

  test("Par semaine", () {
    final parSemaine = sample.parSemaine();
    expect(parSemaine.length, equals(2));
  });

  test("Export matieres", () async {
    final html = matieresToHTML(sample);
    final path = await saveDocument(html, "matieres.html");
    print("Saved in $path");
  });

  test("Export groupes", () async {
    final html = groupesToHTML(sample);
    final path = await saveDocument(html, "groupes.html");
    print("Saved in $path");
  });

  test("Export semaines", () async {
    final html = semainesToHTML(sample, const [
      Color(0xFF90CAF9),
      Color(0xFFA5D6A7),
      Color(0xFFFFB74D),
      Color(0xFFFFF176),
      Color(0xFFF06292),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
    ]);
    final path = await saveDocument(html, "semaines.html");
    print("Saved in $path");
  });
}
