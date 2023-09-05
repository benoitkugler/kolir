import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [matieresToHTML] imprime le programme de colle,
/// une page par matière
String matieresToHTML(Colloscope col) {
  final matieres = col.parMatiere();

  final List<String> pages = [];
  for (var item in matieres.entries) {
    final matiere = col.matieresList.values[item.key];

    final rows = item.value.map((semaine) {
      final creneaux = semaine.item.map((e) {
        final time = col.semaines.dateFor(e.date.semaine, e.date.weekday);
        return "<div class='chip'><i>${e.colleur}</i><br/><b>${e.groupe?.name ?? ''}</b> ${formatDateTime(time, e.date)}</div>";
      });
      return """
      <tr>
        <td>S ${semaine.semaine}</td>
        <td>${creneaux.join("")}</td>
      </tr>
      """;
    });

    final page = """
    <h1>${matiere.format()}</h1>

    <table>
      <tr>
        <th>Semaine</th>
        <th>Groupes</th>
      </tr>
      ${rows.join("\n")}
    </table>
    """;
    pages.add(page);
  }
  return fillTemplate(pages);
}
