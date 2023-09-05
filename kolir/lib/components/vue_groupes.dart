import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kolir/components/attribue_info.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/rotations.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef CreneauxMatieres = Map<MatiereID, VueMatiere>;

const colorWarning = Colors.orangeAccent;

class VueGroupeW extends StatefulWidget {
  final CreneauHoraireProvider horaires;
  final MatiereProvider matieresList;
  final List<Groupe> groupes;
  final Map<GroupeID, VueGroupe> colles;
  final Map<GroupeID, Diagnostic> diagnostics;
  final CreneauxMatieres creneaux;

  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;
  final void Function(GroupeID) onClearGroupeCreneaux;
  final void Function(GroupeID id, List<DateHeure> creneauxInterdits)
      onUpdateGroupeContraintes;

  final void Function(GroupeID groupe, MatiereID mat, int creneauIndex)
      onToogleCreneau;
  final void Function(MatiereID mat) onClearMatiere;
  final Maybe<RotationSelector> Function(MatiereID mat, List<GroupeID> groupes,
      List<int> semaines, int periode) onSetupAttribueAuto;
  final void Function(SelectedRotation) onAttributeAuto;

  // special variants for informatique
  final List<AssignmentResult> Function(
          InformatiqueParams params, int semaineStart, int semaineEnd)
      onPreviewAttributeInformatique;
  final Function(List<AssigmentSuccess>, int semaineStart, String colleur)
      onAttributeInformatique;

  const VueGroupeW(this.horaires, this.matieresList, this.groupes, this.colles,
      this.diagnostics, this.creneaux,
      {required this.onAddGroupe,
      required this.onRemoveGroupe,
      required this.onClearGroupeCreneaux,
      required this.onUpdateGroupeContraintes,
      required this.onToogleCreneau,
      required this.onClearMatiere,
      required this.onSetupAttribueAuto,
      required this.onAttributeAuto,
      required this.onPreviewAttributeInformatique,
      required this.onAttributeInformatique,
      super.key});

  @override
  State<VueGroupeW> createState() => _VueGroupeWState();
}

class _VueGroupeWState extends State<VueGroupeW> {
  bool isInEdit = false;
  final itemScrollController = ItemScrollController();

  void scrollToFirstDiagnostic() {
    final groupeID = widget.diagnostics.keys.first;
    final index = widget.groupes.indexWhere((gr) => gr.id == groupeID);
    itemScrollController.scrollTo(
        index: index, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _DiagnosticAlert(widget.diagnostics, scrollToFirstDiagnostic),
      const SizedBox(width: 10),
      ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: isInEdit ? null : widget.onAddGroupe,
          icon: const Icon(Icons.add),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: isInEdit ? Colors.orange : null),
            child: Text(isInEdit ? "Retour" : "Attribuer automatiquement...")),
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
          firstChild: ScrollablePositionedList.builder(
              key: const PageStorageKey("list_groupes"),
              itemScrollController: itemScrollController,
              shrinkWrap: true,
              itemCount: widget.groupes.length,
              itemBuilder: (context, index) {
                final gr = widget.groupes[index];
                return _GroupeW(
                  widget.horaires,
                  widget.matieresList,
                  gr,
                  widget.colles[gr.id] ?? [],
                  widget.creneaux,
                  widget.diagnostics[gr.id] ??
                      const Diagnostic({}, [], [], [], []),
                  () => widget.onRemoveGroupe(gr.id),
                  () => widget.onClearGroupeCreneaux(gr.id),
                  (mat, creneauIndex) =>
                      widget.onToogleCreneau(gr.id, mat, creneauIndex),
                  widget.onClearMatiere,
                  (creneauxInterdits) => widget.onUpdateGroupeContraintes(
                      gr.id, creneauxInterdits),
                );
              }),
          secondChild: _Assistant(
              widget.matieresList,
              widget.horaires,
              widget.groupes,
              widget.creneaux,
              widget.onSetupAttribueAuto,
              widget.onAttributeAuto,
              widget.onPreviewAttributeInformatique,
              widget.onAttributeInformatique),
        ),
      ),
    );
  }
}

