import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:kolir/logic/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

typedef Collisions = Map<DateHeure, List<Matiere>>;

/// [Diagnostic] indique les problèmes de la répartition courante,
/// pour un groupe.
class Diagnostic {
  /// (au moins) deux créneaux en même temps.
  final Collisions collisions;

  /// semaine public
  final List<int> semainesChargees;
  const Diagnostic(this.collisions, this.semainesChargees);
}

typedef GroupeID = int;

class Groupe {
  final GroupeID id;
  const Groupe(this.id);

  String get name => "G$id";

  int toJson() {
    return id;
  }

  factory Groupe.fromJson(dynamic json) {
    return Groupe(json as int);
  }
}

/// [Colloscope] est la représentation en mémoire vive
/// d'un colloscope.
/// Il peut être enregistré (au format JSON), et affiché
/// sous différente formes (par matière, par semaine, par élève)
class Colloscope {
  final Map<Matiere, _Creneaux> _matieres;

  final List<Groupe> groupes;

  /// [notes] est un champ de texte libre.
  String notes;

  Colloscope(this._matieres, this.groupes, {this.notes = ""}) {
    assert(_matieres.values.every(
        (element) => element.isSorted((a, b) => a.date.compareTo(b.date))));
  }

  Map<String, dynamic> toJson() {
    return {
      "matieres": _matieres.map((k, v) =>
          MapEntry(k.index.toString(), v.map((e) => e.toJson()).toList())),
      "groupes": groupes.map((e) => e.toJson()).toList(),
      "notes": notes,
    };
  }

  factory Colloscope.fromJson(Map<String, dynamic> json) {
    return Colloscope(
        (json["matieres"] as Map).map((k, v) => MapEntry(
              Matiere.values[int.parse(k as String)],
              (v as List).map((cr) => _PopulatedCreneau.fromJson(cr)).toList(),
            )),
        ((json["groupes"] ?? []) as List)
            .map((e) => Groupe.fromJson(e))
            .toList(),
        notes: json["notes"] ?? "");
  }

