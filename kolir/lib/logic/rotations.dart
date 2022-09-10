import 'package:collection/collection.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

/// [setupRotations] calcule les répartitions permettant d'attribuer les groupes donnés aux les créneaux
/// donnés, en respectant les contraintes des groupes.
/// Les contraintes prises en comptes sont les contraintes hebdomadaires et [alreadyAttributed].
/// De plus, pour chaque semaine, un groupe apparait au plus une fois.
/// Pour simplifier, toutes les semaines doivent avoir le même nombre de créneaux.
/// De plus uniquement les contraintes de la première semaine sont prises en compte.
/// Une erreur est renvoyé si aucune rotation ne satisfait les contraintes.
Maybe<RotationSelector> setupRotations(
    MatiereID matiere,
    List<SemaineTo<List<PopulatedCreneau>>> creneauxParSemaine,
    List<Groupe> groupes,
    Map<GroupeID, List<DateHeure>> alreadyAttributed,
    int periode) {
  final builder =
      _RotationBuilder(creneauxParSemaine, groupes, alreadyAttributed);
  final res = builder._build(periode);
  if (res.error.isNotEmpty) {
    return Maybe(RotationSelector(0, [], [], [], 0), res.error);
  }

  return Maybe(
      RotationSelector(
          matiere, creneauxParSemaine, res.value, groupes, periode),
      "");
}

class _RotationBuilder {
  final List<SemaineTo<List<PopulatedCreneau>>> creneauxParSemaine;
  final List<Groupe> groupes;

  /// [alreadyAttributed] is added to the groupe constraints
  final Map<GroupeID, List<DateHeure>> alreadyAttributed;

  _RotationBuilder(
      this.creneauxParSemaine, this.groupes, this.alreadyAttributed) {
    assert(creneauxParSemaine.isNotEmpty);
    assert(creneauxParSemaine.map((e) => e.item.length).toSet().length == 1);
    assert(creneauxParSemaine.isSortedBy<num>((s) => s.semaine));
    assert(groupes.isNotEmpty);
  }

  /// prend en compte les contraintes appliquées à la première semaine
  /// et renvoie toutes les possibilités d'attribution, pour une semaine
  List<Permutation>? _buildPermutationCandidates() {
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

  bool _passConstraintOccupied(
      SemaineTo<List<PopulatedCreneau>> week, Permutation candidate) {
    for (var i = 0; i < week.item.length; i++) {
      final date = week.item[i].date;
      final groupeID = candidate[i];
      if ((alreadyAttributed[groupeID] ?? []).contains(date)) {
        return false;
      }
    }
    return true;
  }

  // parmi les candidats possibles, filtre en appliquant les contraintes
  // de chaque semaine
  Maybe<_CandidatesPerWeek> _buildCandidatesPerWeek(
      List<Permutation> candidates) {
    final _CandidatesPerWeek out = [];
    // try to apply the candidate perms to every week
    for (var semaine in creneauxParSemaine) {
      final l = candidates
          .where((cd) => _passConstraintOccupied(semaine, cd))
          .toList();
      if (l.isEmpty) {
        return Maybe<_CandidatesPerWeek>([],
            "Aucune répartition ne convient pour la semaine ${semaine.semaine}.");
      }
      out.add(l);
    }
    return Maybe(out, "");
  }

  /// [_build] renvoie, pour chaque semaine, les groupes affectés
  /// aux créneaux de la semaine.
  /// Une erreur est retournée pour les cas pathologiques.
  Maybe<_CandidatesPerWeek> _build(int periode) {
    final candidates = _buildPermutationCandidates();

    if (candidates == null) {
      return const Maybe([],
          "Les contraintes hebdomadaires des groupes ne peuvent être résolues.");
    }

    final candidatesPerWeek = _buildCandidatesPerWeek(candidates);

    return candidatesPerWeek;
  }
}

// pour chaque semaine, donne les permutations possibles
// après sélection des contraintes
typedef _CandidatesPerWeek = List<List<Permutation>>;

// représente l'attribution des créneaux de la semaine
typedef Permutation = List<GroupeID>;

class Maybe<T> {
  final T value;
  final String error;
  const Maybe(this.value, this.error);
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

int numberOfCombinaisons<T>(List<List<T>> sources) {
  return sources
      .map((l) => l.length)
      .reduce((value, element) => value * element);
}

Iterable<List<T>> generateCombinaisons<T>(List<List<T>> sources) sync* {
  if (sources.isEmpty || sources.any((l) => l.isEmpty)) {
    yield [];
    return;
  }
  var indices = List<int>.filled(sources.length, 0);
  var next = 0;
  while (true) {
    yield [for (var i = 0; i < indices.length; i++) sources[i][indices[i]]];
    while (true) {
      var nextIndex = indices[next] + 1;
      if (nextIndex < sources[next].length) {
        indices[next] = nextIndex;
        break;
      }
      next += 1;
      if (next == sources.length) return;
    }
    indices.fillRange(0, next, 0);
    next = 0;
  }
}

/// [hintPeriode] renvoie la période déduite des créneaux et groupes
/// choisis.
/// Cette estimation dois parfois être corrigée manuellement.
int hintPeriode(
    List<SemaineTo<List<PopulatedCreneau>>> creneaux, int nbGroupes) {
  creneaux.sortBy<num>((s) => s.semaine);
  final nbWeek = creneaux.last.semaine - creneaux.first.semaine + 1;
  final nbCreneaux = creneaux.map((s) => s.item.length).reduce((a, b) => a + b);
  final periode = nbWeek / (nbCreneaux / nbGroupes);
  return periode.ceil();
}

class RotationSelector {
  final MatiereID _matiere;
  final List<SemaineTo<List<PopulatedCreneau>>> _creneauxParSemaine;
  final _CandidatesPerWeek _candidates;
  final int _periode;

