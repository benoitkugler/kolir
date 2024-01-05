import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/utils.dart';

/// [matieresToHTML] imprime le programme de colle,
/// une page par matière
String matieresToHTML(Colloscope col) {
  final matieres = col.parMatiere();

  final List<String> pages = [];
  for (var item in matieres.entries) {
    final creneaux = item.value;
    final matiere = col.matieresList.values[item.key];

    final colleursSet = <String>{};
    for (var semaine in creneaux) {
      colleursSet.addAll(semaine.item.map((e) => e.colleur));
    }
    final colleurs = colleursSet.toList();
    colleurs.sort();

    final rows = creneaux.map((semaine) {
      final byColleur = <String, List<PopulatedCreneau>>{};
      for (var creneau in semaine.item) {
        final l = byColleur.putIfAbsent(creneau.colleur, () => []);
        l.add(creneau);
      }
      final cells = colleurs.map((colleur) {
        final creneaux = (byColleur[colleur] ?? []).map((e) {
          final time = col.semaines.dateFor(e.date.semaine, e.date.weekday);
          return "<div class='chip'><b>${e.groupe?.name ?? ''}</b><br/>${formatDateTime(time, e.date)}</div>";
        });
        return "<td>${creneaux.join('')}</td>";
      });
      return """
      <tr>
        <td>S ${semaine.semaine}</td>
        ${cells.join("\n")}
      </tr>
      """;
    });

    final colleurHeaders = colleurs.map((e) => "<th>$e</th>").join("\n");
    final page = """
    <h1>${matiere.format()}</h1>

    <table>
      <tr>
        <th>Semaine</th>
        $colleurHeaders
      </tr>
      ${rows.join("\n")}
    </table>
    """;
    pages.add(page);
  }
  return fillTemplate(pages);
}
