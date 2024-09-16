import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/week_calendar.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';

import '../logic/utils.dart';

class VueMatiereW extends StatelessWidget {
  final MatiereProvider matieresList;
  final CreneauHoraireProvider horaires;

  final Map<MatiereID, VueMatiere> byMatieres;

  final void Function(CreneauHoraireProvider) onUpdateHoraires;

  final void Function() onCreateMatiere;
  final void Function(Matiere matiere) onUpdateMatiere;
  final void Function(Matiere matiere) onDeleteMatiere;
  final void Function(Matiere matiere) onEmptyCreneaux;

  final void Function(MatiereID mat, List<DateHeure> hours, List<int> semaines,
      String colleur) onAdd;
  final void Function(MatiereID mat, int creneauIndex) onDeleteCreneau;
  final void Function(MatiereID mat, int semaine) onDeleteSemaine;
  final void Function(MatiereID mat, int creneauIndex, String colleur)
      onEditColleur;
  final void Function(MatiereID mat, int creneauIndex, String salle)
      onEditSalle;
  final void Function(MatiereID mat, int nombre, int? periode)
      onRepeteMotifCourant;
  final void Function(int shift) onShiftSemaines;

  const VueMatiereW(this.matieresList, this.horaires, this.byMatieres,
      {required this.onUpdateHoraires,
      required this.onCreateMatiere,
      required this.onUpdateMatiere,
      required this.onDeleteMatiere,
      required this.onEmptyCreneaux,
      required this.onAdd,
      required this.onDeleteCreneau,
      required this.onDeleteSemaine,
      required this.onEditColleur,
      required this.onEditSalle,
      required this.onRepeteMotifCourant,
      required this.onShiftSemaines,
      super.key});

  @override
  Widget build(BuildContext context) {
    return VueSkeleton(
      mode: ModeView.matieres,
      actions: [
        ElevatedButton.icon(
            onPressed: () async {
              final newHoraires = await showDialog<CreneauHoraireProvider>(
                  context: context,
                  builder: (context) => _HorairesPicker(horaires));
              if (newHoraires == null) return;
              onUpdateHoraires(newHoraires);
            },
            icon: const Icon(Icons.calendar_view_day),
            label: const Text("Editer les horaires")),
        const SizedBox(width: 10),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen.shade400),
            onPressed: onCreateMatiere,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter une matière")),
        const SizedBox(width: 10),
        ElevatedButton(
            onPressed: () async {
              final shift = await showDialog<int>(
                  context: context,
                  builder: (context) => const _ShiftSemaineDialog());
              if (shift == null) return;
              onShiftSemaines(shift);
            },
            child: const Text("Décaler les semaines..."))
      ],
      child: Expanded(
          child: ListView(
        key: const PageStorageKey("list_matiere"),
        children: matieresList.list
            .map((mat) => _MatiereW(
                  horaires,
                  mat,
                  byMatieres[mat.id] ?? [],
                  () => onDeleteMatiere(mat),
                  onUpdateMatiere,
                  () => onEmptyCreneaux(mat),
                  (h, s, c) => onAdd(mat.id, h, s, c),
                  (index) => onDeleteCreneau(mat.id, index),
                  (index) => onDeleteSemaine(mat.id, index),
                  (index, colleur) => onEditColleur(mat.id, index, colleur),
                  (index, salle) => onEditSalle(mat.id, index, salle),
                  (nombre, periode) =>
                      onRepeteMotifCourant(mat.id, nombre, periode),
                ))
            .toList(),
      )),
    );
  }
}

class _ShiftSemaineDialog extends StatefulWidget {
  const _ShiftSemaineDialog({super.key});

  @override
  State<_ShiftSemaineDialog> createState() => __ShiftSemaineDialogState();
}

class __ShiftSemaineDialogState extends State<_ShiftSemaineDialog> {
  TextEditingController fromC = TextEditingController();
  TextEditingController toC = TextEditingController();

