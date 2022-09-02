import 'dart:convert';

import 'package:kolir/logic/colloscope.dart';
import 'package:test/test.dart';

final l = [DateTime(2022, 9, 6), DateTime(2022, 9, 7), DateTime(2022, 9, 14)];

final sample = Colloscope({
  "G1": {
    Matiere.maths: l,
    Matiere.allemand: l,
  },
  "G2": {
    Matiere.maths: l,
    Matiere.allemand: l,
  },
  "G3": {
    Matiere.maths: l,
    Matiere.allemand: l,
  }
}, DateTime(2022, 9, 5));

void main() {
  test("Colloscope JSON", () {
    final cl = sample;
    final json = jsonEncode(cl.toJson());
    final cl2 = Colloscope.fromJson(jsonDecode(json));
    expect(cl.groupes.length, equals(cl2.groupes.length));
    expect(cl.debut, equals(cl2.debut));
  });

  test("Par semaine", () {
    final parSemaine = sample.parSemaine();
    expect(parSemaine.length, equals(2));
  });
}
