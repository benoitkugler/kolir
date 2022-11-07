import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

class VueSemaineW extends StatefulWidget {
  final MatiereProvider matieresList;
  final int creneauxVaccants;
  final List<SemaineTo<VueSemaine>> semaines;
  final SemaineProvider semainesDates;

  final void Function(CreneauID src, CreneauID dst) onPermuteCreneauxGroupe;
  final Function(Map<int, DateTime>) onEditCalendrier;

  const VueSemaineW(this.matieresList, this.creneauxVaccants, this.semaines,
      this.semainesDates, this.onPermuteCreneauxGroupe, this.onEditCalendrier,
      {super.key});

  @override
  State<VueSemaineW> createState() => _VueSemaineWState();
}

class _VueSemaineWState extends State<VueSemaineW> {
  GroupeID? hoveredGroupe;

  _showEditSemaines() async {
    final res = await showDialog<Map<int, DateTime>>(
        context: context,
        builder: (context) => _SemaineProviderEditor(widget.semainesDates, (m) {
              Navigator.of(context).pop(m);
            }));
    if (res == null) return;
    widget.onEditCalendrier(res);
  }

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
          ),
          ElevatedButton(
              onPressed: _showEditSemaines, child: const Text("Calendrier"))
        ],
        child: NotificationListener<_NotifPermute>(
          onNotification: (notification) {
            widget.onPermuteCreneauxGroupe(notification.src, notification.dst);
            return true;
          },
          child: NotificationListener<_NotifHover>(
            onNotification: (notification) {
              setState(() {
                hoveredGroupe = notification.groupe;
              });
              return true;
            },
            child: Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey("list_semaine"),
                child: SemaineList(
                  widget.semaines
                      .map((e) => SemaineTo(
                          e.semaine,
                          _SemaineBody(
                              widget.semainesDates,
                              widget.matieresList,
                              e.semaine,
                              e.item,
                              hoveredGroupe)))
                      .toList(),
                  "Aucune colle n'est prévue.",
                ),
              ),
            ),
          ),
        ));
  }
}

// présente les créneaux par jour
class _SemaineBody extends StatelessWidget {
  final SemaineProvider calendrier;
  final MatiereProvider matieresList;
  final int week;
  final VueSemaine semaine;
  final GroupeID? hoveredGroupe;

  const _SemaineBody(this.calendrier, this.matieresList, this.week,
      this.semaine, this.hoveredGroupe,
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
              .map((weekday) => _WeekdayW(calendrier.dateFor(week, weekday),
                  weekdayCreneaux(weekday), hoveredGroupe))
              .toList(),
        ),
      ),
    );
  }
}