  @override
  void initState() {
    fromC.addListener(() => setState(() => {}));
    toC.addListener(() => setState(() => {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Décaler les semaines"),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: fromC,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: "de"),
            ),
          ),
          const SizedBox(width: 50),
          Expanded(
            child: TextField(
              controller: toC,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: "à"),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed:
                isValid ? () => Navigator.of(context).pop(to! - from!) : null,
            child: const Text("Décaler"))
      ],
    );
  }

  int? get from => int.tryParse(fromC.text);
  int? get to => int.tryParse(toC.text);

  bool get isValid => from != null && to != null && from != to;
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

  final void Function() onDelete;
  final void Function(Matiere) onUpdate;
  final void Function() onEmptyCreneaux;

  final void Function(List<DateHeure> hours, List<int> semaines, String colleur)
      onAdd;
  final void Function(int creneauIndex) onDeleteCreneau;
  final void Function(int semaine) onDeleteSemaine;
  final void Function(int creneauIndex, String colleur) onEditColleur;
  final void Function(int creneauIndex, String salle) onEditSalle;

  final void Function(int nombre, int? periode) onRepeteMotifCourant;

  const _MatiereW(
      this.horaires,
      this.matiere,
      this.semaines,
      this.onDelete,
      this.onUpdate,
      this.onEmptyCreneaux,
      this.onAdd,
      this.onDeleteCreneau,
      this.onDeleteSemaine,
      this.onEditColleur,
      this.onEditSalle,
      this.onRepeteMotifCourant,
      {super.key});

  void showAddCreneaux(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Ajouter des créneaux"),
              content: AssistantCreneaux(
                horaires,
                (creneaux, semaines, colleur) {
                  Navigator.of(context).pop();
                  onAdd(creneaux, semaines, colleur);
                },
              ),
            ));
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

  void _showEditMatiere(BuildContext context) async {
    final updated = await showDialog<Matiere>(
      context: context,
      builder: (context) => _MatiereDetailsDialog(matiere),
    );
    if (updated != null) onUpdate(updated);
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
                width: MediaQuery.of(context).size.width * 0.12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(matiere.format(),
                          style: const TextStyle(fontSize: 18)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          splashRadius: 18,
                          tooltip: "Modifier la matière",
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditMatiere(context),
                        ),
                        IconButton(
                          splashRadius: 18,
                          color: Colors.red,
                          tooltip: "Supprimer la matière",
                          icon: const Icon(Icons.delete),
                          onPressed: onDelete,
                        ),
                        IconButton(
                          splashRadius: 18,
                          color: Colors.orange,
                          tooltip: "Vider les créneaux",
                          icon: const Icon(Icons.restart_alt),
                          onPressed: onEmptyCreneaux,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SemaineList(
                    semaines
                        .map((semaine) => SemaineTo(
                            semaine.semaine,
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Wrap(
                                    runSpacing: 2,
                                    children: semaine.item
                                        .map((e) => ColleW(e.toColle(matiere),
                                            state: e.groupe == null
                                                ? ChipState.regular
                                                : ChipState.highlighted,
                                            showMatiere: false,
                                            onDelete: (_) =>
                                                onDeleteCreneau(e.index),
                                            onEditColleur: (colleur) =>
                                                onEditColleur(e.index, colleur),
                                            onEditSalle: (salle) =>
                                                onEditSalle(e.index, salle)))
                                        .toList(),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  splashRadius: 18,
                                  color: Colors.red,
                                  tooltip:
                                      "Supprimer les créneaux de la semaine ${semaine.semaine}",
                                  icon: const Icon(Icons.clear),
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
                      onPressed: matiere.hasInitialCreneaux
                          ? () => showAddCreneaux(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen.shade400),
                      child: const Text("Ajouter des créneaux")),
                  const SizedBox(height: 10),
                  Tooltip(
                      message: "Répéter la structure courante n fois",
                      child: ElevatedButton(
                          onPressed: matiere.hasInitialCreneaux
                              ? () => showDuplicate(context)
                              : null,
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

class _MatiereDetailsDialog extends StatefulWidget {
  final Matiere matiere;
  const _MatiereDetailsDialog(this.matiere, {super.key});

  @override
  State<_MatiereDetailsDialog> createState() => _MatiereDetailsDialogState();
}

class _MatiereDetailsDialogState extends State<_MatiereDetailsDialog> {
  final nameCt = TextEditingController();
  final shortNameCt = TextEditingController();
  final dureeCt = TextEditingController();
  final periodeCt = TextEditingController();
  Color color = Colors.blue;
  final colorCt = TextEditingController();
  bool hasInitialCreneaux = true;

  @override
  initState() {
    nameCt.text = widget.matiere.name;
    shortNameCt.text = widget.matiere.shortName;
    dureeCt.text = widget.matiere.colleDuree.toString();
    periodeCt.text = widget.matiere.periode.toString();
    color = widget.matiere.color;
    colorCt.text = color.toHexString(includeHashSign: true);
    hasInitialCreneaux = widget.matiere.hasInitialCreneaux;
    super.initState();
  }

  _showColorPicker() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Modifier la couleur"),
              content: MaterialPicker(
                  pickerColor: color,
                  onColorChanged: (c) => setState(() {
                        color = c;
                        colorCt.text = color.toHexString(includeHashSign: true);
                      })),
            ));
  }

  Matiere? data() {
    if (nameCt.text.isEmpty || shortNameCt.text.isEmpty) return null;
    final duree = int.tryParse(dureeCt.text);
    if (duree == null) return null;
    final periode = int.tryParse(periodeCt.text);
    if (periode == null || periode < 1) return null;
    return Matiere(widget.matiere.id, nameCt.text, shortNameCt.text, color,
        colleDuree: duree,
        periode: periode,
        hasInitialCreneaux: hasInitialCreneaux);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Modifier la matière : ${widget.matiere.name}"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          decoration: const InputDecoration(labelText: "Nom"),
          controller: nameCt,
          onChanged: (_) => setState(() {}),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: "Abbréviation"),
          controller: shortNameCt,
          onChanged: (_) => setState(() {}),
        ),
        TextFormField(
          decoration: const InputDecoration(
              labelText: "Durée d'une colle",
              suffixText: "minutes",
              helperText: "Utilisé pour calculer les chevauchements"),
          controller: dureeCt,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextFormField(
          decoration: const InputDecoration(
              labelText: "Période",
              suffixText: "semaines",
              helperText:
                  "Période de rotation pour chaque groupe (une colle toutes les ... semaines)",
              helperMaxLines: 2),
          controller: periodeCt,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
            title: const Text("Créneaux fixes"),
            value: hasInitialCreneaux,
            onChanged: (b) => setState(() {
                  hasInitialCreneaux = b!;
                })),
        const SizedBox(height: 10),
        TextFormField(
          readOnly: true,
          onTap: _showColorPicker,
          decoration: InputDecoration(
              labelText: "Couleur",
              hoverColor: color,
              prefixIcon: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              suffixIcon: Icon(
                Icons.edit,
                color: color,
              )),
          controller: colorCt,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
            onPressed:
                data() == null ? null : () => Navigator.of(context).pop(data()),
            child: const Text("Enregistrer"))
      ]),
    );
  }
}

