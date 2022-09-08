import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kolir/logic/settings.dart';
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

  @override
  bool operator ==(Object other) =>
      other is Groupe && other.runtimeType == runtimeType && other.id == id;

  @override
  int get hashCode => id;
}

bool areMatieresEqual(
    Map<MatiereID, _Creneaux> m1, Map<MatiereID, _Creneaux> m2) {
  if (m1.length != m2.length) {
    return false;
  }
  for (var mat in m1.keys) {
    final l1 = m1[mat] ?? [];
    final l2 = m2[mat] ?? [];
    if (!l1.equals(l2)) {
      return false;
    }
  }
  return true;
}

/// [Colloscope] est la représentation en mémoire vive
/// d'un colloscope.
/// Il peut être enregistré (au format JSON), et affiché
/// sous différente formes (par matière, par semaine, par élève)
class Colloscope {
  final Map<MatiereID, _Creneaux> _matieres;

  final List<Groupe> groupes;

  CreneauHoraireProvider creneauxHoraires;
  MatiereProvider matieresList;

  /// [notes] est un champ de texte libre.
  String notes;

  Colloscope(this._matieres, this.groupes,
      {this.notes = "",
      this.creneauxHoraires = defautHoraires,
      this.matieresList = defautMatieres}) {
    matieresList = defautMatieres;
    assert(_matieres.values.every(
        (element) => element.isSorted((a, b) => a.date.compareTo(b.date))));

    final gm = _groupeMap;
    assert(_matieres.values.every((l) =>
        l.every((cr) => cr.groupeID == null || gm.containsKey(cr.groupeID))));

    assert(List.generate(matieresList.values.length,
        (index) => index == matieresList.values[index].index).every((e) => e));
    final mm = _matiereMap;
    assert(_matieres.keys.every((id) => mm.containsKey(id)));
  }

  Colloscope copy() {
    return Colloscope(
      _matieres.map((k, v) => MapEntry(k, v.map((e) => e.copy()).toList())),
      groupes.map((e) => e).toList(),
      creneauxHoraires: creneauxHoraires.copy(),
      matieresList: matieresList.copy(),
      notes: notes,
    );
  }

  bool isEqual(Colloscope other) =>
      areMatieresEqual(other._matieres, _matieres) &&
      other.groupes.equals(groupes) &&
      other.creneauxHoraires.equals(creneauxHoraires) &&
      other.matieresList.equals(matieresList) &&
      other.notes == notes;

  Map<String, dynamic> toJson() {
    return {
      "matieres": _matieres.map(
          (k, v) => MapEntry(k.toString(), v.map((e) => e.toJson()).toList())),
      "groupes": groupes.map((e) => e.toJson()).toList(),
      "creneauxHoraires": creneauxHoraires.toJson(),
      "matieresList": matieresList.toJson(),
      "notes": notes,
    };
  }

