import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

class VueSemaineW extends StatelessWidget {
  final int creneauxVaccants;
  final List<VueSemaine> semaines;

  const VueSemaineW(this.creneauxVaccants, this.semaines, {super.key});

  @override
  Widget build(BuildContext context) {
    final plural = creneauxVaccants > 1;
    return VueSkeleton(
        mode: ModeView.semaines,
        actions: [
          Card(
            color: creneauxVaccants > 0
                ? Colors.orange.shade400
                : Colors.greenAccent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(creneauxVaccants > 0
                  ? "$creneauxVaccants créneau${plural ? 'x' : ''} vaccant${plural ? 's' : ''}"
                  : "Tous les créneaux sont attribués."),
            ),
          )
        ],
        child: Expanded(
          child: SingleChildScrollView(
            child: SemaineList(
              1,
              semaines.map((e) => _SemaineBody(e)).toList(),
            ),
          ),
        ));
  }
}

class _SemaineBody extends StatelessWidget {
  final VueSemaine semaine;
  const _SemaineBody(this.semaine, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: Matiere.values
            .map((matiere) => Column(
                children: (semaine[matiere] ?? [])
                    .map((creneau) => _Group(matiere, creneau))
                    .toList()))
            .toList(),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final Matiere matiere;
  final PopulatedCreneau creneau;

  const _Group(this.matiere, this.creneau, {super.key});

  @override
  Widget build(BuildContext context) {
    final group =
        creneau.groupeID == NoGroup ? "<Aucun groupe>" : creneau.groupeID;
    return Tooltip(
      message: formatMatiere(matiere),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: matiere.color),
          child: Text("${formatDateHeure(creneau.date)} $group"),
        ),
      ),
    );
  }
}
