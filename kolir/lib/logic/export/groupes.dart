import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [groupesToHTML] imprime le programme de colle,
/// une page par groupe
String groupesToHTML(Colloscope col, List<Color> matieresColors) {
  final groupes = col.parGroupe();

  final List<String> pages = [];
  for (var item in groupes.entries) {
    final groupeID = item.key;

    final rows = item.value.map((semaine) {
      final creneaux = semaine.item.map((cr) {
        final time = col.semaines.dateFor(cr.date.semaine, cr.date.weekday);
        return "<div class='chip matiere-${cr.matiere.index}'>${cr.matiere.format(dense: true)}  - <i>${cr.colleur}</i><br/>${formatDateTime(time, cr.date)}</div>";
      });
      return """
      <tr>
        <td>S ${semaine.semaine}</td>
        <td>${creneaux.join("")}</td>
      </tr>
      """;
    });

    final page = """
    <h1>${col.groupes.singleWhere((gr) => gr.id == groupeID).name}</h1>

    <table>
      <tr>
        <th>Semaine</th>
        <th>Matières</th>
      </tr>
      ${rows.join("\n")}
    </table>
    """;
    pages.add(page);
  }

  final style = cssMatieresColorDefinition(
      matieresColors.map((c) => c.withOpacity(0.5)).toList());

  return fillTemplate(pages, additionalStyle: style);
}