class _DiagnosticAlert extends StatelessWidget {
  final Map<GroupeID, Diagnostic> diagnostics;

  final void Function() onClick;

  const _DiagnosticAlert(this.diagnostics, this.onClick, {super.key});

  @override
  Widget build(BuildContext context) {
    final isValid = diagnostics.isEmpty;
    return ElevatedButton(
      onPressed: isValid ? null : onClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? Colors.greenAccent : colorWarning,
        disabledBackgroundColor: Colors.greenAccent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Text(
          isValid
              ? "Aucun problème détecté."
              : "Certains groupes requierent une attention.",
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _GroupeW extends StatefulWidget {
  final CreneauHoraireProvider horaires;
  final MatiereProvider matieresList;
  final Groupe groupe;
  final VueGroupe semaines;
  final CreneauxMatieres creneaux;
  final Diagnostic diagnostic;

  final void Function() onRemove;
  final void Function() onClearCreneaux;
  final void Function(MatiereID mat, int creneauIndex) onToogleCreneau;
  final void Function(MatiereID mat) onClearMatiere;
  final void Function(List<DateHeure> creneauxInterdits)
      onUpdateGroupeContraintes;

  const _GroupeW(
      this.horaires,
      this.matieresList,
      this.groupe,
      this.semaines,
      this.creneaux,
      this.diagnostic,
      this.onRemove,
      this.onClearCreneaux,
      this.onToogleCreneau,
      this.onClearMatiere,
      this.onUpdateGroupeContraintes,
      {super.key});

  @override
  State<_GroupeW> createState() => _GroupeWState();
}

enum _GroupAction { updateHoraires, deleteGroup, clearCreaneaux }

class _GroupeWState extends State<_GroupeW> {
  bool isInEdit = false;

  void showEditContraintes() async {
    final allCreneaux = widget.creneaux.values
        .map((l) => l
            .map((se) => se.item.map((cr) => cr.date))
            .fold(<DateHeure>[], (pv, e) => [...pv, ...e]))
        .fold(<DateHeure>[], (pv, e) => [...pv, ...e])
        .map((e) => e.copyWithWeek(1)) // erase week information
        .toSet()
        .toList();
    final newContraintes = await showDialog<List<DateHeure>>(
        context: context,
        builder: (context) => _EditContraintes(
            widget.horaires, allCreneaux, widget.groupe.creneauxInterdits));
    if (newContraintes != null) {
      widget.onUpdateGroupeContraintes(newContraintes);
    }
  }

  String get resumeContraintes {
    if (widget.groupe.creneauxInterdits.isEmpty) {
      return "(Aucune contrainte)";
    }
    return "(${widget.groupe.creneauxInterdits.map((e) => e.formatDateHeure(dense: true)).join(" - ")})";
  }

  int get nbMaxCollesParSemaine =>
      widget.semaines.map((s) => s.item.length).fold(0, max);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              PopupMenuButton<_GroupAction>(
                  constraints: const BoxConstraints(minWidth: 180),
                  tooltip: "Plus d'options...",
                  splashRadius: 20,
                  onSelected: (action) {
                    switch (action) {
                      case _GroupAction.updateHoraires:
                        showEditContraintes();
                        return;
                      case _GroupAction.clearCreaneaux:
                        widget.onClearCreneaux();
                        return;
                      case _GroupAction.deleteGroup:
                        widget.onRemove();
                        return;
                    }
                  },
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _GroupAction.updateHoraires,
                          child: ListTile(
                            title:
                                const Text("Modifier les contraintes horaires"),
                            subtitle: Text(resumeContraintes),
                            leading: const Icon(Icons.event_busy,
                                color: Colors.lime),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _GroupAction.clearCreaneaux,
                          child: ListTile(
                            title: Text(
                                "Supprimer tous les créneaux affectés au groupe"),
                            leading: Icon(Icons.clear, color: Colors.orange),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _GroupAction.deleteGroup,
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text("Supprimer définitivement le groupe"),
                          ),
                        ),
                      ]),
              Tooltip(
                message: isInEdit
                    ? "Terminer l'édition"
                    : "Modifier la répartition...",
                child: IconButton(
                  splashRadius: 20,
                  onPressed: () => setState(() {
                    isInEdit = !isInEdit;
                  }),
                  icon: Icon(isInEdit ? Icons.done : Icons.create_rounded),
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
                  firstChild: _GroupStaticW(widget.semaines,
                      widget.onToogleCreneau, widget.onClearMatiere),
                  secondChild: _GroupEditW(
                    widget.matieresList,
                    widget.groupe.id,
                    widget.creneaux,
                    widget.onToogleCreneau,
                  ),
                ),
              ),
              _DiagnosticW(widget.diagnostic, nbMaxCollesParSemaine)
            ],
          ),
        ),
      ),
    );
  }
}

