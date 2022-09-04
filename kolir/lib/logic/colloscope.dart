import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:kolir/logic/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// NoGroup est une valeur spéciale utilisée pour
/// les créneaux non prévus mais non attribués à un groupe.
const NoGroup = "";

typedef Collisions = Map<GroupeID, Map<DateTime, List<Matiere>>>;

/// [Colloscope] est la représentation en mémoire vive
/// d'un colloscope.
/// Il peut être enregistré (au format JSON), et affiché
/// sous différente formes (par matière, par semaine, par élève)
class Colloscope {
  /// les groupes sont identifiés par leur index
  Map<GroupeID, HeuresGroupe> _groupes;

  /// date du lundi de la premiere semaine (Semaine 1)
  DateTime debut;

  /// premiereSemaine est le numéro externe de la première semaine interne
  /// (indexée par 0)
  int premiereSemaine;

  /// [notes] est un champ de texte libre.
  String notes;

  Colloscope(this._groupes, this.debut,
      {this.premiereSemaine = 1, this.notes = ""}) {
    assert(premiereSemaine >= 1);

    assert(_groupes.values.every((element) =>
        element.values.every((dts) => dts.every((dt) => dt.isAfter(debut)))));

    assert(debut.weekday == DateTime.monday);
    assert(debut.hour == 0);
    assert(debut.minute == 0);
    assert(debut.second == 0);
  }

