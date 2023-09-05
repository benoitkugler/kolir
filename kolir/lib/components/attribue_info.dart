import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';

class AttribueInfo extends StatefulWidget {
  final CreneauHoraireProvider creneauxHoraires;

  final List<AssignmentResult> Function(
          InformatiqueParams params, int semaineStart, int semaineEnd)
      onPreviewAttributeInformatique;
  final Function(List<AssigmentSuccess>, int semaineStart, String colleur)
      onAttribute;

  const AttribueInfo(this.creneauxHoraires, this.onPreviewAttributeInformatique,
      this.onAttribute,
      {super.key});

  @override
  State<AttribueInfo> createState() => _AttribueInfoState();
}

class _AttribueInfoState extends State<AttribueInfo> {
  final CreneauxController creneaux = CreneauxController(false);
  final premiereSemaine = TextEditingController(text: "1");
  final derniereSemaine = TextEditingController();
  final colleur = TextEditingController();

  List<AssignmentResult>? results;
  int? previewPremiereSemaine;

  @override
  void initState() {
    creneaux.addListener(() => setState(() {}));
    premiereSemaine.addListener(() => setState(() {}));
    derniereSemaine.addListener(() => setState(() {}));
    colleur.addListener(() => setState(() {}));
    super.initState();
  }

  bool get areParamsValid {
    final ps = int.tryParse(premiereSemaine.text);
    final ds = int.tryParse(derniereSemaine.text);
    return colleur.text.isNotEmpty &&
        creneaux.creneaux.length >= 2 &&
        ps != null &&
        ds != null &&
        ps <= ds;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          WeekCalendar(widget.creneauxHoraires, creneaux),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: "Première semaine"),
                    controller: premiereSemaine,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: "Dernière semaine"),
                    controller: derniereSemaine,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: "Colleur"),
                    controller: colleur,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: areParamsValid ? _preview : null,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  label: const Icon(Icons.chevron_right),
                  icon: const Text("Prévisualiser"),
                ),
              ],
            ),
          ),
          Expanded(
            child: results != null
                ? _PreviewAssign(results!, previewPremiereSemaine!,
                    (l, s) => widget.onAttribute(l, s, colleur.text))
                : const Center(
                    child: Text(
                    "En attente de prévisualisation...",
                  )),
          )
        ],
      ),
    );
  }

  void _preview() {
    final ps = int.parse(premiereSemaine.text);
    final out = widget.onPreviewAttributeInformatique(
        InformatiqueParams(creneaux.creneaux, 2, 55),
        ps,
        int.parse(derniereSemaine.text));
    setState(() {
      previewPremiereSemaine = ps;
      results = out;
    });
  }
}

class _PreviewAssign extends StatelessWidget {
  final List<AssignmentResult> results;
  final int premiereSemaine;

  final Function(List<AssigmentSuccess>, int premiereSemaine) onAttribute;

  const _PreviewAssign(this.results, this.premiereSemaine, this.onAttribute,
      {super.key});

  bool get areResultsValid =>
      results.every((element) => element is AssigmentSuccess);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(6),
      child: Column(
        children: [
          Text(
            "Prévisualisation des créneaux d'informatique",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                  children: List.generate(
                      results.length,
                      (index) =>
                          _ResultRow(results[index], premiereSemaine + index))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: areResultsValid
                    ? () => onAttribute(
                        results.map((e) => e as AssigmentSuccess).toList(),
                        premiereSemaine)
                    : null,
                child: const Text("Attribuer ces créneaux")),
          )
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final AssignmentResult result;
  final int semaine;
  const _ResultRow(this.result, this.semaine, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget body;
    final Color color;
    final String title;
    final r = result;
    if (r is AssigmentFailure) {
      color = Colors.orange.shade400;
      title = "Groupes non disponibles";
      body = Wrap(
          children: r.groupes
              .map((e) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(e.name),
                    ),
                  ))
              .toList());
    } else if (r is AssigmentSuccess) {
      color =
          r.hasWarning ? Colors.yellow.shade300 : Colors.lightGreen.shade400;
      title = "Créneaux assignés";
      body = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: r.groupesForCreneaux
              .map((e) => Card(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(e.key.formatDateHeure(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: e.value
                            .map((e) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(e.name),
                                  ),
                                ))
                            .toList(),
                      ),
                    ]),
                  )))
              .toList());
    } else {
      throw "exhaustive switch";
    }
    return ListTile(
      leading: SizedBox(width: 90, child: Text("Semaine $semaine")),
      title: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(title),
              ),
              body
            ],
          ),
        ),
      ),
    );
  }
}
