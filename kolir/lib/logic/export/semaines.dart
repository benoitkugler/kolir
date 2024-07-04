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
    final matieres = col.matieresList.list.map((mat) {
      final colles = semaine.item[mat.id] ?? [];
      final creneaux = colles.map((e) {
        final time = col.semaines.dateFor(e.date.semaine, e.date.weekday);
        return "<div class='chip matiere-${mat.id}'><b>${e.groupe?.name ?? ''}</b> ${formatDateTime(time, e.date)} <i>${e.colleur}</i></div>";
      });
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
      col.matieresList.list.map((e) => "<th>${e.format(dense: true)}</th>");
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