  factory Colloscope.fromJson(Map<String, dynamic> json) {
    return Colloscope(
        (json["matieres"] as Map).map((k, v) => MapEntry(
              int.parse(k as String),
              (v as List).map((cr) => _PopulatedCreneau.fromJson(cr)).toList(),
            )),
        ((json["groupes"] ?? []) as List)
            .map((e) => Groupe.fromJson(e))
            .toList(),
        creneauxHoraires: json["creneauxHoraires"] == null
            ? defautHoraires
            : CreneauHoraireProvider.fromJson(json["creneauxHoraires"]),
        matieresList: json["matieresList"] == null
            ? defautMatieres
            : MatiereProvider.fromJson(json["matieresList"]),
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

  Map get _groupeMap => Map.fromEntries(groupes.map((e) => MapEntry(e.id, e)));
  Map get _matiereMap =>
      Map.fromEntries(matieresList.values.map((e) => MapEntry(e.index, e)));

  /// [parSemaine] trie les colles par semaine et renvoie une liste
  /// contigue de semaines
  List<SemaineTo<VueSemaine>> parSemaine() {
    final matiereMap = _matiereMap;
    final groupeMap = _groupeMap;
    final semaines = <int, Map<MatiereID, List<PopulatedCreneau>>>{};
    for (var item in _matieres.entries) {
      final matiere = item.key;
      for (var creneauIndex = 0;
          creneauIndex < item.value.length;
          creneauIndex++) {
        final creneau = item.value[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => {});
        final groupesParMatiere = semaine.putIfAbsent(matiere, () => []);
        groupesParMatiere.add(PopulatedCreneau(creneauIndex, creneau.date,
            groupeMap[creneau.groupeID], creneau.colleur, matiereMap[matiere]));
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
        semaine.add(Colle(cr.date, matieresList.values[matiere], cr.colleur));
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

  Map<MatiereID, VueMatiere> parMatiere() {
    final matiereMap = _matiereMap;
    final groupeMap = _groupeMap;

    return _matieres.map((matiere, creneaux) {
      final semaines = <int, List<PopulatedCreneau>>{};
      for (var creneauIndex = 0;
          creneauIndex < creneaux.length;
          creneauIndex++) {
        final creneau = creneaux[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => []);
        semaine.add(PopulatedCreneau(creneauIndex, creneau.date,
            groupeMap[creneau.groupeID], creneau.colleur, matiereMap[matiere]));
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
      for (var creneau in l.where((cr) => cr.groupeID == id)) {
        creneau.groupeID = null;
      }
    }
  }

  /// [addCreneaux] ajoute les heures données comme non
  /// affectées, dupliquant et adaptant la liste pour chaque semaine
  /// demandée
  void addCreneaux(MatiereID mat, List<DateHeure> semaineHours,
      List<int> semaines, String colleur) {
    List<_PopulatedCreneau> finalTimes = [];
    for (var semaine in semaines) {
      for (var time in semaineHours) {
        final adjusted =
            DateHeure(semaine, time.weekday, time.hour, time.minute);
        finalTimes.add(_PopulatedCreneau(adjusted, null, colleur));
      }
    }

    // add into NoGroup
    final l = _matieres.putIfAbsent(mat, () => []);
    l.addAll(finalTimes);
    l.sort((a, b) =>
        a.date.compareTo(b.date)); // make sure sort invariant is preserved
  }

  /// [deleteCreneau] supprime le creneau pour tous les groupes
  void deleteCreneau(MatiereID mat, int creneauIndex) {
    final l = _matieres[mat] ?? [];
    l.removeAt(creneauIndex);
  }

  /// [deleteSemaine] supprime la semaine pour tous les groupes
  void deleteSemaine(MatiereID mat, int semaine) {
    final l = _matieres[mat] ?? [];
    l.removeWhere((cr) => cr.date.semaine == semaine);
  }

  /// toogleCreneau change l'état du créneau donné
  void toogleCreneau(GroupeID groupe, MatiereID mat, int creneauIndex) {
    final l = _matieres[mat] ?? [];
    final cr = l[creneauIndex];
    cr.groupeID = cr.groupeID == null ? groupe : null;
  }

  void editCreneauColleur(MatiereID mat, int creneauIndex, String colleur) {
    final l = _matieres[mat] ?? [];
    final cr = l[creneauIndex];
    cr.colleur = colleur;
  }

  /// [attribueCyclique] attribue les créneaux des semaines donnés aux
  /// groupes donnés.
  /// Pour simplifier, on suppose que le nombre de groupes correspond au nombre
  /// de créneaux disponibles.
  void attribueCyclique(MatiereID matiere, List<GroupeID> groupes,
      List<int> semaines, bool usePermuation) {
    var permutatioOffset = 0;
    final creneaux = _matieres[matiere] ?? [];
    for (var semaineIndex in semaines) {
      final creneauxSemaine = creneaux
          .where((cr) => cr.date.semaine == semaineIndex && cr.groupeID == null)
          .toList();

      final L = creneauxSemaine.length;
      assert(L == groupes.length);
      for (var i = 0; i < L; i++) {
        final groupe = groupes[(permutatioOffset + i) % L];
        creneauxSemaine[i].groupeID = groupe;
      }

      // apply the permutation if needed
      if (usePermuation) {
        permutatioOffset++;
      }
    }
  }

  /// [repeteMotifCourant] repete [nombre] fois l'organisation courante,
  /// pour la [matiere] donnée.
  void repeteMotifCourant(MatiereID matiere, int nombre, {int? periode}) {
    final l = _matieres[matiere] ?? [];
    periode = periode ?? l.map((cr) => cr.date.semaine).fold<int>(0, max);
    if (periode <= 0) {
      return;
    }
    final pattern = l.map((e) => e).toList(); // copy to avoid side effects
    for (var periodOffset = 1; periodOffset <= nombre; periodOffset++) {
      l.addAll(pattern.map(
          (cr) => cr._copyWithWeek(cr.date.semaine + periodOffset * periode!)));
    }
  }
}

// ---------------------------------------------------------

class Colle {
  final DateHeure date;
  final Matiere matiere;
  final String colleur;
  const Colle(this.date, this.matiere, this.colleur);
}

typedef VueGroupe = List<SemaineTo<List<Colle>>>; // semaines => colles

typedef VueSemaine = Map<MatiereID, List<PopulatedCreneau>>;

/// les créneaux sont triés par date, et peuvent
/// etre identifiés par index pour gérer les doublons
typedef _Creneaux = List<_PopulatedCreneau>;

typedef VueMatiere = List<SemaineTo<List<PopulatedCreneau>>>;

class _PopulatedCreneau {
  final DateHeure date;
  GroupeID? groupeID;
  String colleur;
  final String notes;

  _PopulatedCreneau(this.date, this.groupeID, this.colleur, {this.notes = ""});

  _PopulatedCreneau copy() {
    return _PopulatedCreneau(date, groupeID, colleur, notes: notes);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toJson(),
      "groupeID": groupeID,
      "colleur": colleur,
      "notes": notes,
    };
  }

  factory _PopulatedCreneau.fromJson(Map<String, dynamic> json) {
    return _PopulatedCreneau(DateHeure.fromJson(json["date"]), json["groupeID"],
        json["colleur"] ?? "",
        notes: json["notes"] ?? "");
  }

  @override
  bool operator ==(Object other) =>
      other is _PopulatedCreneau &&
      other.runtimeType == runtimeType &&
      other.date == date &&
      other.groupeID == groupeID &&
      other.colleur == colleur &&
      other.notes == notes;

  @override
  int get hashCode =>
      date.hashCode + groupeID.hashCode + colleur.hashCode + notes.hashCode;

  _PopulatedCreneau _copyWithWeek(int semaine) {
    return _PopulatedCreneau(
        DateHeure(semaine, date.weekday, date.hour, date.minute),
        groupeID,
        colleur,
        notes: notes);
  }
}

class PopulatedCreneau {
  /// [index] est l'identifiant unique d'un créneau dans la
  /// liste définie par une matière
  final int index;
  final DateHeure date;
  final Groupe? groupe;
  final String colleur;
  final Matiere matiere;

  const PopulatedCreneau(
      this.index, this.date, this.groupe, this.colleur, this.matiere);

  Colle toColle(Matiere matiere) => Colle(date, matiere, colleur);
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