class _HorairesPicker extends StatefulWidget {
  final CreneauHoraireProvider horaires;

  const _HorairesPicker(this.horaires, {super.key});

  @override
  State<_HorairesPicker> createState() => __HorairesPickerState();
}

class __HorairesPickerState extends State<_HorairesPicker> {
  late CreneauHoraireProvider horaires;
  @override
  void initState() {
    horaires = widget.horaires.copy();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _HorairesPicker oldWidget) {
    horaires = widget.horaires.copy();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Modifier les horaires"),
          IconButton.filledTonal(
              onPressed: () async {
                final creneau = await showDialog<CreneauHoraireData>(
                    context: context,
                    builder: (context) => const _CreneauHoraireDialog());
                if (creneau == null) return;
                setState(() => horaires.insert(creneau));
              },
              icon: const Icon(Icons.add),
              color: Colors.green),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: horaires.values.isEmpty
                ? null
                : () => Navigator.of(context).pop(horaires),
            child: const Text("Enregistrer"))
      ],
      content: SizedBox(
        width: 400,
        child: ListView(
            shrinkWrap: true,
            children: horaires.values
                .map((e) => ListTile(
                      title: Text("${e.hour}:${formatMinute(e.minute)}"),
                      trailing: IconButton(
                          onPressed: () =>
                              setState(() => horaires.values.remove(e)),
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.red,
                          )),
                    ))
                .toList()),
      ),
    );
  }
}

class _CreneauHoraireDialog extends StatefulWidget {
  const _CreneauHoraireDialog({super.key});

  @override
  State<_CreneauHoraireDialog> createState() => __CreneauHoraireDialogState();
}

class __CreneauHoraireDialogState extends State<_CreneauHoraireDialog> {
  int hour = 17;
  int minute = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouveau créneau"),
      content: Row(
        children: [
          DropdownMenu<int>(
              label: const Text("Heure"),
              initialSelection: hour,
              dropdownMenuEntries: [
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23
              ].map((e) => DropdownMenuEntry(value: e, label: "$e")).toList(),
              onSelected: (h) => setState(() => hour = h!)),
          const SizedBox(width: 10),
          DropdownMenu<int>(
              label: const Text("Minutes"),
              initialSelection: minute,
              dropdownMenuEntries: [
                0,
                5,
                10,
                15,
                20,
                25,
                30,
                35,
                40,
                45,
                50,
                55,
              ].map((e) => DropdownMenuEntry(value: e, label: "$e")).toList(),
              onSelected: (m) => setState(() => minute = m!))
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(CreneauHoraireData(hour, minute));
            },
            child: const Text("Ajouter"))
      ],
    );
  }
}
