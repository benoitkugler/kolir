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
  Colloscope col = Colloscope({}, []);
  var mode = ModeView.matieres;
  final notesController = TextEditingController();

  bool isDirty = false;

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
      this.col = col;
      notesController.text = col.notes;
      isDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Colloscope chargé."), backgroundColor: Colors.green));
  }

  void addGroupe() {
    setState(() {
      col.addGroupe();
      isDirty = true;
    });
  }

  void removeGroupe(GroupeID groupe) {
    setState(() {
      col.removeGroupe(groupe);
      isDirty = true;
    });
  }

  void addCreneaux(Matiere mat, List<DateHeure> hours, List<int> semaines) {
    setState(() {
      col.addCreneaux(mat, hours, semaines);
      isDirty = true;
    });
  }

  void removeCreneau(Matiere mat, int creneauIndex) {
    setState(() {
      col.removeCreneau(mat, creneauIndex);
      isDirty = true;
    });
  }

  void onToogleCreneau(GroupeID groupe, Matiere mat, int creneauIndex) {
    setState(() {
      col.toogleCreneau(groupe, mat, creneauIndex);
      isDirty = true;
    });
  }

  void attribueRegulier(
      Matiere mat, GroupeID premierGroupe, DateHeure premierCreneau) {
    // TODO
  }

  void _export() async {
    final matieres = matieresToHTML(col);
    final groupes = groupesToHTML(col);
    final semaines = semainesToHTML(col, matieresColors);

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
        return VueSemaineW(col.nbCreneauxVaccants(), col.parSemaine());
      case ModeView.groupes:
        return VueGroupeW(
          col.groupes,
          col.parGroupe(),
          col.diagnostics(),
          col.parMatiere(),
          onAddGroupe: addGroupe,
          onRemoveGroupe: removeGroupe,
          onToogleCreneau: onToogleCreneau,
          onAttribueRegulier: attribueRegulier,
        );
      case ModeView.matieres:
        return VueMatiereW(col.parMatiere(), addCreneaux, removeCreneau);
    }
  }

  void _save() async {
    final path = await col.save();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Enregistré dans $path.")));
    setState(() {
      isDirty = false;
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
      _loadFromFile();
    }
  }

  void _toogleView(ModeView mode) {
    setState(() {
      this.mode = mode;
    });
  }

  void _saveNotes() async {
    col.notes = notesController.text;
    await col.save();
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
        col.reset();
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
                    IconData(0xf645, fontFamily: 'MaterialIcons'),
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
