import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [matieresToHTML] imprime le programme de colle,
/// une page par matière
String matieresToHTML(Colloscope col) {
  final matieres = col.parMatiere();

  final List<String> pages = [];
  for (var item in matieres.entries) {
    final matiere = item.key;

    final rows = List<String>.generate(item.value.length, (semaine) {
      final creneaux = item.value[semaine].map((e) =>
          "<div class='chip'><i>${e.groupeID}</i> ${formatDateHeure(e.date)}</div>");
      return """
      <tr>
        <td>Semaine ${col.premiereSemaine + semaine}</td>
        <td>${creneaux.join("")}</td>
      </tr>
      """;
    });

    final page = """
    <h1>${formatMatiere(matiere)}</h1>

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
