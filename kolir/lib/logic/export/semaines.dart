import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [semainesToHTML] imprime le programme de colle,
/// résumé sur un seul tableau.
String semainesToHTML(Colloscope col, List<Color> matieresColors) {
  final semaines = col.parSemaine();

  List<String> rows = [];
  for (var semaine in semaines) {
    final matieres = Matiere.values.map((mat) {
      final colles = semaine.item[mat] ?? [];
      final creneaux = colles.map((e) =>
          "<div class='chip matiere-${mat.index}'><i>${e.groupe}</i> ${e.date.formatDateHeure(dense: true)}</div>");
      return "<td>${creneaux.join('')}</td>";
    });

    final row = """
      <tr>
        <td>S ${semaine.semaine}</td>
        ${matieres.join("\n")}
      </tr>
      """;
    rows.add(row);
  }

  final matiereHeaders =
      Matiere.values.map((e) => "<th>${formatMatiere(e, dense: true)}</th>");
  final page = """
    <h1>Colloscope</h1>

    <table>
      <tr>
        <th>Sem.</th>
        ${matiereHeaders.join("\n")}
      </tr>
      ${rows.join("\n")}
    </table>
    """;

  final style = cssMatieresColorDefinition(matieresColors);
  return fillTemplate([page], additionalStyle: style);
}
