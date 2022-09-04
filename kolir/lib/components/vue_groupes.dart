import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

typedef Creneaux = Map<Matiere, VueMatiere>;

final colorWarning = Colors.deepOrange.shade200;

class VueGroupeW extends StatefulWidget {
  final int premiereSemaine;
  final Map<GroupeID, VueGroupe> groupes;
  final Map<GroupeID, Diagnostic> diagnostics;
  final Creneaux creneaux;

  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;

  final void Function(Matiere mat, PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(Matiere mat, int semaine) onClearCreneaux;
  final void Function(
          Matiere mat, GroupeID premierGroupe, DateTime premierCreneau)
      onAttribueRegulier;

  const VueGroupeW(
      this.premiereSemaine, this.groupes, this.diagnostics, this.creneaux,
      {required this.onAddGroupe,
      required this.onRemoveGroupe,
      required this.onAttributeCreneau,
      required this.onClearCreneaux,
      required this.onAttribueRegulier,
      super.key});

  @override
  State<VueGroupeW> createState() => _VueGroupeWState();
}

class _VueGroupeWState extends State<VueGroupeW> {
  bool isInEdit = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.groupes.entries.toList();
    final actions = [
      ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: isInEdit ? null : widget.onAddGroupe,
          icon: const Icon(IconData(0xe047, fontFamily: 'MaterialIcons')),
          label: const Text("Ajouter un groupe")),
      const SizedBox(width: 10),
      Tooltip(
        message: isInEdit
            ? "Quitter le mode Edition"
            : "Modifier les passages des groupes",
        child: ElevatedButton(
            onPressed: () => setState(() {
                  isInEdit = !isInEdit;
                }),
            child: Text(isInEdit ? "Terminer" : "Editer...")),
      )
    ];
    return VueSkeleton(
      mode: ModeView.groupes,
      actions: actions,
      child: Flexible(
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              isInEdit ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.diagnostics.isNotEmpty)
                _DiagnosticAlert(widget.diagnostics),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: List<Widget>.generate(
                      widget.groupes.keys.length,
                      (index) => _GroupeW(
                          entries[index].key,
                          entries[index].value,
                          widget.diagnostics[entries[index].key],
                          () => widget.onRemoveGroupe(entries[index].key))),
                ),
              ),
            ],
          ),
          secondChild: _GroupesCreneaux(
              widget.premiereSemaine,
              widget.groupes.keys.toList(),
              widget.creneaux,
              widget.onAttributeCreneau,
              widget.onClearCreneaux,
              widget.onAttribueRegulier),
        ),
      ),
    );
  }
}

class _DiagnosticAlert extends StatelessWidget {
  final Map<GroupeID, Diagnostic> diagnostics;

  const _DiagnosticAlert(this.diagnostics, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorWarning,
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text(
          "Certains groupes requierent une attention.",
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _GroupeW extends StatelessWidget {
  final GroupeID groupe;
  final VueGroupe semaines;
  final Diagnostic? diagnostic;

  final void Function() onRemove;
  const _GroupeW(this.groupe, this.semaines, this.diagnostic, this.onRemove,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                groupe,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
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
              if (diagnostic != null) _DiagnosticW(diagnostic!)
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticW extends StatelessWidget {
  final Diagnostic diagnostic;
  const _DiagnosticW(this.diagnostic, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorWarning,
      child: Padding(
          padding: const EdgeInsets.all(12.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (diagnostic.collisions.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text("Créneaux simultanés :"),
              ),
            ...diagnostic.collisions.entries
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                          "S${item.key.semaine} ${item.key.formatDateHeure()} (${item.value.map((m) => formatMatiere(m, dense: true)).join(' et ')})"),
                    ))
                .toList(),
            if (diagnostic.semainesChargees.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Semaines en surchages :"),
              ),
            ...diagnostic.semainesChargees
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text("Semaine $item"),
                    ))
                .toList(),
          ])),
    );
  }
}

// permet de modifier les heures d'un groupe,
// en choissant parmi les créneaux définis
class _GroupesCreneaux extends StatefulWidget {
  final int premiereSemaine;
  final List<GroupeID> groupes;
  final Map<Matiere, VueMatiere> creneaux;

