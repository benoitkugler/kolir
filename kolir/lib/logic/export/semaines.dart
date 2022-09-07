import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';

/// [semainesToHTML] imprime le programme de colle,
/// résumé sur un seul tableau.
String semainesToHTML(Colloscope col, List<Color> matieresColors) {
  final semaines = col.parSemaine();

  List<String> rows = [];
  for (var semaine in semaines) {
    final matieres = col.matieresList.values.map((mat) {
      final colles = semaine.item[mat.index] ?? [];
      final creneaux = colles.map((e) =>
          "<div class='chip matiere-${mat.index}'><b>${e.groupe?.name ?? ''}</b> ${e.date.formatDateHeure(dense: true)} - <i>${e.colleur}</i></div>");
      return "<td style='text-align: center'>${creneaux.join('')}</td>";
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
      col.matieresList.values.map((e) => "<th>${e.format(dense: true)}</th>");
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
