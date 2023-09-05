import 'dart:ui';

import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [creneauxToHTML] imprime les créneaux, accumulés sur une semaine
String creneauxToHTML(Colloscope col, List<Color> matieresColors) {
  final creneaux = col.creneaux();

  final entries = creneaux.entries.toList();
  entries.sort((a, b) => a.key - b.key);

  final days = entries.map((e) => formatWeekday(e.key, dense: false));
  final header = "<tr>${days.map((e) => '<th>$e</th>').join()}</tr>";
  final cells = entries.map((ls) => ls.value.map((l) {
        final row = l
            .map((colle) =>
                "<div class='chip matiere-${colle.matiere.index}'>${colle.date.formatDateHeure()} - <i>${colle.colleur}</i><br/><b>${colle.salle}</b></div>")
            .join("\n");
        return "<div style='margin: 10px'>$row</div>";
      }).join("\n"));

  final row = "<tr>${cells.map((e) => '<td>$e</td>').join()}</tr>";

  final notes = col.notes.isEmpty
      ? ""
      : """
    <h3>Notes</h3>
    <p>${col.notes.replaceAll("\n", "<br/>")}</p>
  """;

  final page = """
    <h1>Salles de colle</h1>

    <table>
      $header
      $row
    </table>


    $notes
    """;

  final style = cssMatieresColorDefinition(
      matieresColors.map((c) => c.withOpacity(0.5)).toList());

  return fillTemplate([page], additionalStyle: style);
}
