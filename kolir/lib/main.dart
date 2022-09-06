import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/components/vue_groupes.dart';
import 'package:kolir/components/vue_matieres.dart';
import 'package:kolir/components/vue_semaines.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/export/groupes.dart';
import 'package:kolir/logic/export/matieres.dart';
import 'package:kolir/logic/export/semaines.dart';
import 'package:kolir/logic/export/utils.dart';
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

class _HomeState extends State<_Home> {
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

  void _loadFromFile() async {
    Colloscope col;
    try {
      col = await Colloscope.load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Erreur pendant le chargement"),
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

  void addCreneaux(Matiere mat, List<DateHeure> hours, List<int> semaines) {
    setState(() {
      currentColloscope.addCreneaux(mat, hours, semaines);
    });
  }

  void removeCreneau(Matiere mat, int creneauIndex) {
    setState(() {
      currentColloscope.removeCreneau(mat, creneauIndex);
    });
  }

  void toogleCreneau(GroupeID groupe, Matiere mat, int creneauIndex) {
    setState(() {
      currentColloscope.toogleCreneau(groupe, mat, creneauIndex);
    });
  }

  void attribueCreneaux(Matiere matiere, List<GroupeID> groupes,
      List<int> semaines, bool usePermuation) {
    setState(() {
      currentColloscope.attribueCyclique(
          matiere, groupes, semaines, usePermuation);
    });
  }

  void _export() async {
    final matieres = matieresToHTML(currentColloscope);
    final groupes = groupesToHTML(currentColloscope);
    final semaines = semainesToHTML(currentColloscope, matieresColors);

    final matieresPath =
        await saveDocument(matieres, "colloscope_matieres.html");
    final groupesPath = await saveDocument(groupes, "colloscope_groupes.html");
    final semainesPath =
        await saveDocument(semaines, "colloscope_semaines.html");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Colloscope exporté dans :\n$matieresPath \n$groupesPath \n$semainesPath"),
        backgroundColor: Colors.green));
  }

  Widget get body {
    switch (mode) {
      case ModeView.semaines:
        return VueSemaineW(currentColloscope.nbCreneauxVaccants(),
            currentColloscope.parSemaine());
      case ModeView.groupes:
        return VueGroupeW(
          currentColloscope.groupes,
          currentColloscope.parGroupe(),
          currentColloscope.diagnostics(),
          currentColloscope.parMatiere(),
          onAddGroupe: addGroupe,
          onRemoveGroupe: removeGroupe,
          onToogleCreneau: toogleCreneau,
          onAttribueCreneaux: attribueCreneaux,
        );
      case ModeView.matieres:
        return VueMatiereW(currentColloscope.creneauxHoraires,
            currentColloscope.parMatiere(), addCreneaux, removeCreneau);
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
          return Dialog(
              child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Editer les notes",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextFormField(
                              controller: notesController,
                              decoration: const InputDecoration(
                                  label: Text("Notes libres")),
                              maxLines: 10),
                        ),
                        Row(
                          children: [
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Enregistrer")),
                            )
                          ],
                        )
                      ],
                    ),
                  )));
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
                  icon:
                      const Icon(IconData(0xe201, fontFamily: 'MaterialIcons')),
                  label: const Text("Exporter"))),
          Tooltip(
            message: "Sauvegarder le colloscope actuel sur le disque.",
            child: ElevatedButton.icon(
                onPressed: isDirty ? _save : null,
                icon: Icon(
                  const IconData(0xe550, fontFamily: 'MaterialIcons'),
                  color: isDirty ? Colors.green : Colors.grey,
                ),
                label: const Text("Enregistrer")),
          ),
          Tooltip(
            message: "Revenir à la dernière sauvegarde.",
            child: ElevatedButton.icon(
                onPressed: isDirty ? _reload : null,
                icon: Icon(
                  const IconData(0xf010a, fontFamily: 'MaterialIcons'),
                  color: isDirty ? Colors.orange : Colors.grey,
                ),
                label: const Text("Annuler")),
          ),
          Tooltip(
            message: "Modifier les notes",
            child: IconButton(
                splashRadius: 15,
                onPressed: _editNotes,
                icon:
                    const Icon(IconData(0xf030f, fontFamily: 'MaterialIcons'))),
          ),
          Tooltip(
              message: "Vider entièrement le colloscope.",
              child: ElevatedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(
                    clearIcon,
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
