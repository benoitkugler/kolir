import 'dart:convert';
import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/groupes.dart';
import 'package:kolir/logic/export/matieres.dart';
import 'package:kolir/logic/export/semaines.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/rotations.dart';
import 'package:kolir/logic/utils.dart';
import 'package:test/test.dart';

final sample = Colloscope({}, const [Groupe(1), Groupe(2), Groupe(3)]);

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

  test("Permutations", () {
    print(generatePermutations([1, 2, 3, 4]));
    print(generatePermutations([1, 2, 3, 4]).length);
  });
}