  factory Colloscope.empty() {
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day); // remove hour, minutes, ...
    now = now.subtract(Duration(days: now.weekday - 1)); // shift to monday
    return Colloscope({}, now);
  }

  Map<String, dynamic> toJson() {
    return {
      "groupes": _groupes.map((k, v) => MapEntry(k, v.toJson())),
      "debut": debut.toIso8601String(),
      "premiereSemaine": premiereSemaine,
      "notes": notes,
    };
  }

  factory Colloscope.fromJson(Map<String, dynamic> json) {
    return Colloscope(
        (json["groupes"] as Map).map((k, v) => MapEntry(k, HG.fromJson(v))),
        DateTime.parse(json["debut"]),
        premiereSemaine: (json["premiereSemaine"] ?? 1) as int,
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
      return Colloscope.empty();
    }

    // Read the file
    final contents = await file.readAsString();

    return Colloscope.fromJson(jsonDecode(contents));
  }

  /// [_week] renvoie l'index de la semaine par rapport à debut :
  /// ```week(debut) == 0```
  int _week(DateTime date) {
    return date.difference(debut).inDays ~/ 7; // starting at zero
  }

  /// [parSemaine] trie les colles par semaine et renvoie une liste
  /// contigue de semaines
  List<VueSemaine> parSemaine() {
    final semaines = <int, VueSemaine>{};
    for (var groupeEntry in _groupes.entries) {
      final groupe = groupeEntry.value;
      for (var element in groupe.entries) {
        final matiere = element.key;
        for (var date in element.value) {
          final weekIndex = _week(date);
          final semaine = semaines.putIfAbsent(weekIndex, () => {});
          final groupesParMatiere = semaine.putIfAbsent(matiere, () => []);
          groupesParMatiere.add(PopulatedCreneau(date, groupeEntry.key));
        }
      }
    }
    return _semaineMapToList(semaines, {});
  }

  /// les créneaux non attribués sont ignorés
  Map<GroupeID, VueGroupe> parGroupe() {
    final out = _groupes.map((k, e) {
      final semaines = <int, List<Colle>>{};
      for (var element in e.entries) {
        final matiere = element.key;
        for (var date in element.value) {
          final weekIndex = _week(date);
          final semaine = semaines.putIfAbsent(weekIndex, () => []);
          semaine.add(Colle(date, matiere));
        }
      }
      for (var l in semaines.values) {
        l.sort((a, b) => a.matiere.index - b.matiere.index);
      }
      return MapEntry(k, _semaineMapToList(semaines, <Colle>[]));
    });
    out.remove(NoGroup);
    return out;
  }

  Map<Matiere, VueMatiere> parMatiere() {
    final tmp = <Matiere, Map<int, List<PopulatedCreneau>>>{};
    for (var groupItem in _groupes.entries) {
      for (var item in groupItem.value.entries) {
        final matiere = item.key;
        final semaines = tmp.putIfAbsent(matiere, () => {});
        for (var date in item.value) {
          final weekIndex = _week(date);
          final semaine = semaines.putIfAbsent(weekIndex, () => []);
          semaine.add(PopulatedCreneau(date, groupItem.key));
        }
      }
    }
    for (var m in tmp.values) {
      for (var l in m.values) {
        l.sort((a, b) => a.date.compareTo(b.date));
      }
    }
    return Map<Matiere, VueMatiere>.fromEntries(Matiere.values
        .map((e) => MapEntry(e, _semaineMapToList(tmp[e] ?? {}, []))));
  }

  /// [checkDoublePresence] renvoie une liste de groupes assitant à (au moins) deux créneaux
  /// en même temps. Un colloscope valide devrait renvoyer une liste vide.
  Collisions checkDoublePresence() {
    final Collisions out = {};
    for (var item in _groupes.entries) {
      final group = item.key;
      if (group == NoGroup) {
        continue;
      }
      final parCreneau = <DateTime, List<Matiere>>{};
      for (var mat in item.value.entries) {
        for (var date in mat.value) {
          final l = parCreneau.putIfAbsent(date, () => []);
          l.add(mat.key);
        }
      }
      final problemes =
          parCreneau.entries.where((element) => element.value.length > 1);
      if (problemes.isNotEmpty) {
        out[group] = Map.fromEntries(problemes);
      }
    }
    return out;
  }

  void reset() {
    _groupes = {};
  }

  void addGroupe() {
    int serial = _groupes.length + 1;
    if (_groupes.containsKey(NoGroup)) {
      serial -= 1;
    }
    String id = "G$serial";
    while (_groupes.containsKey(id)) {
      serial += 1;
      id = "G$serial";
    }
    _groupes[id] = {};
  }

  /// removeGroupe supprime le groupe donné
  /// les créneaux liés ne sont pas supprimés
  void removeGroupe(GroupeID id) {
    final group = _groupes.remove(id);
    if (group == null) {
      return;
    }

    // ajoute les créneaux à NoGroup
    final nogroup = _groupes.putIfAbsent(NoGroup, () => {});
    for (var entry in group.entries) {
      final matiere = entry.key;
      final l = nogroup.putIfAbsent(matiere, () => []);
      l.addAll(entry.value);
    }
  }

  /// [addCreneaux] ajoute les heures données comme non
  /// affectées, dupliquant et adaptant la liste pour chaque semaine
  /// demandée
  void addCreneaux(
      Matiere mat, List<DateTime> semaineHours, List<int> semaines) {
    List<DateTime> finalTimes = [];
    for (var semaine in semaines) {
      final offset = Duration(days: 7 * (semaine - 1));
      final lundi = debut.add(offset);
      for (var time in semaineHours) {
        final dur = Duration(
            days: (time.weekday - 1), hours: time.hour, minutes: time.minute);
        finalTimes.add(lundi.add(dur));
      }
    }

    // add into NoGroup
    final l = _groupes.putIfAbsent(NoGroup, () => {});
    final lmat = l.putIfAbsent(mat, () => []);
    lmat.addAll(finalTimes);
  }

  /// removeCreneau supprime le creneau pour tous les groupes
  void removeCreneau(Matiere mat, DateTime creneau) {
    for (var groupe in _groupes.values) {
      final l = groupe[mat] ?? [];
      l.remove(creneau);
    }
  }

  /// attributeCreneau assigne le créneau [dst] au groupe [src],
  /// inversant les affectations précédentes
  void attributeCreneau(
      Matiere mat, PopulatedCreneau src, PopulatedCreneau dst) {
    final srcGroup = _groupes.putIfAbsent(src.groupeID, () => {});
    final srcMatList = srcGroup.putIfAbsent(mat, () => []);
    if (!isEmptyDate(src.date)) {
      srcMatList.remove(src.date);
    }
    srcMatList.add(dst.date);

    // dst.groupID may be NoGroup
    final dstGroup = _groupes.putIfAbsent(dst.groupeID, () => {});
    final dstMatList = dstGroup.putIfAbsent(mat, () => []);
    dstMatList.remove(dst.date);
    if (!isEmptyDate(src.date)) {
      dstMatList.add(src.date);
    }
  }

  /// [clearCreneaux] enlève les groupes prévus pour la semaine [semaine]
  /// et matière [mat]
  void clearCreneaux(Matiere mat, int semaine) {
    final noGroup = _groupes.putIfAbsent(NoGroup, () => {});
    final noGroupMap = noGroup.putIfAbsent(mat, () => []);
    for (var groupe in _groupes.entries) {
      if (groupe.key == NoGroup) {
        continue;
      }
      final l = groupe.value[mat] ?? [];
      final toRemove = l.where((dt) => _week(dt) == semaine).toList();
      l.removeWhere((dt) => _week(dt) == semaine);
      noGroupMap.addAll(toRemove);
    }
  }

  /// [attribueRegulier] remplie les créneaux disponibles dans la matière [mat]
  /// en commençant par [premierGroupe] -> [premierCreneau]
  void attribueRegulier(
      Matiere mat, GroupeID premierGroupe, DateTime premierCreneau) {
    final nogroup = _groupes[NoGroup] ?? {};
    final disponibles = nogroup.putIfAbsent(mat, () => []);
    disponibles.sort();
    var currentIndex = disponibles.indexOf(premierCreneau);
    if (currentIndex == -1) {
      return;
    }

    final groupes =
        _groupes.keys.where((element) => element != NoGroup).toList();
    groupes.sort();

    var currentGroupeIndex = groupes.indexOf(premierGroupe);
    if (currentGroupeIndex == -1) {
      return;
    }

    // to simplify, build the list of available creaneaux, starting at currentIndex
    final ordered = [
      ...disponibles.sublist(currentIndex),
      ...disponibles.sublist(0, currentIndex)
    ];
    for (var creneau in ordered) {
      final currentGroupe = groupes[currentGroupeIndex % groupes.length];
      final gr = _groupes.putIfAbsent(currentGroupe, () => {});
      final matList = gr.putIfAbsent(mat, () => []);
      matList.add(creneau);

      currentGroupeIndex += 1; // iterate in parallel
    }

    // clear the NoGroup group
    disponibles.clear();
  }
}

