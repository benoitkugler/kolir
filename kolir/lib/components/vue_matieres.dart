import 'package:flutter/material.dart';
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
  final void Function(MatiereID mat, int creneauIndex) onDelete;
  final void Function(MatiereID mat, int creneauIndex, String colleur)
      onEditColleur;

  const VueMatiereW(this.matieresList, this.horaires, this.byMatieres,
      {required this.onAdd,
      required this.onDelete,
      required this.onEditColleur,
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
                  (index) => onDelete(e.key, index),
                  (index, colleur) => onEditColleur(e.key, index, colleur),
                ))
            .toList(),
      )),
    );
  }
}

class _MatiereW extends StatelessWidget {
  final CreneauHoraireProvider horaires;

  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(List<DateHeure> hours, List<int> semaines, String colleur)
      onAdd;
  final void Function(int creneauIndex) onDelete;
  final void Function(int creneauIndex, String colleur) onEditColleur;

  const _MatiereW(this.horaires, this.matiere, this.semaines, this.onAdd,
      this.onDelete, this.onEditColleur,
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
                        .map((creneaux) => SemaineTo(
                            creneaux.semaine,
                            Wrap(
                              children: creneaux.item
                                  .map((e) => ColleW(
                                        e.toColle(matiere),
                                        showMatiere: false,
                                        onDelete: () => onDelete(e.index),
                                        onEditColleur: (colleur) =>
                                            onEditColleur(e.index, colleur),
                                      ))
                                  .toList(),
                            )))
                        .toList(),
                    "Aucun créneau n'est encore défini."),
              ),
              ElevatedButton(
                  onPressed: () => showAddCreneaux(context),
                  child: const Text("Ajouter des créneaux"))
            ],
          ),
        ),
      ),
    );
  }
}
