import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

class VueSemaineW extends StatefulWidget {
  final MatiereProvider matieresList;
  final int creneauxVaccants;
  final List<SemaineTo<VueSemaine>> semaines;

  const VueSemaineW(this.matieresList, this.creneauxVaccants, this.semaines,
      {super.key});

  @override
  State<VueSemaineW> createState() => _VueSemaineWState();
}

class _VueSemaineWState extends State<VueSemaineW> {
  GroupeID? hoveredGroupe;

  @override
  Widget build(BuildContext context) {
    final plural = widget.creneauxVaccants > 1;
    return VueSkeleton(
        mode: ModeView.semaines,
        actions: [
          Card(
            color: widget.creneauxVaccants > 0
                ? Colors.orange.shade400
                : Colors.greenAccent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.creneauxVaccants > 0
                  ? "${widget.creneauxVaccants} créneau${plural ? 'x' : ''} vaccant${plural ? 's' : ''}"
                  : "Tous les créneaux sont attribués."),
            ),
          )
        ],
        child: NotificationListener<_NotifHover>(
          onNotification: (notification) {
            setState(() {
              hoveredGroupe = notification.groupe;
            });
            return true;
          },
          child: Expanded(
            child: SingleChildScrollView(
              child: SemaineList(
                widget.semaines
                    .map((e) => SemaineTo(
                        e.semaine,
                        _SemaineBody(
                            widget.matieresList, e.item, hoveredGroupe)))
                    .toList(),
                "Aucune colle n'est prévue.",
              ),
            ),
          ),
        ));
  }
}

// présente les créneaux par jour
class _SemaineBody extends StatelessWidget {
  final MatiereProvider matieresList;
  final VueSemaine semaine;
  final GroupeID? hoveredGroupe;

  const _SemaineBody(this.matieresList, this.semaine, this.hoveredGroupe,
      {super.key});

  List<List<PopulatedCreneau>> weekdayCreneaux(int weekday) {
    final forDay = semaine.values
        .map((l) => l.where((cr) => cr.date.weekday == weekday))
        .reduce((value, element) => [...value, ...element]);
    final byDate = <DateHeure, List<PopulatedCreneau>>{};
    for (var creneau in forDay) {
      final l = byDate.putIfAbsent(creneau.date, () => []);
      l.add(creneau);
    }
    final l = byDate.entries.toList();
    l.sort((a, b) => a.key.compareTo(b.key));
    return l.map((e) => e.value).toList();
  }

  static const weekdays = [1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: weekdays
              .map((weekday) =>
                  _WeekdayW(weekday, weekdayCreneaux(weekday), hoveredGroupe))
              .toList(),
        ),
      ),
    );
  }
}

class _WeekdayW extends StatelessWidget {
  final int weekday;
  final List<List<PopulatedCreneau>> creneaux;
  final GroupeID? currentGroup;
  const _WeekdayW(this.weekday, this.creneaux, this.currentGroup, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(6))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(formatWeekday(weekday, dense: false),
                style: const TextStyle(fontSize: 16)),
          ),
          if (creneaux.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Aucune colle."),
            ),
          ...creneaux
              .map((creneauxParHeure) => Row(
                  children: creneauxParHeure
                      .map((creneau) => _Group(
                          creneau,
                          creneau.groupe != null &&
                              creneau.groupe?.id == currentGroup))
                      .toList()))
              .toList()
        ]),
      ),
    );
  }
}

class _NotifHover extends Notification {
  final GroupeID? groupe;
  _NotifHover(this.groupe);
}

class _Group extends StatelessWidget {
  final PopulatedCreneau creneau;
  final bool isHighlighted;

  const _Group(this.creneau, this.isHighlighted, {super.key});

  @override
  Widget build(BuildContext context) {
    final group = creneau.groupe?.name ?? "?";
    final matiere = creneau.matiere;
    return GestureDetector(
      onTap: creneau.groupe != null
          ? () => _NotifHover(isHighlighted ? null : creneau.groupe!.id)
              .dispatch(context)
          : null,
      child: Tooltip(
        message: "${matiere.format()} - ${creneau.colleur}",
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                border: Border.all(color: matiere.color),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: matiere.color.withOpacity(isHighlighted ? 0.6 : 0.5)),
            child: Text(
              "${creneau.date.formatHeure()}  $group ",
              style:
                  TextStyle(fontWeight: isHighlighted ? FontWeight.bold : null),
            ),
          ),
        ),
      ),
    );
  }
}
