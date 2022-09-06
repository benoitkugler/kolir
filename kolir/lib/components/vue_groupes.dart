import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

typedef Creneaux = Map<Matiere, VueMatiere>;

final colorWarning = Colors.deepOrange.shade200;

class VueGroupeW extends StatefulWidget {
  final List<Groupe> groupes;
  final Map<GroupeID, VueGroupe> colles;
  final Map<GroupeID, Diagnostic> diagnostics;
  final Creneaux creneaux;

  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;

  final void Function(GroupeID groupe, Matiere mat, int creneauIndex)
      onToogleCreneau;
  final void Function(
          Matiere mat, GroupeID premierGroupe, DateHeure premierCreneau)
      onAttribueRegulier;

  const VueGroupeW(this.groupes, this.colles, this.diagnostics, this.creneaux,
      {required this.onAddGroupe,
      required this.onRemoveGroupe,
      required this.onToogleCreneau,
      required this.onAttribueRegulier,
      super.key});

  @override
  State<VueGroupeW> createState() => _VueGroupeWState();
}

class _VueGroupeWState extends State<VueGroupeW> {
  bool isInEdit = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.colles.entries.toList();
    final actions = [
      ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: isInEdit ? null : widget.onAddGroupe,
          icon: const Icon(IconData(0xe047, fontFamily: 'MaterialIcons')),
          label: const Text("Ajouter un groupe")),
      const SizedBox(width: 10),
      Tooltip(
        message: isInEdit
            ? "Quitter l'assistant"
            : "Attribuer rapidement une séquence de créneaux pour une matière.",
        child: ElevatedButton(
            onPressed: () => setState(() {
                  isInEdit = !isInEdit;
                }),
            child:
                Text(isInEdit ? "Terminer" : "Ajouter plusieurs créneaux...")),
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
                  children: widget.groupes
                      .map((gr) => _GroupeW(
                            gr,
                            widget.colles[gr.id] ?? [],
                            widget.creneaux,
                            widget.diagnostics[gr.id],
                            () => widget.onRemoveGroupe(gr.id),
                            (mat, creneauIndex) => widget.onToogleCreneau(
                                gr.id, mat, creneauIndex),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          secondChild: _GroupesCreneaux(widget.colles.keys.toList(),
              widget.creneaux, widget.onAttribueRegulier),
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

class _GroupeW extends StatefulWidget {
  final Groupe groupe;
  final VueGroupe semaines;
  final Creneaux creneaux;
  final Diagnostic? diagnostic;

  final void Function() onRemove;
  final void Function(Matiere mat, int creneauIndex) onToogleCreneau;

  const _GroupeW(this.groupe, this.semaines, this.creneaux, this.diagnostic,
      this.onRemove, this.onToogleCreneau,
      {super.key});

  @override
  State<_GroupeW> createState() => _GroupeWState();
}

class _GroupeWState extends State<_GroupeW> {
  bool isInEdit = false;

  @override
  Widget build(BuildContext context) {
    print(widget.creneaux[Matiere.maths]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Tooltip(
                message: "Supprimer définitivement le groupe",
                child: IconButton(
                  onPressed: widget.onRemove,
                  icon: deleteIcon,
                  splashRadius: 20,
                  color: Colors.red,
                ),
              ),
              Tooltip(
                message: isInEdit
                    ? "Terminer l'édition"
                    : "Modifier la répartition...",
                child: IconButton(
                  splashRadius: 20,
                  onPressed: () => setState(() {
                    isInEdit = !isInEdit;
                  }),
                  icon: Icon(isInEdit
                      ? const IconData(0xe1f6, fontFamily: 'MaterialIcons')
                      : const IconData(0xf67a, fontFamily: 'MaterialIcons')),
                  color: isInEdit ? Colors.green : null,
                ),
              ),
              Text(
                widget.groupe.name,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isInEdit
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _GroupStaticW(widget.semaines),
                  secondChild: _GroupEditW(
                    widget.groupe.id,
                    widget.creneaux,
                    widget.onToogleCreneau,
                  ),
                ),
              ),
              if (widget.diagnostic != null) _DiagnosticW(widget.diagnostic!)
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupStaticW extends StatelessWidget {
  final VueGroupe semaines;

  const _GroupStaticW(this.semaines, {super.key});

  @override
  Widget build(BuildContext context) {
    return SemaineList(
        semaines
            .map((semaine) =>
                // pour un groupe et une semaine
                SemaineTo(
                    semaine.semaine,
                    Wrap(
                        children: semaine.item.map((c) => ColleW(c)).toList())))
            .toList(),
        "Aucune colle n'est encore prévue.");
  }
}

class _GroupEditW extends StatefulWidget {
  final GroupeID groupe;
  final Creneaux creneaux;

  final void Function(Matiere mat, int creneauIndex) onToogleCreneau;

  const _GroupEditW(this.groupe, this.creneaux, this.onToogleCreneau,
      {super.key});

  @override
  State<_GroupEditW> createState() => _GroupEditWState();
}

class _GroupEditWState extends State<_GroupEditW>
    with TickerProviderStateMixin {
  late final TabController ct;

  @override
  void initState() {
    ct = TabController(length: Matiere.values.length, vsync: this);
    super.initState();
  }

  Matiere get mat => Matiere.values[ct.index];

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TabBar(
                  controller: ct,
                  onTap: (value) => setState(() {
                    ct.index = value;
                  }),
                  isScrollable: true,
                  labelColor: Colors.black,
                  splashBorderRadius:
                      const BorderRadius.all(Radius.circular(4)),
                  tabs: Matiere.values
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(formatMatiere(e)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                _GroupEditMatiere(
                  widget.groupe,
                  mat,
                  widget.creneaux[mat] ?? [],
                  (creneauIndex) => widget.onToogleCreneau(mat, creneauIndex),
                ),
              ],
            )));
  }
}

class _GroupEditMatiere extends StatelessWidget {
  final GroupeID groupeID;
  final Matiere matiere;
  final VueMatiere creneaux;

  final void Function(int creneauIndex) onToogleCreneau;

  const _GroupEditMatiere(
      this.groupeID, this.matiere, this.creneaux, this.onToogleCreneau,
      {super.key});

  bool isCreneauError(
      List<PopulatedCreneau> semaine, PopulatedCreneau creneau) {
    if (creneau.groupe?.id != groupeID) {
      return false;
    }
    final duplicates = semaine
        .where((element) => element.groupe?.id == creneau.groupe?.id)
        .length;
    return duplicates >= 2;
  }

  _CS getState(List<PopulatedCreneau> semaine, PopulatedCreneau creneau) {
    final creneauID = creneau.groupe?.id;
    if (creneauID == null) {
      return _CS.disponible;
    }
    if (creneauID != groupeID) {
      return _CS.dejaPris;
    }
    if (isCreneauError(semaine, creneau)) {
      return _CS.invalide;
    }
    return _CS.selectionne; // car creneauID == groupeID
  }

  @override
  Widget build(BuildContext context) {
    return SemaineList(
        creneaux
            .map(
              (semaine) => SemaineTo(
                semaine.semaine,
                Wrap(
                  children: semaine.item
                      .map((e) => _Creneau(
                            Colle(e.date, matiere),
                            getState(semaine.item, e),
                            () => onToogleCreneau(e.index),
                          ))
                      .toList(),
                ),
              ),
            )
            .toList(),
        "Aucun créneau n'est encore défini.");
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
  final List<GroupeID> groupes;
  final Map<Matiere, VueMatiere> creneaux;

  final void Function(
          Matiere mat, GroupeID premierGroupe, DateHeure premierCreneau)
      onAttribueRegulier;

  const _GroupesCreneaux(this.groupes, this.creneaux, this.onAttribueRegulier,
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
        matiere!,
        widget.groupes,
        widget.creneaux[matiere!] ?? [],
        (origin, dst) {}, // TODO
        (semaine) {}, // TODO
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
  final Matiere matiere;
  final List<GroupeID> groupes;
  final VueMatiere creneaux;

  final void Function(PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(int semaine) onClearCreneaux;
  final void Function(GroupeID premierGroupe, DateHeure premierCreneau)
      onAttribueRegulier;

  const _MatiereCreneaux(this.matiere, this.groupes, this.creneaux,
      this.onAttributeCreneau, this.onClearCreneaux, this.onAttribueRegulier,
      {super.key});

  @override
  State<_MatiereCreneaux> createState() => _MatiereCreneauxState();
}

class _MatiereCreneauxState extends State<_MatiereCreneaux> {
  bool inWizard = false;

  GroupeID? selectedGroupe;
  DateHeure? selectedCreneau;

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
                                title: Text(e.toString()), // TODO
                                value: e,
                                groupValue: selectedGroupe,
                                onChanged: (g) => setState(() {
                                      selectedGroupe = g;
                                    }))
                            : _DraggableGroup(
                                PopulatedCreneau(0, emptyDate(), null))) // TODO
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
  final PopulatedCreneau creneau; // date is optional
  final bool dense;
  const _DraggableGroup(this.creneau, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 0)
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 2 : 8),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Text(
            creneau.groupe?.name ?? "",
            textAlign: TextAlign.center,
          ),
        ));
  }
}

