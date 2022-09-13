import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kolir/logic/rotations.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

typedef Collisions = Map<DateHeure, List<Matiere>>;

class Chevauchement {
  final Colle debut;
  final Colle fin;
  const Chevauchement(this.debut, this.fin);
}

/// [Diagnostic] indique les problèmes de la répartition courante,
/// pour un groupe.
class Diagnostic {
  /// (au moins) deux créneaux en même temps.
  final Collisions collisions;

  final List<Chevauchement> chevauchements;

  /// les colles ne respectant pas les contraintes de créneau
  /// du groupe
  final List<Colle> contraintes;

  /// index des semaines en surcharges
  final List<int> semainesChargees;

  /// les matières pour lesquelles le nombre de colle par groupe
  /// n'est pas constant (ou nul)
  final List<Matiere> matiereNonEquilibrees;

  const Diagnostic(
    this.collisions,
    this.chevauchements,
    this.contraintes,
    this.semainesChargees,
    this.matiereNonEquilibrees,
  );
}

bool _areMatieresEqual(
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
      groupes.toList(),
      creneauxHoraires: creneauxHoraires.copy(),
      matieresList: matieresList.copy(),
      notes: notes,
    );
  }

  bool isEqual(Colloscope other) =>
      _areMatieresEqual(other._matieres, _matieres) &&
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

  Map<GroupeID, Groupe> get _groupeMap => groupeMap(groupes);
  Map<MatiereID, Matiere> get _matiereMap =>
      Map.fromEntries(matieresList.values.map((e) => MapEntry(e.index, e)));

  PopulatedCreneau _publy(
      MatiereID matiere, int creneauIndex, _PopulatedCreneau creneau) {
    return PopulatedCreneau(creneauIndex, creneau.date,
        _groupeMap[creneau.groupeID], creneau.colleur, _matiereMap[matiere]!);
  }

  /// [parSemaine] trie les colles par semaine et renvoie une liste
  /// contigue de semaines
  List<SemaineTo<VueSemaine>> parSemaine() {
    final semaines = <int, Map<MatiereID, List<PopulatedCreneau>>>{};
    for (var item in _matieres.entries) {
      final matiere = item.key;
      for (var creneauIndex = 0;
          creneauIndex < item.value.length;
          creneauIndex++) {
        final creneau = item.value[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => {});
        final groupesParMatiere = semaine.putIfAbsent(matiere, () => []);
        groupesParMatiere.add(_publy(matiere, creneauIndex, creneau));
      }
    }
    return _semaineMapToList(semaines);
  }

  Map<GroupeID, List<DateHeure>> _parGroupes() {
    final out = <GroupeID, List<DateHeure>>{};
    for (var element in _matieres.entries) {
      for (var creneauIndex = 0;
          creneauIndex < element.value.length;
          creneauIndex++) {
        final creneau = element.value[creneauIndex];
        if (creneau.groupeID == null) {
          continue;
        }
        final l = out.putIfAbsent(creneau.groupeID!, () => []);
        l.add(creneau.date);
      }
    }
    return out;
  }

  VueGroupe _groupeSemaines(GroupeID groupe) {
    final semaines = <int, List<Colle>>{};
    for (var element in _matieres.entries) {
      final matiere = element.key;
      for (var creneauIndex = 0;
          creneauIndex < element.value.length;
          creneauIndex++) {
        final cr = element.value[creneauIndex];
        if (cr.groupeID == groupe) {
          final semaine = semaines.putIfAbsent(cr.date.semaine, () => []);
          semaine.add(Colle(
              creneauIndex, cr.date, matieresList.values[matiere], cr.colleur));
        }
      }
    }
    for (var l in semaines.values) {
      l.sort((a, b) => a.matiere.index - b.matiere.index);
    }
    return _semaineMapToList(semaines);
  }

  /// [creneaux] renvoit les créneaux utilisés, ramenés sur une semaine,
  /// et classéss par jour de la semaine puis par heure
  Map<int, List<List<Colle>>> creneaux() {
    final out = <int, Set<WeeklyCreneauID>>{};
    final mm = _matiereMap;
    for (var entry in _matieres.entries) {
      final matiereID = entry.key;
      for (var creneau in entry.value) {
        final set = out.putIfAbsent(creneau.date.weekday, () => {});
        final key = WeeklyCreneauID(
            matiereID, creneau.date.hour, creneau.date.minute, creneau.colleur);
        set.add(key);
      }
    }
    return out.map((key, value) {
      final l = value
          .map((e) => Colle(-1, DateHeure(1, key, e.hour, e.minute),
              mm[e.matiereID]!, e.colleur))
          .toList();
      l.sort((a, b) => a.date.compareTo(b.date));
      final byDateHeure = l.groupListsBy((colle) => colle.date).values.toList();
      return MapEntry(key, byDateHeure);
    });
  }

  /// les créneaux non attribués sont ignorés
  Map<GroupeID, VueGroupe> parGroupe() {
    return Map.fromEntries(
        groupes.map((k) => MapEntry(k.id, _groupeSemaines(k.id))));
  }

  Map<MatiereID, VueMatiere> parMatiere() {
    return _matieres.map((matiere, creneaux) {
      final semaines = <int, List<PopulatedCreneau>>{};
      for (var creneauIndex = 0;
          creneauIndex < creneaux.length;
          creneauIndex++) {
        final creneau = creneaux[creneauIndex];
        final semaine = semaines.putIfAbsent(creneau.date.semaine, () => []);
        semaine.add(_publy(matiere, creneauIndex, creneau));
      }
      // creneaux is already sorted
      return MapEntry(matiere, _semaineMapToList(semaines));
    });
  }

  /// [diagnostics] renvoie une liste de groupes posant problème.
  /// Un colloscope valide devrait renvoyer une liste vide.
  Map<GroupeID, Diagnostic> diagnostics() {
    final Map<GroupeID, Diagnostic> out = {};
    final gm = _groupeMap;
    final mm = _matiereMap;

    // contrainte d'équilibre
    final equilibriumFailed = <GroupeID, List<Matiere>>{};
    for (var item in _matieres.entries) {
      final matiere = item.key;
      // calcule le nombre de colle par groupe
      final parGroupe = <GroupeID, int>{};
      for (var cr in item.value) {
        if (cr.groupeID == null) continue;
        parGroupe[cr.groupeID!] = (parGroupe[cr.groupeID] ?? 0) + 1;
      }
      // on accepte soit 0, soit un nombre commun
      if (parGroupe.values.toSet().length != 1) {
        for (var groupe in parGroupe.keys) {
          final l = equilibriumFailed.putIfAbsent(groupe, () => []);
          l.add(mm[matiere]!);
        }
      }
    }

    for (var item in parGroupe().entries) {
      final group = item.key;
      final parSemaine = item.value;

      // collisions directes
      final parCreneau = <DateHeure, List<Matiere>>{};
      for (var semaine in parSemaine) {
        for (var cr in semaine.item) {
          final l = parCreneau.putIfAbsent(cr.date, () => []);
          l.add(cr.matiere);
        }
      }
      final collisions =
          parCreneau.entries.where((element) => element.value.length > 1);

      final List<Chevauchement> chevauchements = [];
      // chevauchement pour les matières plus longues
      for (var semaine in parSemaine) {
        // sort by time
        semaine.item.sort((a, b) => a.date.compareTo(b.date));
        for (var i = 0; i < semaine.item.length; i++) {
          if (i == semaine.item.length - 1) {
            break;
          }
          final courant = semaine.item[i];
          final suivant = semaine.item[i + 1];
          final duree = courant.matiere.colleDuree;
          if (courant.date
              .toDateTime()
              .add(Duration(minutes: duree))
              .isAfter(suivant.date.toDateTime())) {
            chevauchements.add(Chevauchement(courant, suivant));
          }
        }
      }

      // contraintes de créneaux
      final cs = gm[group]!.constraintsSet();
      final contraintes = parSemaine
          .map((s) =>
              s.item.where((colle) => cs.contains(colle.date.copyWithWeek(1))))
          .fold(<Colle>[], (pr, el) => [...pr, ...el]);

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

      final equilibrium = equilibriumFailed[group] ?? [];
      if (collisions.isNotEmpty ||
          semainesChargees.isNotEmpty ||
          chevauchements.isNotEmpty ||
          contraintes.isNotEmpty ||
          equilibrium.isNotEmpty) {
        out[group] = Diagnostic(Collisions.fromEntries(collisions),
            chevauchements, contraintes, semainesChargees, equilibrium);
      }
    }
    return out;
  }

  /// [nbCreneauxVaccants] renvoie le nombre de créneaux définis mais non
  /// attribués à un groupe
  int nbCreneauxVaccants() {
    if (_matieres.isEmpty) return 0;
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
    clearGroupeCreneaux(id);
  }

  /// clearGroupeCreneaux desaffecte les créneaux de [id]
  void clearGroupeCreneaux(GroupeID id) {
    for (var l in _matieres.values) {
      for (var creneau in l.where((cr) => cr.groupeID == id)) {
        creneau.groupeID = null;
      }
    }
  }

  void updateGroupeContraintes(GroupeID id, List<DateHeure> contraintes) {
    final index = groupes.indexWhere((element) => element.id == id);
    groupes[index] = Groupe(id, creneauxInterdits: contraintes);
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

  /// [setupAttribueAuto] prépare l'attribution des créneaux donnés,
  /// ou renvoit une erreur si les créneaux sont incompatibles avec l'occupation courante.
  Maybe<RotationSelector> setupAttribueAuto(MatiereID matiere,
      List<GroupeID> selectedGroupes, List<int> semaines, int periode) {
    final backupArray = (_matieres[matiere] ?? []);
    final creneaux = List<PopulatedCreneau>.generate(
        backupArray.length,
        (creneauIndex) =>
            _publy(matiere, creneauIndex, backupArray[creneauIndex]));

    semaines.sort();
    final parSemaine = semaines
        .map((si) => SemaineTo(
            si, creneaux.where((cr) => cr.date.semaine == si).toList()))
        .toList();
    final groupes = selectedGroupes.map((e) => _groupeMap[e]!).toList();

    return setupRotations(matiere, parSemaine, groupes, _parGroupes(), periode);
  }

  /// [attribueAuto] effectue la sélection de la meilleur répartition
  void attribueAuto(SelectedRotation res) {
    final backupArray = (_matieres[res.matiere] ?? []);

    // apply the selected permutations
    for (var semaineIndex = 0;
        semaineIndex < res.rotation.length;
        semaineIndex++) {
      final crs = res.creneauxParSemaine[semaineIndex].item;
      final perm = res.rotation[semaineIndex];
      for (var i = 0; i < crs.length; i++) {
        final backupIndex = crs[i].index;
        backupArray[backupIndex].groupeID = perm[i];
      }
    }
  }

  /// [repeteMotifCourant] repete [nombre] fois l'organisation courante,
  /// pour la [matiere] donnée, sans copier les attributions.
  void repeteMotifCourant(MatiereID matiere, int nombre, {int? periode}) {
    final l = _matieres[matiere] ?? [];
    periode = periode ?? l.map((cr) => cr.date.semaine).fold<int>(0, max);
    if (periode <= 0) {
      return;
    }
    final pattern = l
        .map((e) => _PopulatedCreneau(e.date, null, e.colleur))
        .toList(); // copy to avoid side effects
    for (var periodOffset = 1; periodOffset <= nombre; periodOffset++) {
      l.addAll(pattern.map(
          (cr) => cr._copyWithWeek(cr.date.semaine + periodOffset * periode!)));
    }
  }

  /// [permuteCreneauxGroupe] échange les assignations des groupes pour les créneaux données
  void permuteCreneauxGroupe(CreneauID src, CreneauID dst) {
    final srcC = _matieres[src.matiere]![src.index];
    final dstC = _matieres[dst.matiere]![dst.index];
    final tmp = srcC.groupeID;
    srcC.groupeID = dstC.groupeID;
    dstC.groupeID = tmp;
  }

  /// [clearMatiere] désaffecte tous les créneaux de [matiereID]
  void clearMatiere(MatiereID matiereID) {
    for (var cr in (_matieres[matiereID] ?? <_PopulatedCreneau>[])) {
      cr.groupeID = null;
    }
  }
}