class _WeekdayW extends StatelessWidget {
  final DateTime day;
  final List<List<PopulatedCreneau>> creneaux;
  final GroupeID? currentGroup;
  const _WeekdayW(this.day, this.creneaux, this.currentGroup, {super.key});

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
            child: Text(formatDate(day), style: const TextStyle(fontSize: 16)),
          ),
          if (creneaux.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Aucune colle."),
            ),
          ...creneaux
              .map((creneauxParHeure) => Row(
                  children: creneauxParHeure
                      .map((creneau) => _GroupColle(
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
  const _NotifHover(this.groupe);
}

class _NotifPermute extends Notification {
  final CreneauID src;
  final CreneauID dst;
  const _NotifPermute(this.src, this.dst);
}

class _GroupColle extends StatelessWidget {
  final PopulatedCreneau creneau;
  final bool isHighlighted;

  const _GroupColle(this.creneau, this.isHighlighted, {super.key});

  Widget _content(bool isHovered) {
    final group = creneau.groupe?.name ?? "?";
    final matiere = creneau.matiere;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          border: Border.all(color: isHovered ? Colors.black : matiere.color),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: matiere.color.withOpacity(isHighlighted ? 0.6 : 0.5)),
      child: Text(
        "${creneau.date.formatHeure()}  $group ",
        style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matiere = creneau.matiere;
    return Draggable<CreneauID>(
      data: creneau.id,
      feedback: Card(child: _content(false)),
      child: DragTarget<CreneauID>(
        builder: (context, candidateData, rejectedData) => GestureDetector(
          onTap: creneau.groupe != null
              ? () => _NotifHover(isHighlighted ? null : creneau.groupe!.id)
                  .dispatch(context)
              : null,
          child: Tooltip(
            message: "${matiere.format()} - ${creneau.colleur}",
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _content(candidateData.isNotEmpty),
            ),
          ),
        ),
        onAccept: (src) => _NotifPermute(src, creneau.id).dispatch(context),
      ),
    );
  }
}

class _SemaineProviderEditor extends StatefulWidget {
  final SemaineProvider semaines;
  final Function(Map<int, DateTime>) onSave;

  const _SemaineProviderEditor(this.semaines, this.onSave, {super.key});

  @override
  State<_SemaineProviderEditor> createState() => __SemaineProviderEditorState();
}

class __SemaineProviderEditorState extends State<_SemaineProviderEditor> {
  late final List<MapEntry<int, DateTime>> edited;

  @override
  void initState() {
    edited = widget.semaines.mondays.entries.toList();
    edited.sort(((a, b) => a.key - b.key));
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _SemaineProviderEditor oldWidget) {
    edited = widget.semaines.mondays.entries.toList();
    edited.sort(((a, b) => a.key - b.key));
    super.didUpdateWidget(oldWidget);
  }

  deleteEntry(int index) {
    setState(() {
      edited.removeAt(index);
    });
  }

  addEntry() {
    setState(() {
      edited.add(MapEntry(1, DateTime.now()));
    });
  }

  onEditSemaine(int index, String newValue) {
    final newValueInt = int.tryParse(newValue);
    if (newValueInt == null) return;
    if (edited.map((e) => e.key).contains(newValueInt)) return;
    setState(() {
      edited[index] = MapEntry(newValueInt, edited[index].value);
    });
  }

  onEditMonday(int index, String newDate) {
    final chunks = newDate.split("/");
    if (chunks.length != 3) return;
    final day = int.tryParse(chunks[0]);
    final month = int.tryParse(chunks[1]);
    final year = int.tryParse(chunks[2]);
    if (day == null || month == null || year == null) return;
    setState(() {
      edited[index] = MapEntry(edited[index].key, DateTime(year, month, day));
    });
  }

  saveAndClose() {
    widget.onSave(Map.fromEntries(edited));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editer le calendrier"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          edited.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text("Aucun semaine n'est encore définie."),
                )
              : SizedBox(
                  width: 500,
                  height: 300,
                  child: ListView(
                      shrinkWrap: true,
                      children: List<Widget>.generate(edited.length, (index) {
                        final e = edited[index];
                        final time = e.value;
                        return ListTile(
                          leading: SizedBox(
                            width: 100,
                            child: TextFormField(
                              decoration:
                                  const InputDecoration(prefixText: "Semaine "),
                              keyboardType: TextInputType.number,
                              initialValue: e.key.toString(),
                              onChanged: (s) => onEditSemaine(index, s),
                            ),
                          ),
                          title: TextFormField(
                            textAlign: TextAlign.center,
                            decoration:
                                const InputDecoration(hintText: "JJ/MM/AAAA"),
                            initialValue:
                                "${time.day}/${time.month}/${time.year}",
                            onChanged: (s) => onEditMonday(index, s),
                          ),
                          trailing: IconButton(
                              onPressed: () => deleteEntry(index),
                              splashRadius: 20,
                              icon:
                                  const Icon(Icons.delete, color: Colors.red)),
                        );
                      }).toList()),
                ),
          Row(
            children: [
              ElevatedButton(
                onPressed: addEntry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Ajouter une semaine"),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: saveAndClose,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Enregistrer"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
