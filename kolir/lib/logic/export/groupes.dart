import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';

/// [groupesToHTML] imprime le programme de colle,
/// une page par groupe
String groupesToHTML(Colloscope col) {
  final groupes = col.parGroupe();

  final List<String> pages = [];
  for (var item in groupes.entries) {
    final groupeID = item.key;

    final rows = item.value.map((semaine) {
      final creneaux = semaine.item.map((cr) =>
          "<div class='chip'>${cr.matiere.format(dense: true)} ${cr.date.formatDateHeure()} - <i>${cr.colleur}</i></div>");
      return """
      <tr>
        <td>Semaine ${semaine.semaine}</td>
        <td>${creneaux.join("")}</td>
      </tr>
      """;
    });

    final page = """
    <h1>$groupeID</h1>

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
  return fillTemplate(pages);
}