  static Future<File> get _saveFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, "kolir.json");
    return File(path);
  }

  Future<String> save() async {
    final file = await _saveFile;
    await file
        .writeAsString(const JsonEncoder.withIndent(" ").convert(toJson()));
    return file.path;
  }

  static Future<Colloscope> load() async {
    final file = await _saveFile;
    final ok = await file.exists();
    if (!ok) {
      return Colloscope({}, []);
    }

    // Read the file
    final contents = await file.readAsString();

    return Colloscope.fromJson(jsonDecode(contents));
  }

  /// [parSemaine] trie les colles par semaine et renvoie une liste
  /// contigue de semaines
  List<SemaineTo<VueSemaine>> parSemaine() {
    final groupeMap = Map.fromEntries(groupes.map((e) => MapEntry(e.id, e)));
    final semaines = <int, VueSemaine>{};
    for (var item in _matieres.entries) {
      final matiere = item.key;
      for (var creneauIndex = 0;
          creneauIndex < item.value.length;
          creneauIndex++) {
        final creneau = item.value[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => {});
        final groupesParMatiere = semaine.putIfAbsent(matiere, () => []);
        groupesParMatiere.add(PopulatedCreneau(
            creneauIndex, creneau.date, groupeMap[creneau.groupeID]));
      }
    }
    return _semaineMapToList(semaines);
  }

  VueGroupe _groupeSemaines(GroupeID groupe) {
    final semaines = <int, List<Colle>>{};
    for (var element in _matieres.entries) {
      final matiere = element.key;
      final creneauxGroupe =
          element.value.where((element) => element.groupeID == groupe);
      for (var cr in creneauxGroupe) {
        final semaine = semaines.putIfAbsent(cr.date.semaine, () => []);
        semaine.add(Colle(cr.date, matiere));
      }
    }
    for (var l in semaines.values) {
      l.sort((a, b) => a.matiere.index - b.matiere.index);
    }
    return _semaineMapToList(semaines);
  }

  /// les créneaux non attribués sont ignorés
  Map<GroupeID, VueGroupe> parGroupe() {
    return Map.fromEntries(
        groupes.map((k) => MapEntry(k.id, _groupeSemaines(k.id))));
  }

  Map<Matiere, VueMatiere> parMatiere() {
    final groupeMap = Map.fromEntries(groupes.map((e) => MapEntry(e.id, e)));

    return _matieres.map((matiere, creneaux) {
      final semaines = <int, List<PopulatedCreneau>>{};
      for (var creneauIndex = 0;
          creneauIndex < creneaux.length;
          creneauIndex++) {
        final creneau = creneaux[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => []);
        semaine.add(PopulatedCreneau(
            creneauIndex, creneau.date, groupeMap[creneau.groupeID]));
      }
      // creneaux is already sorted
      return MapEntry(matiere, _semaineMapToList(semaines));
    });
  }

  /// [diagnostics] renvoie une liste de groupes posant problème.
  /// Un colloscope valide devrait renvoyer une liste vide.
  Map<GroupeID, Diagnostic> diagnostics() {
    final Map<GroupeID, Diagnostic> out = {};
    for (var item in parGroupe().entries) {
      final group = item.key;
      final parSemaine = item.value;

      // collisions
      final parCreneau = <DateHeure, List<Matiere>>{};
      for (var crs in parSemaine) {
        for (var cr in crs.item) {
          final l = parCreneau.putIfAbsent(cr.date, () => []);
          l.add(cr.matiere);
        }
      }
      final collisions =
          parCreneau.entries.where((element) => element.value.length > 1);

      // surchage : on calcule le nombre moyen de colles par semaine
      final nbColles = parSemaine.isEmpty
          ? 0
          : parSemaine
              .map((e) => e.item.length)
              .reduce((value, element) => value + element);
      final nbWeeks = parSemaine.length;
      final average = nbColles / nbWeeks;
      // plus de 1 d'écart -> surcharge
      final semainesChargees = parSemaine
          .where((s) => s.item.length > average.ceil() + 1)
          .map((s) => s.semaine)
          .toList();

      if (collisions.isNotEmpty || semainesChargees.isNotEmpty) {
        out[group] =
            Diagnostic(Collisions.fromEntries(collisions), semainesChargees);
      }
    }
    return out;
  }

  /// [nbCreneauxVaccants] renvoie le nombre de créneaux définis mais non
  /// attribués à un groupe
  int nbCreneauxVaccants() {
    return (_matieres.values
            .map((l) => l.where((cr) => cr.groupeID == null).length))
        .reduce((value, element) => value + element);
  }

  /// reset supprime complètement toutes les données.
  void reset() {
    _matieres.clear();
    groupes.clear();
    notes = "";
  }

  void addGroupe() {
    int serial = groupes.length + 1;
    while (groupes.indexWhere((g) => g.id == serial) != -1) {
      serial += 1;
    }
    groupes.add(Groupe(serial));
  }

  /// removeGroupe supprime le groupe donné
  /// les créneaux liés ne sont pas supprimés,
  /// mais désaffectés
  void removeGroupe(GroupeID id) {
    groupes.removeWhere((gr) => gr.id == id);

    // properly cleanup
    for (var l in _matieres.values) {
      for (var i = 0; i < l.length; i++) {
        final cr = l[i];
        if (cr.groupeID == id) {
          l[i] = _PopulatedCreneau(cr.date, null);
        }
      }
    }
  }

  /// [addCreneaux] ajoute les heures données comme non
  /// affectées, dupliquant et adaptant la liste pour chaque semaine
  /// demandée
  void addCreneaux(
      Matiere mat, List<DateHeure> semaineHours, List<int> semaines) {
    List<_PopulatedCreneau> finalTimes = [];
    for (var semaine in semaines) {
      for (var time in semaineHours) {
        final adjusted =
            DateHeure(semaine, time.weekday, time.hour, time.minute);
        finalTimes.add(_PopulatedCreneau(adjusted, null));
      }
    }

    // add into NoGroup
    final l = _matieres.putIfAbsent(mat, () => []);
    l.addAll(finalTimes);
    l.sort((a, b) =>
        a.date.compareTo(b.date)); // make sure sort invariant is preserved
  }

  /// removeCreneau supprime le creneau pour tous les groupes
  void removeCreneau(Matiere mat, int creneauIndex) {
    final l = _matieres[mat] ?? [];
    l.removeAt(creneauIndex);
  }

  /// toogleCreneau change l'état du créneau donné
  void toogleCreneau(GroupeID groupe, Matiere mat, int creneauIndex) {
    final l = _matieres[mat] ?? [];
    final cr = l[creneauIndex];
    l[creneauIndex] =
        _PopulatedCreneau(cr.date, cr.groupeID == null ? groupe : null);
  }

  void attribueCyclique(List<GroupeID> groupes, List<int> semaines) {}

  // /// [attribueRegulier] remplie les créneaux disponibles dans la matière [mat]
  // /// en commençant par [premierGroupe] -> [premierCreneauIndex]
  // /// les créneaux déjà attribués sont ignorés
  // void attribueRegulier(
  //     Matiere mat, GroupeID premierGroupe, int premierCreneauIndex) {
  //   // to simplify, build the list of available creaneaux, starting at premierCreneauIndex
  //   final ordered = [
  //     ...(_matieres[mat] ?? []).sublist(premierCreneauIndex),
  //     ...(_matieres[mat] ?? []).sublist(0, premierCreneauIndex)
  //   ];
  //   final disponibles = ordered.where((cr) => cr.groupeID == null).toList();

  //   var currentGroupeIndex = groupes.indexWhere((gr) => gr.id == premierGroupe);
  //   if (currentGroupeIndex == -1) {
  //     return;
  //   }

  //   for (var creneau in disponibles) {
  //     final currentGroupe = groupes[currentGroupeIndex % groupes.length];
  //     final gr = _groupes.putIfAbsent(currentGroupe, () => {});
  //     final matList = gr.putIfAbsent(mat, () => []);
  //     matList.add(creneau);

  //     currentGroupeIndex += 1; // iterate in parallel
  //   }

  //   // clear the NoGroup group
  //   disponibles.clear();
  // }
}