class CreneauID {
  final MatiereID matiere;
  final int index;
  const CreneauID(this.matiere, this.index);
}

class WeeklyCreneauID {
  final MatiereID matiereID;
  final int hour;
  final int minute;
  final String colleur;
  const WeeklyCreneauID(this.matiereID, this.hour, this.minute, this.colleur);

  @override
  bool operator ==(Object other) =>
      other is WeeklyCreneauID &&
      other.runtimeType == runtimeType &&
      other.matiereID == matiereID &&
      other.hour == hour &&
      other.minute == minute &&
      other.colleur == colleur;

  @override
  int get hashCode =>
      matiereID.hashCode + hour.hashCode + minute.hashCode + colleur.hashCode;
}

class Colle {
  final int creneauxIndex;
  final DateHeure date;
  final Matiere matiere;
  final String colleur;
  const Colle(this.creneauxIndex, this.date, this.matiere, this.colleur);
}

typedef VueGroupe = List<SemaineTo<List<Colle>>>; // semaines => colles

typedef VueSemaine = Map<MatiereID, List<PopulatedCreneau>>;

/// les créneaux sont triés par date, et peuvent
/// etre identifiés par index pour gérer les doublons
typedef _Creneaux = List<_PopulatedCreneau>;

typedef Creneaux = List<SemaineTo<List<PopulatedCreneau>>>;

typedef VueMatiere = Creneaux;

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
    return _PopulatedCreneau(date.copyWithWeek(semaine), groupeID, colleur,
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

  Colle toColle(Matiere matiere) => Colle(index, date, matiere, colleur);

  CreneauID get id => CreneauID(matiere.index, index);
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