class _MatiereW extends StatelessWidget {
  final bool inWizard;
  final DateHeure? selectedCreneau;

  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(PopulatedCreneau src, PopulatedCreneau dst)
      onAttributeCreneau;
  final void Function(int semaine) onClearCreneaux;
  final void Function(DateHeure creneau) onSelectCreneau;

  const _MatiereW(
      this.inWizard,
      this.selectedCreneau,
      this.matiere,
      this.semaines,
      this.onAttributeCreneau,
      this.onClearCreneaux,
      this.onSelectCreneau,
      {super.key});

  bool isCreneauError(
      List<PopulatedCreneau> semaine, PopulatedCreneau creneau) {
    if (creneau.groupe == null) {
      return false;
    }
    return semaine
            .where((element) => element.groupe == creneau.groupe)
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
              semaines.map((semaine) {
                return SemaineTo(
                    semaine.semaine,
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            children: semaine.item
                                .map(
                                  (e) => inWizard
                                      ? _CreneauButton(
                                          Colle(e.date, matiere),
                                          e.groupe?.id,
                                          selectedCreneau == e.date,
                                          () => onSelectCreneau(e.date),
                                        )
                                      : _Creneau(
                                          Colle(e.date, matiere),
                                          _CS.dejaPris,
                                          () {},
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
                                onPressed: () =>
                                    onClearCreneaux(semaine.semaine),
                                icon: deleteIcon),
                          )
                      ],
                    ));
              }).toList(),
              "",
            ),
          ),
        ],
      ),
    ));
  }
}

enum _CS { disponible, dejaPris, invalide, selectionne }

class _Creneau extends StatelessWidget {
  final Colle colle;

  final _CS state;

  final void Function() onPressed;

  const _Creneau(this.colle, this.state, this.onPressed, {super.key});

  Color get backgroundColor {
    switch (state) {
      case _CS.invalide:
        return Colors.red.shade300;
      case _CS.dejaPris:
        return Colors.grey;
      case _CS.disponible:
        return Colors.white;
      case _CS.selectionne:
        return colle.matiere.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = colle.date.formatDateHeure();
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Tooltip(
          message:
              state == _CS.dejaPris ? "Créneau occupé par un autre groupe" : "",
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: backgroundColor,
            ),
            onPressed: state == _CS.dejaPris ? null : onPressed,
            child: Text(time, style: const TextStyle(fontSize: 12)),
          ),
        ));
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
    final time = colle.date.formatDateHeure();
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
