import 'package:collection/collection.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

/// [RotationParams] attribue les groupes donnés dans les créneaux
/// donnés, en appliquant autant que possible une permutation de semaine en semaine, et
/// en respectant les contraintes des groupes.
/// De plus, pour chaque semaine, un groupe apparait au plus une fois.
/// Pour simplifier, toutes les semaines doivent avoir le même nombre de créneaux.
/// De plus uniquement les contraintes de la première semaine sont prises en compte.
class RotationParams {
  final List<SemaineTo<List<PopulatedCreneau>>> creneauxParSemaine;
  final List<Groupe> groupes;

  /// [alreadyAttributed] is added to the groupe constraints
  final Map<GroupeID, List<DateHeure>> alreadyAttributed;

  RotationParams(
      this.creneauxParSemaine, this.groupes, this.alreadyAttributed) {
    assert(creneauxParSemaine.isNotEmpty);
    assert(creneauxParSemaine.map((e) => e.item.length).toSet().length == 1);
    assert(creneauxParSemaine.isSortedBy<num>((s) => s.semaine));
    assert(groupes.isNotEmpty);
  }

  /// prend en compte les contraintes appliquées à la première semaine
  /// et renvoie toutes les possibilités d'attribution
  List<Permutation>? _buildCandidates() {
    final firstWeek = creneauxParSemaine.first.item;
    final groupeCandidates = _applyConstraints(firstWeek);

    List<Permutation>? aux(int remainingLength) {
      if (remainingLength == 0) {
        return [[]];
      }
      final minus1s = aux(remainingLength - 1);
      if (minus1s == null) {
        return null;
      }

      final lastCandidates = groupeCandidates[remainingLength - 1];
      final out = <Permutation>[];
      for (var candidate in lastCandidates) {
        for (var minus1 in minus1s) {
          // maximum one groupe per week
          if (minus1.contains(candidate)) {
            continue;
          }
          final copy = minus1.toList(); // do no mutate minus1
          copy.add(candidate);
          out.add(copy);
        }
      }

      // if no candidate fit for the creneau
      if (out.isEmpty) {
        return null;
      }
      return out;
    }

    return aux(firstWeek.length);
  }

  // renvoie, pour chaque créneau, les groupes pouvant y assister
  List<List<GroupeID>> _applyConstraints(List<PopulatedCreneau> creneaux) {
    return creneaux
        .map((cr) => groupes
            .where(
                (gr) => !gr.constraintsSet().contains(cr.date.copyWithWeek(1)))
            .map((e) => e.id)
            .toList())
        .toList();
  }

  Iterable<Permutation> _iterFrom(int index, List<Permutation> candidates) {
    index = index % candidates.length;
    return candidates
        .getRange(index, candidates.length)
        .followedBy(candidates.getRange(0, index));
  }

  bool _canApplyCandidate(List<PopulatedCreneau> week, Permutation candidate) {
    assert(week.length == candidate.length);
    for (var i = 0; i < week.length; i++) {
      final date = week[i].date;
      final groupeID = candidate[i];
      if ((alreadyAttributed[groupeID] ?? []).contains(date)) {
        return false;
      }
    }
    return true;
  }

  MaybeRotations _buildRotation(Map<GroupeID, Groupe> gm,
      List<Permutation> candidates, bool usePermutation) {
    var lastChosenIndex = 0;
    final out = <Permutation>[];
    // try to apply the candidate perms to every week
    for (var semaine in creneauxParSemaine) {
      bool hasFoundCandidate = false;
      // start at the last index, and try every candidate
      for (var candidate in _iterFrom(lastChosenIndex, candidates)) {
        if (_canApplyCandidate(semaine.item, candidate)) {
          // Great !
          out.add(candidate);
          hasFoundCandidate = true;

          // apply the permutation if needed
          if (usePermutation) {
            lastChosenIndex++;
          }

          break;
        }
      }
      if (!hasFoundCandidate) {
        // no candidate match, return an error value
        return MaybeRotations([],
            "Aucune répartition pour la semaine ${semaine.semaine}. Candidats : \n${candidates.map((l) => l.map((id) => gm[id]!.name).join(', ')).join('\n')}");
      }
    }
    return MaybeRotations(out, "");
  }

