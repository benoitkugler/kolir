import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/creneaux.dart';
import 'package:kolir/logic/export/groupes.dart';
import 'package:kolir/logic/export/matieres.dart';
import 'package:kolir/logic/export/semaines.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/rotations.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';
import 'package:test/test.dart';

final sample = Colloscope({}, const [Groupe(1), Groupe(2), Groupe(3)]);
const colors = [
  Color(0xFF90CAF9),
  Color(0xFFA5D6A7),
  Color(0xFFFFB74D),
  Color(0xFFFFF176),
  Color(0xFFF06292),
  Color(0xFFBA68C8),
  Color(0xFF4DB6AC),
];
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
    expect(parSemaine.length, equals(0));
  });

  test("Export matieres", () async {
    final html = matieresToHTML(sample);
    final path = await saveDocument(html, "matieres.html");
    print("Saved in $path");
  });

  test("Export groupes", () async {
    final html = groupesToHTML(sample, colors);
    final path = await saveDocument(html, "groupes.html");
    print("Saved in $path");
  });

  test("Export semaines", () async {
    final html = semainesToHTML(sample, colors);
    final path = await saveDocument(html, "semaines.html");
    print("Saved in $path");
  });

  test("Export créneaux", () async {
    final html = creneauxToHTML(sample, colors);
    final path = await saveDocument(html, "creneaux.html");
    print("Saved in $path");
  });

  test("Permutations", () {
    print(generatePermutations([1, 2, 3, 4]));
    print(generatePermutations([1, 2, 3, 4]).length);
  });

  test("Combinaisons", () {
    final l = [
      [1, 2],
      [3],
      [4, 5]
    ];
    print(generateCombinaisons(l));
    expect(generateCombinaisons(l).length, equals(numberOfCombinaisons(l)));
  });

  test("Semaines", () {
    final sf = SemaineProvider({
      1: DateTime(2022, DateTime.november, 7),
      3: DateTime(2022, DateTime.december, 5),
    });
    expect(sf.dateFor(1, 1), equals(DateTime(2022, DateTime.november, 7)));
    expect(sf.dateFor(1, 3), equals(DateTime(2022, DateTime.november, 9)));
    expect(sf.dateFor(2, 3), equals(DateTime(2022, DateTime.november, 16)));
    expect(sf.dateFor(4, 1), equals(DateTime(2022, DateTime.december, 12)));

    final sf2 = SemaineProvider({
      1: DateTime(2022, 9, 19),
      6: DateTime(2022, DateTime.november, 7),
    });
    expect(sf2.dateFor(1, 1), equals(DateTime(2022, 9, 19)));
  });

  test("Horaires", () {
    final provider = CreneauHoraireProvider([
      CreneauHoraireData(8, 0),
      CreneauHoraireData(8, 50),
      CreneauHoraireData(9, 15)
    ]);

    provider.insert(CreneauHoraireData(8, 15));
    expect(
        listEquals(provider.values, [
          CreneauHoraireData(8, 0),
          CreneauHoraireData(8, 15),
          CreneauHoraireData(8, 50),
          CreneauHoraireData(9, 15)
        ]),
        true);

    provider.insert(CreneauHoraireData(7, 0));
    expect(
        listEquals(provider.values, [
          CreneauHoraireData(7, 0),
          CreneauHoraireData(8, 0),
          CreneauHoraireData(8, 15),
          CreneauHoraireData(8, 50),
          CreneauHoraireData(9, 15)
        ]),
        true);

    provider.insert(CreneauHoraireData(10, 50));
    expect(
        listEquals(provider.values, [
          CreneauHoraireData(7, 0),
          CreneauHoraireData(8, 0),
          CreneauHoraireData(8, 15),
          CreneauHoraireData(8, 50),
          CreneauHoraireData(9, 15),
          CreneauHoraireData(10, 50),
        ]),
        true);
  });

  test("Contraintes", () {
    final colloscope = Colloscope({}, const [
      Groupe(1, creneauxInterdits: [DateHeure(1, 1, 12, 15)]),
      Groupe(2, creneauxInterdits: [DateHeure(1, 2, 12, 15)]),
      Groupe(3)
    ], matieresList: defautMatieres);
    const MatiereID mat = 1;
    const GroupeID g1 = 1;
    const GroupeID g2 = 2;
    colloscope.addCreneaux(
        mat,
        [const DateHeure(1, 1, 12, 0), const DateHeure(1, 2, 13, 00)],
        [1],
        'Kugler');
    colloscope.toogleCreneau(g1, mat, 0);
    colloscope.toogleCreneau(g2, mat, 1);
    expect(colloscope.parGroupe()[g1]![0].item.length, 1);
    expect(colloscope.parGroupe()[g2]![0].item.length, 1);

    final warnings = colloscope.diagnostics();
    expect(warnings[g1], isNotNull);
    expect(warnings[g1]!.contraintes.length, 1);
    expect(warnings[g2], isNotNull);
    expect(warnings[g2]!.contraintes.length, 1);
  });
}