  final Map<GroupeID, int> bufferEquilibrium;
  final Map<GroupeID, List<int>> bufferPeriodeByGroupe = {};

  int get essais => numberOfCombinaisons(_candidates);

  RotationSelector(this._matiere, this._creneauxParSemaine, this._candidates,
      List<Groupe> groupes, this._periode)
      : bufferEquilibrium =
            Map.fromEntries(groupes.map((e) => MapEntry(e.id, 0)));

  bool _hasEquilibrium(List<Permutation> value) {
    bufferEquilibrium.updateAll((key, value) => 0);
    for (var perm in value) {
      for (var groupeID in perm) {
        bufferEquilibrium[groupeID] = (bufferEquilibrium[groupeID] ?? 0) + 1;
      }
    }
    final first = bufferEquilibrium.values.first;
    return bufferEquilibrium.values.every((size) => size == first);
  }

  // verifie si, pour chaque groupes, les colles sont séparés
  // d'au plus periode - 1 semaine
  // renvoie [null] si la période est respecté, un score sinon
  int? _respectPeriode<T>(List<Permutation> value) {
    bufferPeriodeByGroupe.updateAll((key, value) => []);
    for (var i = 0; i < value.length; i++) {
      final perm = value[i];
      final semaine = _creneauxParSemaine[i].semaine;
      for (var groupeID in perm) {
        final l = bufferPeriodeByGroupe.putIfAbsent(groupeID, () => []);
        l.add(semaine);
      }
    }
    // semaines are sorted
    final firstWeek = _creneauxParSemaine.first.semaine - 1;
    final lastWeek = _creneauxParSemaine.last.semaine;
    int closestDistanceForAll = lastWeek - firstWeek;
    bool respectPeriode = true;
    for (var groupeSemaines in bufferPeriodeByGroupe.values) {
      int closestDistance = lastWeek - firstWeek;
      groupeSemaines.add(lastWeek);
      for (var i = 0; i < groupeSemaines.length; i++) {
        final int distance;
        if (i == 0) {
          distance = groupeSemaines[0] - firstWeek;
        } else {
          distance = groupeSemaines[i] - groupeSemaines[i - 1];
        }
        // exclude distance with begining and end
        if (i != 0 &&
            i != groupeSemaines.length - 1 &&
            distance < closestDistance) {
          closestDistance = distance;
        }
        if (distance > _periode) {
          respectPeriode = false;
        }
      }
      if (closestDistance < closestDistanceForAll) {
        closestDistanceForAll = closestDistance;
      }
    }

    return respectPeriode ? null : closestDistanceForAll;
  }

  /// [select] renvoie, pour chaque semaine demandée, les groupes affectés
  /// aux créneaux de la semaine.
  /// Dans le pire des cas, le temps de calcul est proportionnel à [essais].
  /// Cette fonction devrait être appelée dans un thread s
  SelectedRotation select() {
    final iter = generateCombinaisons(_candidates);
    // try every permutation of the candidate and select the best
    // in case nothing works, we give priority to equilibrium over periode
    List<Permutation>? best;
    int bestPeriodeScore = 0; // higher is better
    for (var res in iter) {
      if (_hasEquilibrium(res)) {
        final periodeScore = _respectPeriode(res);
        if (periodeScore == null) {
          return SelectedRotation(
              _matiere, _creneauxParSemaine, res); // great !
        } else if (periodeScore > bestPeriodeScore || best == null) {
          // garde le meilleur score
          best = res;
          bestPeriodeScore = periodeScore;
        }
      }
    }

    // hope for equilbirum
    if (best != null) {
      return SelectedRotation(_matiere, _creneauxParSemaine, best);
    }
    // arg, select the first one
    return SelectedRotation(_matiere, _creneauxParSemaine,
        iter.first); // note that generateCombinaisons is lazy
  }
}

class SelectedRotation {
  final MatiereID matiere;
  final List<SemaineTo<List<PopulatedCreneau>>> creneauxParSemaine;
  final List<Permutation> rotation;
  const SelectedRotation(this.matiere, this.creneauxParSemaine, this.rotation);
}
