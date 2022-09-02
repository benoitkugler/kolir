import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

typedef Creneaux = Map<Matiere, VueMatiere>;

class VueGroupeW extends StatelessWidget {
  final Map<GroupeID, VueGroupe> groupes;

  final Creneaux creneaux;

  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;

  final Creneaux Function(Matiere mat, GroupeID origin, PopulatedCreneau dst)
      onAttributeCreneau;

  const VueGroupeW(this.groupes, this.creneaux,
      {required this.onAddGroupe,
      required this.onRemoveGroupe,
      required this.onAttributeCreneau,
      super.key});

  void showEditPassages(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => _GroupesCreneaux(
              groupes.keys.toList(),
              creneaux,
              onAttributeCreneau,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final entries = groupes.entries.toList();
    return ListHeader(
      title: "Vue par groupes",
      actions: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: onAddGroupe,
            child: const Text("Ajouter un groupe")),
        const SizedBox(width: 10),
        ElevatedButton(
            onPressed: () => showEditPassages(context),
            child: const Text("Modifier les passages"))
      ],
      child: Expanded(
        child: ListView(
          children: List<Widget>.generate(
              groupes.keys.length,
              (index) => _GroupeW(entries[index].key, entries[index].value,
                  () => onRemoveGroupe(entries[index].key))),
        ),
      ),
    );
  }
}

class _GroupeW extends StatelessWidget {
  final GroupeID groupe;
  final VueGroupe semaines;

  final void Function() onRemove;
  const _GroupeW(this.groupe, this.semaines, this.onRemove, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: deleteIcon,
                splashRadius: 20,
                color: Colors.red,
              ),
              Text(
                "$groupe :",
                style: const TextStyle(fontSize: 18),
              ),
              Expanded(
                child: SemaineList(
                    1,
                    semaines
                        .map((colles) =>
                            // pour un groupe et une semaine
                            Wrap(
                                children:
                                    colles.map((c) => ColleW(c)).toList()))
                        .toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// permet de modifier les heures d'un groupe,
// en choissant parmi les créneaux définis
class _GroupesCreneaux extends StatefulWidget {
  final List<GroupeID> groupes;
  final Map<Matiere, VueMatiere> creneaux;

  final Creneaux Function(Matiere mat, GroupeID origin, PopulatedCreneau dst)
      onAttributeCreneau;

  const _GroupesCreneaux(this.groupes, this.creneaux, this.onAttributeCreneau,
      {super.key});

  @override
  State<_GroupesCreneaux> createState() => _GroupesCreneauxState();
}

class _GroupesCreneauxState extends State<_GroupesCreneaux> {
  Matiere? matiere;
  Creneaux _updatedCreneaux = {};

  @override
  void initState() {
    _updatedCreneaux = widget.creneaux;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _GroupesCreneaux oldWidget) {
    _updatedCreneaux = widget.creneaux;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget body =
        const Center(child: Text("Veuillez sélectionner une matière"));
    if (matiere != null) {
      body = _MatiereCreneaux(
        matiere!,
        widget.groupes,
        _updatedCreneaux[matiere!] ?? [],
        (origin, dst) => setState(() {
          _updatedCreneaux = widget.onAttributeCreneau(matiere!, origin, dst);
        }),
      );
    }
    return Dialog(
      child: Card(
        child: Column(
          children: [
            DropdownButton(
                hint: const Text("Choisir la matière..."),
                items: Matiere.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(formatMatiere(e)),
                        ))
                    .toList(),
                value: matiere,
                onChanged: (mat) {
                  if (mat == null) {
                    return;
                  }
                  setState(() {
                    matiere = mat;
                  });
                }),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _MatiereCreneaux extends StatelessWidget {
  final Matiere matiere;
  final List<GroupeID> groupes;
  final VueMatiere creneaux;

  final void Function(GroupeID origin, PopulatedCreneau dst) onAttributeCreneau;

  const _MatiereCreneaux(
      this.matiere, this.groupes, this.creneaux, this.onAttributeCreneau,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: ListView(
                shrinkWrap: true,
                children: groupes.map((e) => _DraggableGroup(e)).toList())),
        Expanded(
          flex: 5,
          child: _MatiereW(matiere, creneaux, onAttributeCreneau),
        ),
      ],
    );
  }
}

class _DraggableGroup extends StatelessWidget {
  final GroupeID group;
  const _DraggableGroup(this.group, {super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable(
        data: group,
        feedback: Card(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Text(group),
          ),
        ),
        child: Card(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Text(group),
          ),
        ));
  }
}

class _MatiereW extends StatelessWidget {
  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(GroupeID origin, PopulatedCreneau dst) onAttributeCreneau;

  const _MatiereW(this.matiere, this.semaines, this.onAttributeCreneau,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SemaineList(
            1,
            semaines
                .map((creneaux) => Wrap(
                      children: creneaux
                          .map(
                            (e) => _Creneau(
                                Colle(e.date, matiere),
                                e.groupeID == NoGroup ? null : e.groupeID,
                                (origin) => onAttributeCreneau(origin, e)),
                          )
                          .toList(),
                    ))
                .toList()),
      ),
    );
  }
}

class _Creneau extends StatelessWidget {
  final Colle colle;
  final GroupeID? group;

  final void Function(GroupeID origin) onAttributeCreneau;

  // final void Function()? onDelete;

  const _Creneau(this.colle, this.group, this.onAttributeCreneau, {super.key});

  @override
  Widget build(BuildContext context) {
    final time = formatDateHeure(colle.date);
    final text = group == null ? time : "$time : $group";
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: DragTarget<GroupeID>(
        builder: (context, candidateData, rejectedData) {
          return Container(
              decoration: BoxDecoration(
                color: colle.matiere.color,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.black
                        : Colors.transparent),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(text));
        },
        onAccept: onAttributeCreneau,
      ),
    );
  }
}
