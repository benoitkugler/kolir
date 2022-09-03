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
  Colloscope col = Colloscope.empty();
  var mode = ModeView.matieres;
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
      col = Colloscope.empty();
    }
    setState(() {
      this.col = col;
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

  void addCreneaux(Matiere mat, List<DateTime> hours, List<int> semaines) {
    setState(() {
      col.addCreneaux(mat, hours, semaines);
      isDirty = true;
    });
  }

  void removeCreneau(Matiere mat, DateTime creneau) {
    setState(() {
      col.removeCreneau(mat, creneau);
      isDirty = true;
    });
  }

  Creneaux attributeCreneau(
      Matiere mat, PopulatedCreneau src, PopulatedCreneau dst) {
    setState(() {
      col.attributeCreneau(mat, src, dst);
      isDirty = true;
    });
    return col.parMatiere();
  }

  Creneaux clearCreneaux(Matiere mat, int semaine) {
    setState(() {
      col.clearCreneaux(mat, semaine);
      isDirty = true;
    });
    return col.parMatiere();
  }

  Creneaux attribueRegulier(
      Matiere mat, GroupeID premierGroupe, DateTime premierCreneau) {
    setState(() {
      col.attribueRegulier(mat, premierGroupe, premierCreneau);
      isDirty = true;
    });
    return col.parMatiere();
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
        return VueSemaineW(col.parSemaine());
      case ModeView.groupes:
        return VueGroupeW(
          col.premiereSemaine,
          col.parGroupe(),
          col.parMatiere(),
          onAddGroupe: addGroupe,
          onRemoveGroupe: removeGroupe,
          onAttributeCreneau: attributeCreneau,
          onClearCreneaux: clearCreneaux,
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

  void _toogleView() {
    setState(() {
      mode = ModeView.values[(mode.index + 1) % (ModeView.values.length)];
    });
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
          onNotification: (_) {
            _toogleView();
            return true;
          },
          child: body),
    );
  }
}
