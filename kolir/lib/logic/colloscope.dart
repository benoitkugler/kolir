import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// NoGroup est une valeur spéciale utilisée pour
/// les créneaux non prévus mais non attribués à un groupe.
const NoGroup = "";

/// [Colloscope] est la représentation en mémoire vive
/// d'un colloscope.
/// Il peut être enregistré (au format JSON), et affiché
/// sous différente formes (par matière, par semaine, par élève)
class Colloscope {
  /// les groupes sont identifiés par leur index
  Map<GroupeID, HeuresGroupe> groupes;

  /// date du lundi de la premiere semaine (Semaine 1)
  DateTime debut;

  Colloscope(this.groupes, this.debut) {
    assert(groupes.values.every((element) =>
        element.values.every((dts) => dts.every((dt) => dt.isAfter(debut)))));

    assert(debut.weekday == DateTime.monday);
    assert(debut.hour == 0);
    assert(debut.minute == 0);
    assert(debut.second == 0);
  }

  Map<String, dynamic> toJson() {
    return {
      "groupes": groupes.map((k, v) => MapEntry(k, v.toJson())),
      "debut": debut.toIso8601String(),
    };
  }

  factory Colloscope.fromJson(Map<String, dynamic> json) {
    return Colloscope(
      (json["groupes"] as Map).map((k, v) => MapEntry(k, HG.fromJson(v))),
      DateTime.parse(json["debut"]),
    );
  }

  static Future<File> get _saveFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/kolir.json';
    return File(path);
  }

  Future<String> save() async {
    final file = await _saveFile;
    await file.writeAsString(jsonEncode(toJson()));
    return file.path;
  }

  factory Colloscope.empty() {
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    now = now.subtract(Duration(days: now.weekday - 1));
    return Colloscope({}, now);
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

  /// [week] renvoie l'index de la semaine par rapport à debut :
  /// ```week(debut) == 0```
  int week(DateTime date) {
    return date.difference(debut).inDays ~/ 7; // starting at zero
  }

  /// [parSemaine] trie les colles par semaine et renvoie une liste
  /// contigue de semaines
  List<VueSemaine> parSemaine() {
    final semaines = <int, VueSemaine>{};
    for (var groupeEntry in groupes.entries) {
      final groupe = groupeEntry.value;
      for (var element in groupe.entries) {
        final matiere = element.key;
        for (var date in element.value) {
          final weekIndex = week(date);
          final semaine = semaines.putIfAbsent(weekIndex, () => {});
          final groupesParMatiere = semaine.putIfAbsent(matiere, () => []);
          groupesParMatiere.add(groupeEntry.key);
        }
      }
    }
    return _semaineMapToList(semaines, {});
  }

  /// les créneaux non attribués sont ignorés
  Map<GroupeID, VueGroupe> parGroupe() {
    final out = groupes.map((k, e) {
      final semaines = <int, List<Colle>>{};
      for (var element in e.entries) {
        final matiere = element.key;
        for (var date in element.value) {
          final weekIndex = week(date);
          final semaine = semaines.putIfAbsent(weekIndex, () => []);
          semaine.add(Colle(date, matiere));
        }
      }
      return MapEntry(k, _semaineMapToList(semaines, <Colle>[]));
    });
    out.remove(NoGroup);
    return out;
  }

  Map<Matiere, VueMatiere> parMatiere() {
    final tmp = <Matiere, Map<int, List<PopulatedCreneau>>>{};
    for (var groupItem in groupes.entries) {
      for (var item in groupItem.value.entries) {
        final matiere = item.key;
        final semaines = tmp.putIfAbsent(matiere, () => {});
        for (var date in item.value) {
          final weekIndex = week(date);
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

  void reset() {
    groupes = {};
  }

  void addGroupe() {
    int serial = groupes.length + 1;
    if (groupes.containsKey(NoGroup)) {
      serial -= 1;
    }
    String id = "Groupe $serial";
    while (groupes.containsKey(id)) {
      serial += 1;
      id = "Groupe $serial";
    }
    groupes[id] = {};
  }

  /// removeGroupe supprime le groupe donné
  /// les créneaux liés ne sont pas supprimés
  void removeGroupe(GroupeID id) {
    final group = groupes.remove(id);
    if (group == null) {
      return;
    }

    // ajoute les créneaux à NoGroup
    final nogroup = groupes.putIfAbsent(NoGroup, () => {});
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
    final l = groupes.putIfAbsent(NoGroup, () => {});
    final lmat = l.putIfAbsent(mat, () => []);
    lmat.addAll(finalTimes);
  }

  /// removeCreneau supprime le creneau pour tous les groupes
  void removeCreneau(Matiere mat, DateTime creneau) {
    for (var groupe in groupes.values) {
      final l = groupe[mat] ?? [];
      l.remove(creneau);
    }
  }

  /// attributeCreneau assigne le créneau donné au groupe donné,
  /// retirant le groupe précédent si nécessaire
  void attributeCreneau(Matiere mat, GroupeID origin, PopulatedCreneau dst) {
    final group = groupes.putIfAbsent(origin, () => {});
    final matList = group.putIfAbsent(mat, () => []);
    matList.add(dst.date);

    // cleanup the given creneau
    final oldGroup = groupes[dst.groupeID] ?? {};
    final oldMatList = oldGroup[mat] ?? [];
    oldMatList.remove(dst.date);
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

typedef VueSemaine = Map<Matiere, List<GroupeID>>;

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