  final void Function(Matiere mat, PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(Matiere mat, int semaine) onClearCreneaux;
  final void Function(
          Matiere mat, GroupeID premierGroupe, DateTime premierCreneau)
      onAttribueRegulier;

  const _GroupesCreneaux(this.premiereSemaine, this.groupes, this.creneaux,
      this.onAttributeCreneau, this.onClearCreneaux, this.onAttribueRegulier,
      {super.key});

  @override
  State<_GroupesCreneaux> createState() => _GroupesCreneauxState();
}

class _GroupesCreneauxState extends State<_GroupesCreneaux> {
  Matiere? matiere;

  @override
  Widget build(BuildContext context) {
    Widget body =
        const Center(child: Text("Veuillez sélectionner une matière"));
    if (matiere != null) {
      body = _MatiereCreneaux(
        widget.premiereSemaine,
        matiere!,
        widget.groupes,
        widget.creneaux[matiere!] ?? [],
        (origin, dst) => widget.onAttributeCreneau(matiere!, origin, dst),
        (semaine) => widget.onClearCreneaux(matiere!, semaine),
        (premierGroupe, premierCreneau) =>
            widget.onAttribueRegulier(matiere!, premierGroupe, premierCreneau),
      );
    }
    return Column(
      children: [
        DropdownButton(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            hint: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Choisir la matière..."),
            ),
            items: Matiere.values
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(formatMatiere(e)),
                      ),
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
        const SizedBox(height: 10),
        body,
      ],
    );
  }
}

class _MatiereCreneaux extends StatefulWidget {
  final int premiereSemaine;
  final Matiere matiere;
  final List<GroupeID> groupes;
  final VueMatiere creneaux;

  final void Function(PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(int semaine) onClearCreneaux;
  final void Function(GroupeID premierGroupe, DateTime premierCreneau)
      onAttribueRegulier;

  const _MatiereCreneaux(
      this.premiereSemaine,
      this.matiere,
      this.groupes,
      this.creneaux,
      this.onAttributeCreneau,
      this.onClearCreneaux,
      this.onAttribueRegulier,
      {super.key});

  @override
  State<_MatiereCreneaux> createState() => _MatiereCreneauxState();
}

class _MatiereCreneauxState extends State<_MatiereCreneaux> {
  bool inWizard = false;

  GroupeID? selectedGroupe;
  DateTime? selectedCreneau;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inWizard)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              """
              Cet assistant vous permet d'attribuer rapidement des créneaux de façon régulière.
              Les créneaux seront attribués séquentiellement en commençant par placer le premier groupe choisi sur le premier créneau choisi.
              Attention, les créneaux déjà attribués seront ignorés.
              """,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  inWizard ? "Premier groupe" : "Groupes",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                ListView(
                    shrinkWrap: true,
                    children: widget.groupes
                        .map((e) => inWizard
                            ? RadioListTile<GroupeID>(
                                dense: true,
                                title: Text(e),
                                value: e,
                                groupValue: selectedGroupe,
                                onChanged: (g) => setState(() {
                                      selectedGroupe = g;
                                    }))
                            : _DraggableGroup(PopulatedCreneau(emptyDate(), e)))
                        .toList()),
                const SizedBox(height: 20),
                inWizard
                    ? Row(children: [
                        ElevatedButton(
                            onPressed: () => setState(() {
                                  inWizard = false;
                                }),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text("Annuler"),
                            )),
                        const SizedBox(width: 5),
                        Expanded(
                          child: ElevatedButton(
                              onPressed: selectedGroupe == null ||
                                      selectedCreneau == null
                                  ? null
                                  : () {
                                      widget.onAttribueRegulier(
                                          selectedGroupe!, selectedCreneau!);
                                      setState(() {
                                        inWizard = false;
                                        selectedGroupe = null;
                                        selectedCreneau = null;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      inWizard ? Colors.green : null),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "Valider",
                                  textAlign: TextAlign.center,
                                ),
                              )),
                        ),
                      ])
                    : ElevatedButton(
                        onPressed: () => setState(() {
                              inWizard = true;
                            }),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Attribuer régulièrement...",
                            textAlign: TextAlign.center,
                          ),
                        )),
              ]),
            ),
            Expanded(
              flex: 6,
              child: _MatiereW(
                inWizard,
                selectedCreneau,
                widget.premiereSemaine,
                widget.matiere,
                widget.creneaux,
                widget.onAttributeCreneau,
                widget.onClearCreneaux,
                (creneau) => setState(() {
                  selectedCreneau = creneau;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DraggableGroup extends StatelessWidget {
  final PopulatedCreneau group; // date is optional
  final bool dense;
  const _DraggableGroup(this.group, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Draggable(
        dragAnchorStrategy: pointerDragAnchorStrategy,
        data: group,
        feedback: Card(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Text(
              group.groupeID,
            ),
          ),
        ),
        child: Card(
          margin: dense
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 0)
              : null,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 2 : 8),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Text(
              group.groupeID,
              textAlign: TextAlign.center,
            ),
          ),
        ));
  }
}

