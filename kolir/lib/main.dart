import 'package:flutter/material.dart';
import 'package:kolir/components/vue_groupes.dart';
import 'package:kolir/components/vue_matieres.dart';
import 'package:kolir/components/vue_semaines.dart';
import 'package:kolir/logic/colloscope.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

enum _ModeView { semaines, groupes, matieres }

final l = [DateTime(2022, 9, 6, 10, 30), DateTime(2022, 9, 15, 19, 30)];

final sample = Colloscope({
  "G1": {
    Matiere.maths: l,
    Matiere.allemand: l,
  },
  "G2": {
    Matiere.maths: l,
    Matiere.allemand: l,
  },
  "G3": {
    Matiere.maths: l,
    Matiere.allemand: l,
  }
}, DateTime(2022, 9, 5));

class _HomeState extends State<_Home> {
  Colloscope col = sample;
  var mode = _ModeView.semaines;

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
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Colloscope chargé."), backgroundColor: Colors.green));
  }

  void addGroupe() {
    setState(() {
      col.addGroupe();
    });
  }

  void removeGroupe(GroupeID groupe) {
    setState(() {
      col.removeGroupe(groupe);
    });
  }

  void addCreneaux(Matiere mat, List<DateTime> hours, List<int> semaines) {
    setState(() {
      col.addCreneaux(mat, hours, semaines);
    });
  }

  Widget get body {
    switch (mode) {
      case _ModeView.semaines:
        return VueSemaineW(col.parSemaine());
      case _ModeView.groupes:
        return VueGroupeW(
          col.parGroupe(),
          onAddGroupe: addGroupe,
          onRemoveGroupe: removeGroupe,
        );
      case _ModeView.matieres:
        return VueMatiereW(col.parMatiere(), addCreneaux);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Kolir"),
        actions: [
          ElevatedButton(
              onPressed: () async {
                final path = await col.save();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enregistré dans $path.")));
              },
              child: const Text("Enregistrer")),
          ElevatedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Confirmer"),
                        content: const Text(
                            "Etes vous sur d'effacer le colloscope actuel ?"),
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
              },
              child: const Text("Effacer")),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  mode = _ModeView
                      .values[(mode.index + 1) % (_ModeView.values.length)];
                });
              },
              child: const Text("Mode"))
        ],
      ),
      body: body,
    );
  }
}
