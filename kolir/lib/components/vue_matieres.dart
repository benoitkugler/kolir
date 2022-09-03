import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';

import '../logic/utils.dart';

class VueMatiereW extends StatelessWidget {
  final Map<Matiere, VueMatiere> matieres;

  final void Function(Matiere mat, List<DateTime> hours, List<int> semaines)
      onAdd;
  final void Function(Matiere mat, DateTime creneau) onDelete;

  const VueMatiereW(this.matieres, this.onAdd, this.onDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    final entries = matieres.entries.toList();
    return VueSkeleton(
      mode: ModeView.matieres,
      actions: const [],
      child: Expanded(
          child: ListView(
        children: entries
            .map((e) => _MatiereW(
                e.key,
                e.value,
                (h, s) => onAdd(
                      e.key,
                      h,
                      s,
                    ),
                (dt) => onDelete(e.key, dt)))
            .toList(),
      )),
    );
  }
}

class _MatiereW extends StatelessWidget {
  final Matiere matiere;
  final VueMatiere semaines;
  final void Function(List<DateTime> hours, List<int> semaines) onAdd;
  final void Function(DateTime creneau) onDelete;

  const _MatiereW(this.matiere, this.semaines, this.onAdd, this.onDelete,
      {super.key});

  void showAddCreneaux(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return WeekCalendar(onAdd);
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
                child: Text(formatMatiere(matiere),
                    style: const TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: SemaineList(
                    1,
                    semaines
                        .map((creneaux) => Wrap(
                              children: creneaux
                                  .map((e) => ColleW(
                                        Colle(e.date, matiere),
                                        showMatiere: false,
                                        onDelete: () => onDelete(e.date),
                                      ))
                                  .toList(),
                            ))
                        .toList()),
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