class _EditContraintes extends StatefulWidget {
  final CreneauHoraireProvider horaires;
  final List<DateHeure> collesCreneaux;
  final List<DateHeure> initialesContraintes;

  const _EditContraintes(
      this.horaires, this.collesCreneaux, this.initialesContraintes,
      {super.key});

  @override
  State<_EditContraintes> createState() => __EditContraintesState();
}

class __EditContraintesState extends State<_EditContraintes> {
  var ct = CreneauxController(false);

  @override
  void initState() {
    ct.creneaux = widget.initialesContraintes.toList();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    ct.creneaux = widget.initialesContraintes.toList();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editer les contraintes horaires"),
      actions: [
        ElevatedButton(
            onPressed: () => Navigator.of(context).pop(ct.creneaux),
            child: const Text("Enregistrer les contraintes"))
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Sélectionner les créneaux étant non disponibles pour le groupe.",
              style: TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          WeekCalendar(
            widget.horaires,
            ct,
            placeholders: widget.collesCreneaux,
            activeCreneauColor: Colors.limeAccent,
          ),
        ],
      ),
    );
  }
}

class _GroupStaticW extends StatelessWidget {
  final VueGroupe semaines;
  final void Function(MatiereID matiere, int creneauIndex) onDelete;
  final void Function(MatiereID matiere) onClearMatiere;

  const _GroupStaticW(this.semaines, this.onDelete, this.onClearMatiere,
      {super.key});

  void confirmeClearMatiere(Matiere matiere, BuildContext context) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Confirmer"),
              content: Text(
                  "Confirmez-vous l'effacement des groupes pour la matière ${matiere.format()} ?"),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Effacer"),
                )
              ],
            ));
    if (ok != null) {
      onClearMatiere(matiere.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SemaineList(
        semaines
            .map((semaine) =>
                // pour un groupe et une semaine
                SemaineTo(
                    semaine.semaine,
                    Wrap(
                        runSpacing: 2,
                        children: semaine.item
                            .map((c) => ColleW(
                                  c,
                                  onDelete: (all) => all
                                      ? confirmeClearMatiere(c.matiere, context)
                                      : onDelete(
                                          c.matiere.index, c.creneauxIndex),
                                ))
                            .toList())))
            .toList(),
        "Aucune colle n'est encore prévue.");
  }
}

class _GroupEditW extends StatelessWidget {
  final MatiereProvider matieresList;
  final GroupeID groupe;
  final CreneauxMatieres creneaux;

  final void Function(MatiereID mat, int creneauIndex) onToogleCreneau;

