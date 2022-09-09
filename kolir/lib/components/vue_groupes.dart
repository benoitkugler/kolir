import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

typedef Creneaux = Map<MatiereID, VueMatiere>;

const colorWarning = Colors.orangeAccent;

class VueGroupeW extends StatefulWidget {
  final CreneauHoraireProvider horaires;
  final MatiereProvider matieresList;
  final List<Groupe> groupes;
  final Map<GroupeID, VueGroupe> colles;
  final Map<GroupeID, Diagnostic> diagnostics;
  final Creneaux creneaux;

  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;
  final void Function(GroupeID) onClearGroupeCreneaux;
  final void Function(GroupeID id, List<DateHeure> creneauxInterdits)
      onUpdateGroupeContraintes;

  final void Function(GroupeID groupe, MatiereID mat, int creneauIndex)
      onToogleCreneau;
  final void Function(MatiereID mat, List<GroupeID> groupes, List<int> semaines,
      bool usePermutation) onAttribueCyclique;
  final String Function(
    MatiereID mat,
    List<GroupeID> groupes,
    List<int> semaines,
  ) checkAttributeCyclique;

  const VueGroupeW(this.horaires, this.matieresList, this.groupes, this.colles,
      this.diagnostics, this.creneaux,
      {required this.onAddGroupe,
      required this.onRemoveGroupe,
      required this.onClearGroupeCreneaux,
      required this.onUpdateGroupeContraintes,
      required this.onToogleCreneau,
      required this.onAttribueCyclique,
      required this.checkAttributeCyclique,
      super.key});

  @override
  State<VueGroupeW> createState() => _VueGroupeWState();
}

