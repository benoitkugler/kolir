import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';

/// [matieresToHTML] imprime le programme de colle,
/// une page par matière
String matieresToHTML(Colloscope col) {
  final matieres = col.parMatiere();

  final List<String> pages = [];
  for (var item in matieres.entries) {
    final matiere = col.matieresList.values[item.key];

    final rows = item.value.map((semaine) {
      final creneaux = semaine.item.map((e) =>
          "<div class='chip'><b>${e.groupe?.name ?? ''}</b> ${e.date.formatDateHeure()} - <i>${e.colleur}</i></div>");
      return """
      <tr>
        <td>Semaine ${semaine.semaine}</td>
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
