import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/vue_groupes.dart';
import 'package:kolir/components/vue_matieres.dart';
import 'package:kolir/components/vue_semaines.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/creneaux.dart';
import 'package:kolir/logic/export/groupes.dart';
import 'package:kolir/logic/export/matieres.dart';
import 'package:kolir/logic/export/semaines.dart';
import 'package:kolir/logic/export/utils.dart';
import 'package:kolir/logic/rotations.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

void main() async {
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kolir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({super.key});

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with SingleTickerProviderStateMixin {
  Colloscope currentColloscope = Colloscope({}, []);
  Colloscope savedColloscope =
      Colloscope({}, []); // cached version for the lastly saved

  var mode = ModeView.matieres;
  final notesController = TextEditingController();

  bool get isDirty => !currentColloscope.isEqual(savedColloscope);

  @override
  void initState() {
    _loadFromFile();
    super.initState();
  }

  Future<void> _loadFromFile() async {
    Colloscope col;
    try {
      col = await Colloscope.load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur pendant le chargement: $e"),
          backgroundColor: Colors.orange));
      col = Colloscope({}, []);
    }
    setState(() {
      currentColloscope = col;
      savedColloscope = col.copy();
      notesController.text = col.notes;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Colloscope chargé."), backgroundColor: Colors.green));
  }

  void _save() async {
    final path = await currentColloscope.save();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Enregistré dans $path.")));
    setState(() {
      savedColloscope = currentColloscope.copy();
    });
  }

  void _reload() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirmer"),
            content: const Text(
                "Etes-vous sûr de recharger le colloscope depuis le disque ?"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("Recharger"))
            ],
          );
        });
    if (confirm != null && confirm) {
      setState(() {
        currentColloscope = savedColloscope.copy();
      });
    }
  }

  void addGroupe() {
    setState(() {
      currentColloscope.addGroupe();
    });
  }

  void removeGroupe(GroupeID groupe) {
    setState(() {
      currentColloscope.removeGroupe(groupe);
    });
  }

  void clearGroupeCreneaux(GroupeID groupe) {
    setState(() {
      currentColloscope.clearGroupeCreneaux(groupe);
    });
  }

  void updateGroupeContraintes(GroupeID id, List<DateHeure> contraintes) {
    setState(() {
      currentColloscope.updateGroupeContraintes(id, contraintes);
    });
  }

  void addCreneaux(MatiereID mat, List<DateHeure> hours, List<int> semaines,
      String colleur) {
    setState(() {
      currentColloscope.addCreneaux(mat, hours, semaines, colleur);
    });
  }

  void deleteCreneau(MatiereID mat, int creneauIndex) {
    setState(() {
      currentColloscope.deleteCreneau(mat, creneauIndex);
    });
  }

  void deleteSemaine(MatiereID mat, int semaine) {
    setState(() {
      currentColloscope.deleteSemaine(mat, semaine);
    });
  }

  void editCreneauColleur(MatiereID mat, int creneauIndex, String colleur) {
    setState(() {
      currentColloscope.editCreneauColleur(mat, creneauIndex, colleur);
    });
  }

  void editCreneauxSalle(MatiereID mat, int creneauIndex, String salle) {
    setState(() {
      currentColloscope.editCreneauxSalle(mat, creneauIndex, salle);
    });
  }

  void toogleCreneau(GroupeID groupe, MatiereID mat, int creneauIndex) {
    setState(() {
      currentColloscope.toogleCreneau(groupe, mat, creneauIndex);
    });
  }

  void clearMatiere(MatiereID matiereID) {
    setState(() {
      currentColloscope.clearMatiere(matiereID);
    });
  }

  void attribueAuto(SelectedRotation res) {
    currentColloscope.attribueAuto(res);
    setState(() {});
  }

  void repeteMotifCourant(MatiereID matiere, int nombre, int? periode) {
    setState(() {
      currentColloscope.repeteMotifCourant(matiere, nombre, periode: periode);
    });
  }

  void permuteCreneauxGroupe(CreneauID src, CreneauID dst) {
    setState(() {
      currentColloscope.permuteCreneauxGroupe(src, dst);
    });
  }

  void editCalendrier(Map<int, DateTime> m) {
    setState(() {
      currentColloscope.semaines = SemaineProvider(m);
    });
  }

  void shiftSemaines(int shift) {
    setState(() {
      currentColloscope.shiftSemaines(shift);
    });
  }

  void attributeInformatique(
      List<AssigmentSuccess> assignments, int semaineStart, String colleur) {
    setState(() {
      currentColloscope.attributeInformatique(
          assignments, semaineStart, colleur);
    });
  }

  void _export() async {
    final colors =
        currentColloscope.matieresList.values.map((m) => m.color).toList();
    final matieres = matieresToHTML(currentColloscope);
    final groupes = groupesToHTML(currentColloscope, colors);
    final semaines = semainesToHTML(currentColloscope, colors);
    final creneaux = creneauxToHTML(currentColloscope, colors);

    final matieresPath =
        await saveDocument(matieres, "colloscope_matieres.html");
    final groupesPath = await saveDocument(groupes, "colloscope_groupes.html");
    final semainesPath =
        await saveDocument(semaines, "colloscope_semaines.html");
    final creneauxPath =
        await saveDocument(creneaux, "colloscope_creneaux.html");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Colloscope exporté dans :\n$matieresPath \n$groupesPath \n$semainesPath \n$creneauxPath"),
        backgroundColor: Colors.green));
  }

  Widget get body {
    switch (mode) {
      case ModeView.semaines:
        return VueSemaineW(
          currentColloscope.matieresList,
          currentColloscope.nbCreneauxVaccants(),
          currentColloscope.parSemaine(),
          currentColloscope.semaines,
          permuteCreneauxGroupe,
          editCalendrier,
        );
      case ModeView.groupes:
        return VueGroupeW(
          currentColloscope.creneauxHoraires,
          currentColloscope.matieresList,
          currentColloscope.groupes,
          currentColloscope.parGroupe(),
          currentColloscope.diagnostics(),
          currentColloscope.parMatiere(),
          onAddGroupe: addGroupe,
          onRemoveGroupe: removeGroupe,
          onClearGroupeCreneaux: clearGroupeCreneaux,
          onUpdateGroupeContraintes: updateGroupeContraintes,
          onToogleCreneau: toogleCreneau,
          onClearMatiere: clearMatiere,
          onSetupAttribueAuto: currentColloscope.setupAttribueAuto,
          onAttributeAuto: attribueAuto,
          onPreviewAttributeInformatique:
              currentColloscope.previewAttributeInformatique,
          onAttributeInformatique: attributeInformatique,
        );
      case ModeView.matieres:
        return VueMatiereW(
          currentColloscope.matieresList,
          currentColloscope.creneauxHoraires,
          currentColloscope.parMatiere(),
          onAdd: addCreneaux,
          onDeleteCreneau: deleteCreneau,
          onDeleteSemaine: deleteSemaine,
          onEditColleur: editCreneauColleur,
          onEditSalle: editCreneauxSalle,
          onRepeteMotifCourant: repeteMotifCourant,
          onShiftSemaines: shiftSemaines,
        );
    }
  }

  void _toogleView(ModeView mode) {
    setState(() {
      this.mode = mode;
    });
  }

  void _saveNotes() async {
    currentColloscope.notes = notesController.text;
    savedColloscope.notes = notesController.text;
    await savedColloscope.save();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Notes enregistrées.")));
  }

  void _editNotes() async {
    final save = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text("Editer les notes"),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Enregistrer"))
              ],
              content: SizedBox(
                width: 800,
                child: TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      label: Text("Notes libres"),
                    ),
                    maxLines: 15),
              ));
        });
    if (save != null && save) {
      _saveNotes();
    }
  }

  void _clear() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirmer"),
            content:
                const Text("Etes-vous sûr d'effacer le colloscope actuel ?"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("Effacer"))
            ],
          );
        });
    if (confirm != null && confirm) {
      setState(() {
        currentColloscope.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edition du colloscope - ${mode.title}"),
        actions: [
          Tooltip(
              message: "Exporter le colloscope au format HTML.",
              child: ElevatedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.download),
                  label: const Text("Exporter"))),
          Tooltip(
            message: "Sauvegarder le colloscope actuel sur le disque.",
            child: ElevatedButton.icon(
                onPressed: isDirty ? _save : null,
                icon: Icon(
                  Icons.save,
                  color: isDirty ? Colors.green : Colors.grey,
                ),
                label: const Text("Enregistrer")),
          ),
          Tooltip(
            message: "Revenir à la dernière sauvegarde.",
            child: ElevatedButton.icon(
                onPressed: isDirty ? _reload : null,
                icon: Icon(
                  Icons.restore_page_rounded,
                  color: isDirty ? Colors.orange : Colors.grey,
                ),
                label: const Text("Annuler")),
          ),
          Tooltip(
            message: "Modifier les notes",
            child: IconButton(
                splashRadius: 15,
                onPressed: _editNotes,
                icon: const Icon(Icons.edit_note_rounded)),
          ),
          Tooltip(
              message: "Vider entièrement le colloscope.",
              child: ElevatedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Colors.red,
                  ),
                  label: const Text("Effacer"))),
        ],
      ),
      body: NotificationListener<ViewNotification>(
          onNotification: (v) {
            _toogleView(v.mode);
            return true;
          },
          child: body),
    );
  }
}