typedef GroupeID = String;

enum Matiere {
  maths,
  esh, // Eco
  anglais,
  allemand,
  espagnol,
  francais,
  philo;
}

/// [HeuresGroupe] donne les heures de colles d'un groupe,
/// pour toutes les matières
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
  final DateTime date;
  final Matiere matiere;
  const Colle(this.date, this.matiere);
}

typedef VueGroupe = List<List<Colle>>; // semaines => colles

/// [HeuresMatiereGroupe] donne les jours (et heures) pour un groupe,
/// et une matière
typedef HeuresMatiereGroupe = List<DateTime>;

extension HMG on HeuresMatiereGroupe {
  List<String> toJson() {
    return map((e) => e.toIso8601String()).toList();
  }

  static HeuresMatiereGroupe fromJson(List<dynamic> json) {
    return json.map((e) => DateTime.parse(e)).toList();
  }
}

typedef VueSemaine = Map<Matiere, List<PopulatedCreneau>>;

typedef VueMatiere = List<List<PopulatedCreneau>>; // semaine -> colle

class PopulatedCreneau {
  final DateTime date;
  final GroupeID groupeID;

  /// may be NoGroup
  const PopulatedCreneau(this.date, this.groupeID);
}

List<T> _semaineMapToList<T>(Map<int, T> semaines, T empty) {
  if (semaines.isEmpty) {
    return List<T>.empty();
  }
  final L = semaines.keys.reduce(max) + 1;
  return List<T>.generate(L, (index) => semaines[index] ?? empty);
}