  const _GroupEditW(
      this.matieresList, this.groupe, this.creneaux, this.onToogleCreneau,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return MatieresTabs(
      matieresList,
      (mat) => _GroupEditMatiere(
        groupe,
        matieresList.values[mat],
        creneaux[mat] ?? [],
        (creneauIndex) => onToogleCreneau(mat, creneauIndex),
      ),
    );
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
                            e.toColle(matiere),
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

class _DiagnosticCard extends StatelessWidget {
  final String title;
  final List<Widget> body;

  const _DiagnosticCard(this.title, this.body, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorWarning,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...body
            ]),
      ),
    );
  }
}

class _DiagnosticW extends StatelessWidget {
  final Diagnostic diagnostic;
  final int nbMaxColles;
  const _DiagnosticW(this.diagnostic, this.nbMaxColles, {super.key});

  @override
  Widget build(BuildContext context) {
    const itemPadding = EdgeInsets.symmetric(vertical: 2.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Card(
          color: Colors.yellow,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
                text: TextSpan(
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1?.color),
                    children: [
                  const TextSpan(text: "Nombre max. de colles par semaine : "),
                  TextSpan(
                      text: "$nbMaxColles",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ])),
          )),
      // collisions
      if (diagnostic.collisions.isNotEmpty)
        _DiagnosticCard(
            "Créneaux simultanés :",
            diagnostic.collisions.entries
                .map((item) => Padding(
                      padding: itemPadding,
                      child: Text(
                          "S${item.key.semaine} ${item.key.formatDateHeure()} (${item.value.map((m) => m.format(dense: true)).join(' et ')})"),
                    ))
                .toList()),
      // chevauchements
      if (diagnostic.chevauchements.isNotEmpty)
        _DiagnosticCard(
            "Créneaux en chevauchements :",
            diagnostic.chevauchements
                .map((ch) => Padding(
                      padding: itemPadding,
                      child: Text(
                          "S${ch.debut.date.semaine} ${ch.debut.date.formatDateHeure()} (${ch.debut.matiere.format(dense: true)}) - ${ch.fin.date.formatDateHeure()} (${ch.fin.matiere.format(dense: true)})"),
                    ))
                .toList()),
      // contraintes non respectées
      if (diagnostic.contraintes.isNotEmpty)
        _DiagnosticCard(
            "Contraintes horaires non respectées :",
            diagnostic.contraintes
                .map((item) => Padding(
                      padding: itemPadding,
                      child: Text(
                          "${item.date.formatDateHeure()} (${item.matiere.format(dense: true)})"),
                    ))
                .toList()),
      // surcharges
      if (diagnostic.semainesChargees.isNotEmpty)
        _DiagnosticCard(
            "Semaines en surchages :",
            diagnostic.semainesChargees
                .map((item) => Padding(
                      padding: itemPadding,
                      child: Text("Semaine $item"),
                    ))
                .toList()),
      // manque d'équilibre
      if (diagnostic.matiereNonEquilibrees.isNotEmpty)
        _DiagnosticCard(
            "Matières non équilibrées :",
            diagnostic.matiereNonEquilibrees
                .map((item) => Padding(
                      padding: itemPadding,
                      child: Text(item.format()),
                    ))
                .toList()),
    ]);
  }
}

// permet d'attribuer plusieurs créneaux d'un coup
class _Assistant extends StatelessWidget {
  final MatiereProvider matieresList;
  final CreneauHoraireProvider creneauxList;
  final List<Groupe> groupes;
  final Map<MatiereID, VueMatiere> creneaux;

  final Maybe<RotationSelector> Function(MatiereID mat, List<GroupeID> groupes,
      List<int> semaines, int periode) onSetupAttribueAuto;
  final void Function(SelectedRotation) onAttributeAuto;

  // special variants for informatique
  final List<AssignmentResult> Function(
          InformatiqueParams params, int semaineStart, int semaineEnd)
      onPreviewAttributeInformatique;
  final Function(List<AssigmentSuccess>, int semaineStart, String colleur)
      onAttributeInformatique;