class _VueGroupeWState extends State<VueGroupeW> {
  bool isInEdit = false;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (widget.diagnostics.isNotEmpty) ...[
        _DiagnosticAlert(widget.diagnostics),
        const SizedBox(width: 10),
      ],
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
          firstChild: ListView(
            shrinkWrap: true,
            children: widget.groupes
                .map((gr) => _GroupeW(
                      widget.horaires,
                      widget.matieresList,
                      gr,
                      widget.colles[gr.id] ?? [],
                      widget.creneaux,
                      widget.diagnostics[gr.id],
                      () => widget.onRemoveGroupe(gr.id),
                      () => widget.onClearGroupeCreneaux(gr.id),
                      (mat, creneauIndex) =>
                          widget.onToogleCreneau(gr.id, mat, creneauIndex),
                      (creneauxInterdits) => widget.onUpdateGroupeContraintes(
                          gr.id, creneauxInterdits),
                    ))
                .toList(),
          ),
          secondChild: _Assistant(
            widget.matieresList,
            widget.groupes,
            widget.creneaux,
            widget.onAttribueCyclique,
            widget.checkAttributeCyclique,
          ),
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
    return const Card(
      color: colorWarning,
      child: Padding(
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
  final CreneauHoraireProvider horaires;
  final MatiereProvider matieresList;
  final Groupe groupe;
  final VueGroupe semaines;
  final Creneaux creneaux;
  final Diagnostic? diagnostic;

  final void Function() onRemove;
  final void Function() onClearCreneaux;
  final void Function(MatiereID mat, int creneauIndex) onToogleCreneau;
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
      this.onUpdateGroupeContraintes,
      {super.key});

  @override
  State<_GroupeW> createState() => _GroupeWState();
}

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

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(Icons.delete),
                  splashRadius: 20,
                  color: Colors.red,
                ),
              ),
              Tooltip(
                richMessage: TextSpan(children: [
                  const TextSpan(text: "Modifier les contraintes horaires\n"),
                  TextSpan(
                      text: resumeContraintes,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ]),
                child: IconButton(
                  splashRadius: 20,
                  onPressed: showEditContraintes,
                  icon: const Icon(Icons.event_busy),
                  color: Colors.lime,
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
                  icon: Icon(isInEdit ? Icons.done : Icons.create_rounded),
                  color: isInEdit ? Colors.green : null,
                ),
              ),
              Tooltip(
                message: "Supprimer tous les créneaux affectés au groupe",
                child: IconButton(
                  splashRadius: 20,
                  onPressed: widget.onClearCreneaux,
                  icon: const Icon(Icons.clear),
                  color: Colors.orange,
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
                    widget.matieresList,
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

class _GroupEditW extends StatelessWidget {
  final MatiereProvider matieresList;
  final GroupeID groupe;
  final Creneaux creneaux;

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
  const _DiagnosticW(this.diagnostic, {super.key});

  @override
  Widget build(BuildContext context) {
    const itemPadding = EdgeInsets.symmetric(vertical: 2.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
    ]);
  }
}

// permet d'attribuer plusieurs créneaux d'un coup
class _Assistant extends StatelessWidget {
  final MatiereProvider matieresList;
  final List<Groupe> groupes;
  final Map<MatiereID, VueMatiere> creneaux;

  final void Function(MatiereID mat, List<GroupeID> groupes, List<int> semaines,
      bool usePermutation) onAttribue;
  final String Function(
    MatiereID mat,
    List<GroupeID> groupes,
    List<int> semaines,
  ) checkAttribue;

  const _Assistant(this.matieresList, this.groupes, this.creneaux,
      this.onAttribue, this.checkAttribue,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return MatieresTabs(
        matieresList,
        (mat) => _AssistantMatiere(
              matieresList.values[mat],
              groupes,
              creneaux[mat] ?? [],
              (groupes, semaines, p) => onAttribue(mat, groupes, semaines, p),
              (groupes, semaines) => checkAttribue(mat, groupes, semaines),
            ));
  }
}

class _AssistantMatiere extends StatefulWidget {
  final Matiere matiere;
  final List<Groupe> groupes;
  final VueMatiere creneaux;

  final void Function(
          List<GroupeID> groupes, List<int> semaines, bool usePermutation)
      onAttribue;
  final String Function(List<GroupeID> groupes, List<int> semaines)
      checkAttribue;

  const _AssistantMatiere(this.matiere, this.groupes, this.creneaux,
      this.onAttribue, this.checkAttribue,
      {super.key});

  @override
  State<_AssistantMatiere> createState() => _AssistantMatiereState();
}

class _AssistantMatiereState extends State<_AssistantMatiere> {
  Set<GroupeID> selectedGroupes = {};
  Set<int> selectedSemaines = {};

  bool usePermutation = true;

  @override
  void didUpdateWidget(covariant _AssistantMatiere oldWidget) {
    selectedSemaines.clear();
    super.didUpdateWidget(oldWidget);
  }

  void _onAttribue() {
    final groupes = selectedGroupes.toList();
    groupes.sort();

    final error = widget.checkAttribue(groupes, selectedSemaines.toList());
    if (error.isNotEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        "Les contraintes des groupes ne peuvent pas être résolues."),
                    Text(
                      error,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              ));
      return;
    }

    widget.onAttribue(groupes, selectedSemaines.toList(), usePermutation);
    setState(() {
      selectedGroupes.clear();
      selectedSemaines.clear();
    });
  }

  bool isSelectionValide() {
    if (selectedGroupes.isEmpty || selectedSemaines.isEmpty) {
      return false;
    }
    // pour simplifier on impose l'égalite entre le nombre de
    // créneaux de chaque semaine
    final nbFirstWeek = widget.creneaux
        .singleWhere((s) => s.semaine == selectedSemaines.first) // first week
        .item
        .length;
    return selectedSemaines.every((semaineIndex) {
      final nbWeek = widget.creneaux
          .singleWhere((s) => s.semaine == semaineIndex) // week
          .item
          .length;
      return nbFirstWeek == nbWeek;
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
                            onChanged: (checked) => setState(() {
                                  checked!
                                      ? selectedGroupes.add(e.id)
                                      : selectedGroupes.remove(e.id);
                                })))
                        .toList()),
              ]),
            ),
            Expanded(
              flex: 6,
              child: _AssistantMatiereCreneaux(
                selectedSemaines,
                widget.matiere,
                widget.creneaux,
                (semaine, selected) => setState(() {
                  selected
                      ? selectedSemaines.add(semaine)
                      : selectedSemaines.remove(semaine);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Flexible(
            child: CheckboxListTile(
                title: const Text(
                    "Appliquer une permutation d'une semaine à l'autre"),
                value: usePermutation,
                onChanged: (value) => setState(() {
                      usePermutation = value!;
                    })),
          ),
          const Spacer(),
          Tooltip(
            message:
                "Placer les groupes sélectionnés sur les semaines sélectionnées.",
            child: ElevatedButton(
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

  final void Function(int semaine, bool selected) onSelectSemaine;

  const _AssistantMatiereCreneaux(
      this.selectedSemaines, this.matiere, this.semaines, this.onSelectSemaine,
      {super.key});

  bool isSemaineDisponible(List<PopulatedCreneau> semaine) {
    return semaine.every((cr) => cr.groupe == null);
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
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
                            ? (value) =>
                                onSelectSemaine(semaine.semaine, value!)
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
