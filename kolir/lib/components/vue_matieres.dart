import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';

import '../logic/utils.dart';

class VueMatiereW extends StatelessWidget {
  final MatiereProvider matieresList;
  final CreneauHoraireProvider horaires;

  final Map<MatiereID, VueMatiere> byMatieres;

  final void Function(MatiereID mat, List<DateHeure> hours, List<int> semaines,
      String colleur) onAdd;
  final void Function(MatiereID mat, int creneauIndex) onDeleteCreneau;
  final void Function(MatiereID mat, int semaine) onDeleteSemaine;
  final void Function(MatiereID mat, int creneauIndex, String colleur)
      onEditColleur;
  final void Function(MatiereID mat, int nombre, int? periode)
      onRepeteMotifCourant;

  const VueMatiereW(this.matieresList, this.horaires, this.byMatieres,
      {required this.onAdd,
      required this.onDeleteCreneau,
      required this.onDeleteSemaine,
      required this.onEditColleur,
      required this.onRepeteMotifCourant,
      super.key});

  @override
  Widget build(BuildContext context) {
    final entries = byMatieres.entries.toList();
    return VueSkeleton(
      mode: ModeView.matieres,
      actions: const [],
      child: Expanded(
          child: ListView(
        children: entries
            .map((e) => _MatiereW(
                  horaires,
                  matieresList.values[e.key],
                  e.value,
                  (h, s, c) => onAdd(e.key, h, s, c),
                  (index) => onDeleteCreneau(e.key, index),
                  (index) => onDeleteSemaine(e.key, index),
                  (index, colleur) => onEditColleur(e.key, index, colleur),
                  (nombre, periode) =>
                      onRepeteMotifCourant(e.key, nombre, periode),
                ))
            .toList(),
      )),
    );
  }
}

class _DuplicateDialog extends StatefulWidget {
  final void Function(int, int?) onValid;
  const _DuplicateDialog(this.onValid, {super.key});

  @override
  State<_DuplicateDialog> createState() => __DuplicateDialogState();
}

class __DuplicateDialogState extends State<_DuplicateDialog> {
  var repeatcontroller = TextEditingController();
  var periodeController = TextEditingController();

  int? get nbRepeat => int.tryParse(repeatcontroller.text);
  int? get periode => int.tryParse(periodeController.text);

  @override
  void initState() {
    repeatcontroller.addListener(() => setState(() {}));
    periodeController.addListener(() => setState(() {}));
    super.initState();
  }

  bool get isInputValid =>
      nbRepeat != null && (periodeController.text.isEmpty || periode != null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text("Répéter le motif"),
        actions: [
          ElevatedButton(
              onPressed: nbRepeat == null
                  ? null
                  : () => widget.onValid(nbRepeat!, periode),
              child: const Text("Valider"))
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: repeatcontroller,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nombre de répétitions",
                contentPadding: EdgeInsets.only(bottom: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: periodeController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Ajuster la période (optionel)",
                contentPadding: EdgeInsets.only(bottom: 10),
              ),
            ),
          ],
        ));
  }
}

class _MatiereW extends StatelessWidget {
  final CreneauHoraireProvider horaires;

  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(List<DateHeure> hours, List<int> semaines, String colleur)
      onAdd;
  final void Function(int creneauIndex) onDelete;
  final void Function(int semaine) onDeleteSemaine;
  final void Function(int creneauIndex, String colleur) onEditColleur;
  final void Function(int nombre, int? periode) onRepeteMotifCourant;

  const _MatiereW(
      this.horaires,
      this.matiere,
      this.semaines,
      this.onAdd,
      this.onDelete,
      this.onDeleteSemaine,
      this.onEditColleur,
      this.onRepeteMotifCourant,
      {super.key});

  void showAddCreneaux(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AssistantCreneaux(
            horaires,
            (creneaux, semaines, colleur) {
              Navigator.of(context).pop();
              onAdd(creneaux, semaines, colleur);
            },
          );
        });
  }

  void showDuplicate(BuildContext context) async {
    int nbRepeat = 0;
    int? periode;
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => _DuplicateDialog((r, p) {
              nbRepeat = r;
              periode = p;
              Navigator.of(context).pop(true);
            }));
    if (ok != null && ok) {
      onRepeteMotifCourant(nbRepeat, periode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: Text(matiere.format(),
                    style: const TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: SemaineList(
                    semaines
                        .map((semaine) => SemaineTo(
                            semaine.semaine,
                            Row(
                              children: [
                                Wrap(
                                  children: semaine.item
                                      .map((e) => ColleW(
                                            e.toColle(matiere),
                                            showMatiere: false,
                                            onDelete: () => onDelete(e.index),
                                            onEditColleur: (colleur) =>
                                                onEditColleur(e.index, colleur),
                                          ))
                                      .toList(),
                                ),
                                const Spacer(),
                                IconButton(
                                  splashRadius: 18,
                                  color: Colors.red,
                                  tooltip:
                                      "Supprimer les créneaux de la semaine ${semaine.semaine}",
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      onDeleteSemaine(semaine.semaine),
                                ),
                                const SizedBox(width: 20)
                              ],
                            )))
                        .toList(),
                    "Aucun créneau n'est encore défini."),
              ),
              Column(
                children: [
                  ElevatedButton(
                      onPressed: () => showAddCreneaux(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text("Ajouter des créneaux")),
                  const SizedBox(height: 10),
                  Tooltip(
                      message: "Répéter la structure courante n fois",
                      child: ElevatedButton(
                          onPressed: () => showDuplicate(context),
                          child: const Text("Répéter...")))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