enum Matiere {
  maths,
  esh, // Eco
  anglais,
  allemand,
  espagnol,
  francais,
  philo;
}

// ---------------------------------------------------------

typedef HeuresGroupe = Map<Matiere, HeuresMatiereGroupe>;

extension HG on HeuresGroupe {
  Map<String, dynamic> toJson() {
    return map((key, value) => MapEntry(key.index.toString(), value.toJson()));
  }

  static HeuresGroupe fromJson(Map<String, dynamic> json) {
    return json.map((key, value) =>
        MapEntry(Matiere.values[int.parse(key)], HMG.fromJson(value)));
  }
}

class Colle {
  final DateHeure date;
  final Matiere matiere;
  const Colle(this.date, this.matiere);
}

typedef VueGroupe = List<SemaineTo<List<Colle>>>; // semaines => colles
typedef HeuresMatiereGroupe = List<DateHeure>;

extension HMG on HeuresMatiereGroupe {
  List<Map<String, dynamic>> toJson() {
    return map((e) => e.toJson()).toList();
  }

  static HeuresMatiereGroupe fromJson(List<dynamic> json) {
    return json
        .map((e) => DateHeure.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

typedef VueSemaine = Map<Matiere, List<PopulatedCreneau>>;

/// les créneaux sont triés par date, et peuvent
/// etre identifiés par index pour gérer les doublons
typedef _Creneaux = List<_PopulatedCreneau>;

typedef VueMatiere = List<SemaineTo<List<PopulatedCreneau>>>;

class _PopulatedCreneau {
  final DateHeure date;
  final GroupeID? groupeID;

  const _PopulatedCreneau(this.date, this.groupeID);

  Map<String, dynamic> toJson() {
    return {
      "date": date.toJson(),
      "groupeID": groupeID,
    };
  }

  factory _PopulatedCreneau.fromJson(Map<String, dynamic> json) {
    return _PopulatedCreneau(
        DateHeure.fromJson(json["date"]), json["groupeID"]);
  }
}

class PopulatedCreneau {
  /// [index] est l'identifiant unique d'un créneau dans la
  /// liste définie par une matière
  final int index;
  final DateHeure date;
  final Groupe? groupe;

  const PopulatedCreneau(this.index, this.date, this.groupe);
}

class SemaineTo<T> {
  final int semaine;
  final T item;
  const SemaineTo(this.semaine, this.item);
}

// convert to a sorted list
List<SemaineTo<T>> _semaineMapToList<T>(Map<int, T> semaines) {
  final out = semaines.entries.map((e) => SemaineTo(e.key, e.value)).toList();
  out.sort((a, b) => a.semaine - b.semaine);
  return out;
}