  /// [getRotations] renvoie, pour chaque semaine, les groupes affectés
  /// aux créneaux de la semaine.
  /// Une erreur est retournée pour les cas pathologiques.
  MaybeRotations getRotations(int periode, bool usePermutation) {
    final gm = groupeMap(groupes);
    final candidates = _buildCandidates();

    if (candidates == null) {
      return const MaybeRotations([],
          "Les contraintes hedbomadaires des groupes ne peuvent être résolues.");
    }

    // try every permutation of the candidate, until one with equal repartition is found
    for (var permutatedCandidates in generatePermutations(candidates)) {
      final res = _buildRotation(gm, permutatedCandidates, usePermutation);
      if (res.error.isNotEmpty) {
        // by design, an error in one permutation will lead to error in all permutations
        return res;
      }
      if (res._hasEquilibrium() &&
          res._respectPeriode(periode, creneauxParSemaine)) {
        return res; // great !
      }
    }

    // default to non equilbirum
    return _buildRotation(gm, candidates, usePermutation);
  }
}

// représente l'attribution des créneaux de la semaine
typedef Permutation = List<GroupeID>;

class MaybeRotations {
  final List<Permutation> rotations;
  final String error;
  const MaybeRotations(this.rotations, this.error);

  bool _hasEquilibrium() {
    final byGroupes = <GroupeID, int>{};
    for (var perm in rotations) {
      for (var groupeID in perm) {
        byGroupes[groupeID] = (byGroupes[groupeID] ?? 0) + 1;
      }
    }
    return byGroupes.values.toSet().length == 1;
  }

  // verifie si, pour chaque groupes, les colles sont séparés
  // d'au plus periode - 1 semaine
  bool _respectPeriode<T>(int periode, List<SemaineTo<T>> creneauxParSemaine) {
    assert(rotations.length == creneauxParSemaine.length);

    final weeksByGroup = <GroupeID, List<int>>{};
    for (var i = 0; i < rotations.length; i++) {
      final perm = rotations[i];
      final semaine = creneauxParSemaine[i].semaine;
      for (var groupeID in perm) {
        final l = weeksByGroup.putIfAbsent(groupeID, () => []);
        l.add(semaine);
      }
    }
    // semaines are sorted
    final firstWeek = creneauxParSemaine.first.semaine;
    final lastWeek = creneauxParSemaine.last.semaine;
    return weeksByGroup.values.every((semaines) {
      semaines.add(lastWeek);
      for (var i = 0; i < semaines.length; i++) {
        final int distance;
        if (i == 0) {
          distance = semaines[0] - firstWeek;
        } else {
          distance = semaines[i] - semaines[i - 1];
        }
        if (distance > periode) {
          return false;
        }
      }
      return true;
    });
  }
}

/// [generatePermutations] lazily returns the permutation of [source]
Iterable<List<T>> generatePermutations<T>(List<T> source) {
  Iterable<List<T>> permutate(List<T> list, int cursor) sync* {
    // when the cursor gets this far, we've found one permutation, so save it
    if (cursor == list.length) {
      yield list;
    }

    for (int i = cursor; i < list.length; i++) {
      final permutation = List<T>.from(list);
      permutation[cursor] = list[i];
      permutation[i] = list[cursor];
      for (var l in permutate(permutation, cursor + 1)) {
        yield l;
      }
    }
  }

  return permutate(source, 0);
}

/// [hintPeriode] renvoie la période déduite des créneaux et groupes
/// choisis.
/// Cette estimation dois parfois être corrigée manuellement.
int hintPeriode(
    List<SemaineTo<List<PopulatedCreneau>>> creneaux, int nbGroupes) {
  final nbWeek = creneaux.last.semaine - creneaux.first.semaine + 1;
  final nbCreneaux = creneaux.map((s) => s.item.length).reduce((a, b) => a + b);
  final periode = nbWeek / (nbCreneaux / nbGroupes);
  return periode.ceil();
}