  const _Assistant(
      this.matieresList,
      this.creneauxList,
      this.groupes,
      this.creneaux,
      this.onSetupAttribueAuto,
      this.onAttributeAuto,
      this.onPreviewAttributeInformatique,
      this.onAttributeInformatique,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return MatieresTabs(
        matieresList,
        (mat) => mat == informatiqueID
            ? AttribueInfo(creneauxList, onPreviewAttributeInformatique,
                onAttributeInformatique)
            : _AssistantMatiere(
                matieresList.values[mat],
                groupes,
                creneaux[mat] ?? [],
                (groupes, semaines, periode) =>
                    onSetupAttribueAuto(mat, groupes, semaines, periode),
                onAttributeAuto,
              ));
  }
}

class _AssistantMatiere extends StatefulWidget {
  final Matiere matiere;
  final List<Groupe> groupes;
  final VueMatiere creneaux;

  final Maybe<RotationSelector> Function(
          List<GroupeID> groupes, List<int> semaines, int periode)
      onSetupAttribueAuto;
  final void Function(SelectedRotation) onAttributeAuto;

  const _AssistantMatiere(this.matiere, this.groupes, this.creneaux,
      this.onSetupAttribueAuto, this.onAttributeAuto,
      {super.key});

  @override
  State<_AssistantMatiere> createState() => _AssistantMatiereState();
}

class _AssistantMatiereState extends State<_AssistantMatiere> {
  Set<GroupeID> selectedGroupes = {};
  Set<int> selectedSemaines = {};

  var periodeCt = TextEditingController();

  int? computationNumber; // null means not in computation
  CancelableOperation? selectionOperation;

  @override
  void didUpdateWidget(covariant _AssistantMatiere oldWidget) {
    selectedSemaines.clear();
    super.didUpdateWidget(oldWidget);
  }

  void _inferPeriodeHint() {
    if (selectedCreneaux.isEmpty) {
      periodeCt.text = "";
    } else {
      final periode = hintPeriode(selectedCreneaux, selectedGroupes.length);
      periodeCt.text = periode.toString();
    }
  }

  void onSelectGroupe(GroupeID groupe, bool checked) {
    setState(() {
      checked ? selectedGroupes.add(groupe) : selectedGroupes.remove(groupe);
      _inferPeriodeHint();
    });
  }

  void onSelectSemaines(Set<int> selected) {
    setState(() {
      selectedSemaines = selected;
      _inferPeriodeHint();
    });
  }

