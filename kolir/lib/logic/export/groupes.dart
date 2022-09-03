import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [groupesToHTML] imprime le programme de colle,
/// une page par groupe
String groupesToHTML(Colloscope col) {
  final groupes = col.parGroupe();

  final List<String> pages = [];
  for (var item in groupes.entries) {
    final groupeID = item.key;

    final rows = List<String>.generate(item.value.length, (semaine) {
      final creneaux = item.value[semaine].map((e) =>
          "<div class='chip'>${formatMatiere(e.matiere, dense: true)} ${formatDateHeure(e.date)}</div>");
      return """
      <tr>
        <td>Semaine ${col.premiereSemaine + semaine}</td>
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
