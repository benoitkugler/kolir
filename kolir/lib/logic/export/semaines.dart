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
          "<div class='chip matiere-${mat.index}'><b>${e.groupe?.name ?? ''}</b> ${e.date.formatDateHeure(dense: true)} <i>${e.colleur}</i></div>");
      return "<td style='text-align: center'><div class='avoid-page-break'>${creneaux.join('')}</div></td>";
    });

    final row = """
      <tr>
        <td><div class='avoid-page-break'>S ${semaine.semaine}</div></td>
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

  final style = cssMatieresColorDefinition(
      matieresColors.map((c) => c.withOpacity(0.8)).toList());
  const lowerSize = "body { font-size: 9pt}";
  return fillTemplate([page], additionalStyle: "$style \n $lowerSize");
}
