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

  final void Function() onCreateMatiere;
  final void Function(Matiere matiere) onUpdateMatiere;
  final void Function(Matiere matiere) onDeleteMatiere;

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
      {required this.onCreateMatiere,
      required this.onUpdateMatiere,
      required this.onDeleteMatiere,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                width: MediaQuery.of(context).size.width * 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(matiere.format(),
                        style: const TextStyle(fontSize: 18)),
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
                      onPressed: matiere.hasInitialCreneaux
                          ? () => showAddCreneaux(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
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
  Color color = Colors.blue;
  bool hasInitialCreneaux = true;

  @override
  initState() {
    nameCt.text = widget.matiere.name;
    shortNameCt.text = widget.matiere.shortName;
    dureeCt.text = widget.matiere.colleDuree.toString();
    color = widget.matiere.color;
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
                      })),
            ));
  }

  Matiere? data() {
    if (nameCt.text.isEmpty || shortNameCt.text.isEmpty) return null;
    final duree = int.tryParse(dureeCt.text);
    if (duree == null) return null;
    return Matiere(widget.matiere.id, nameCt.text, shortNameCt.text, color,
        colleDuree: duree, hasInitialCreneaux: hasInitialCreneaux);
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
              labelText: "Durée d'une colle", suffixText: "minutes"),
          controller: dureeCt,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            Text(color.toHexString(includeHashSign: true)),
            IconButton(
              onPressed: _showColorPicker,
              icon: const Icon(Icons.edit),
              color: color,
            ),
          ],
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