class _MatiereW extends StatelessWidget {
  final bool inWizard;
  final DateTime? selectedCreneau;

  final int premiereSemaine;

  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(int semaine) onClearCreneaux;
  final void Function(DateTime creneau) onSelectCreneau;

  const _MatiereW(
      this.inWizard,
      this.selectedCreneau,
      this.premiereSemaine,
      this.matiere,
      this.semaines,
      this.onAttributeCreneau,
      this.onClearCreneaux,
      this.onSelectCreneau,
      {super.key});

  bool isCreneauError(
      List<PopulatedCreneau> semaine, PopulatedCreneau creneau) {
    if (creneau.groupeID == NoGroup) {
      return false;
    }
    return semaine
            .where((element) => element.groupeID == creneau.groupeID)
            .length >=
        2;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            inWizard ? "Premier créneau" : "Créneaux",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            child: SemaineList(
              premiereSemaine,
              List<Widget>.generate(semaines.length, (semaineIndex) {
                final semaine = semaines[semaineIndex];
                return Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        children: semaine
                            .map(
                              (e) => inWizard
                                  ? _CreneauButton(
                                      Colle(e.date, matiere),
                                      e.groupeID == NoGroup ? null : e.groupeID,
                                      selectedCreneau == e.date,
                                      () => onSelectCreneau(e.date),
                                    )
                                  : _Creneau(
                                      Colle(e.date, matiere),
                                      e.groupeID == NoGroup ? null : e.groupeID,
                                      (src) => onAttributeCreneau(src, e),
                                      isError: isCreneauError(semaine, e),
                                    ),
                            )
                            .toList(),
                      ),
                    ),
                    if (!inWizard)
                      Tooltip(
                        message: "Enlever les affectation courantes",
                        child: IconButton(
                            splashRadius: 20,
                            onPressed: () => onClearCreneaux(semaineIndex),
                            icon: deleteIcon),
                      )
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    ));
  }
}

class _Creneau extends StatelessWidget {
  final Colle colle;
  final GroupeID? group;

  final bool isError;

  final void Function(PopulatedCreneau src) onAttributeCreneau;

  const _Creneau(this.colle, this.group, this.onAttributeCreneau,
      {super.key, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final time = formatDateHeure(colle.date);
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: DragTarget<PopulatedCreneau>(
        builder: (context, candidateData, rejectedData) {
          return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: candidateData.isNotEmpty
                          ? colle.matiere.color.withOpacity(0.5)
                          : Colors.transparent,
                      blurRadius: 2,
                      spreadRadius: 2)
                ],
                color: isError ? Colors.red.shade300 : null,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(
                    color: candidateData.isNotEmpty || group != null
                        ? colle.matiere.color
                        : Colors.black),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(time, style: const TextStyle(fontSize: 12)),
                SizedBox(
                    height: 20,
                    child: group != null
                        ? _DraggableGroup(
                            PopulatedCreneau(colle.date, group!),
                            dense: true,
                          )
                        : null)
              ]));
        },
        onWillAccept: (data) => data?.groupeID != group,
        onAccept: onAttributeCreneau,
      ),
    );
  }
}

class _CreneauButton extends StatelessWidget {
  final Colle colle;
  final GroupeID? group;

  final bool isSelected;

  final void Function() onSelect;

  const _CreneauButton(this.colle, this.group, this.isSelected, this.onSelect,
      {super.key});

  @override
  Widget build(BuildContext context) {
    final time = formatDateHeure(colle.date);
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: OutlinedButton(
          onPressed: group == null ? onSelect : null,
          style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? colle.matiere.color : null),
          child: Text(group != null ? "$time  $group" : time),
        ));
  }
}