  void _onAttribue() async {
    final groupes = selectedGroupes.toList();
    groupes.sort();

    final res = widget.onSetupAttribueAuto(
        groupes, selectedSemaines.toList(), periode!);
    if (res.error.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("Contraintes"),
            content: Text(
              res.error,
              style: const TextStyle(fontStyle: FontStyle.italic),
            )),
      );
      return;
    }

    // actually launch the long computation

    setState(() {
      computationNumber = res.value.essais;
    });

    final op = compute((selector) => selector.select(), res.value);
    selectionOperation = CancelableOperation.fromFuture(op);
    final selected = await selectionOperation!.value; // launch the selection
    widget.onAttributeAuto(selected);

    setState(() {
      computationNumber = null;
      selectionOperation = null;
      selectedGroupes.clear();
      selectedSemaines.clear();
    });
  }

  void cancelSelection() {
    selectionOperation!.cancel();
    setState(() {
      computationNumber = null;
      selectionOperation = null;
    });
  }

  int? get periode => int.tryParse(periodeCt.text);

  Creneaux get selectedCreneaux => selectedSemaines
      .map((semaineIndex) => SemaineTo(
          semaineIndex,
          widget.creneaux
              .singleWhere((s) => s.semaine == semaineIndex) // week
              .item))
      .toList();

  bool isSelectionValide() {
    if (selectedGroupes.isEmpty || selectedSemaines.isEmpty) {
      return false;
    }
    if (periode == null) {
      return false;
    }

    // pour simplifier on impose l'égalite entre le nombre de
    // créneaux de chaque semaine
    final nbFirstWeek = selectedCreneaux.first.item.length;
    return selectedCreneaux.every((s) {
      final weekLength = s.item.length;
      return nbFirstWeek == weekLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                  "Choix des groupes",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                ListView(
                    shrinkWrap: true,
                    children: widget.groupes
                        .map((e) => CheckboxListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            dense: true,
                            title: Text(e.name),
                            selected: selectedGroupes.contains(e.id),
                            value: selectedGroupes.contains(e.id),
                            onChanged: (checked) =>
                                onSelectGroupe(e.id, checked!)))
                        .toList()),
              ]),
            ),
            Expanded(
              flex: 6,
              child: _AssistantMatiereCreneaux(
                selectedSemaines,
                widget.matiere,
                widget.creneaux,
                onSelectSemaines,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: periodeCt,
                decoration: const InputDecoration(
                    labelText: "Ajuster la période",
                    isDense: true,
                    helperText:
                        "Nombre de semaines entre deux colles, à ajuster quand la valeur déduite de la sélection est incorrecte."),
              ),
            ),
          ),
          const Spacer(),
          Tooltip(
            message: computationNumber != null
                ? "En train de choisir la meilleure répartition parmi $computationNumber..."
                : "Répartir automatiquement les groupes sélectionnés sur les semaines sélectionnées.",
            child: computationNumber != null
                ? ElevatedButton.icon(
                    onPressed: cancelSelection,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade600),
                    icon: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator()),
                    ),
                    label: const Text("Annuler l'opération..."))
                : ElevatedButton(
                    onPressed: isSelectionValide() ? _onAttribue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Atttribuer les créneaux",
                        textAlign: TextAlign.center,
                      ),
                    )),
          ),
        ])
      ],
    );
  }
}

class _AssistantMatiereCreneaux extends StatelessWidget {
  final Set<int> selectedSemaines;

  final Matiere matiere;
  final VueMatiere semaines;

  final void Function(Set<int> newSelection) onSelect;

  const _AssistantMatiereCreneaux(
      this.selectedSemaines, this.matiere, this.semaines, this.onSelect,
      {super.key});

  bool isSemaineDisponible(List<PopulatedCreneau> semaine) {
    return semaine.every((cr) => cr.groupe == null);
  }

  bool? get isAllSelected {
    if (semaines.length == selectedSemaines.length) return true;
    if (selectedSemaines.isEmpty) return false;
    return null;
  }

  void onSelectAll(bool? v) {
    final newSelection =
        v != null && v ? semaines.map((e) => e.semaine).toSet() : <int>{};
    onSelect(newSelection);
  }

  void onCheck(int semaine, bool isChecked) {
    isChecked
        ? selectedSemaines.add(semaine)
        : selectedSemaines.remove(semaine);
    onSelect(selectedSemaines);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          const Text(
            "Créneaux",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            tristate: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            value: isAllSelected,
            onChanged: onSelectAll,
            title: Row(
              children: const [Spacer(), Text("Sélectionner tout")],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            child: SingleChildScrollView(
              child: SemaineList(
                semaines.map((semaine) {
                  return SemaineTo(
                      semaine.semaine,
                      CheckboxListTile(
                        activeColor: matiere.color,
                        selectedTileColor: matiere.color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        value: selectedSemaines.contains(semaine.semaine),
                        selected: selectedSemaines.contains(semaine.semaine),
                        onChanged: isSemaineDisponible(semaine.item)
                            ? (value) => onCheck(semaine.semaine, value!)
                            : null,
                        title: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                children: semaine.item
                                    .map(
                                      (e) => _Creneau(
                                        e.toColle(matiere),
                                        e.groupe == null
                                            ? _CS.disponible
                                            : _CS.dejaPris,
                                        null,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ));
                }).toList(),
                "Aucun créneau n'est définie pour cette matière.",
              ),
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

  final void Function()? onPressed;

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
