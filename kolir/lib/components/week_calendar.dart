import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

class WeekCalendar extends StatefulWidget {
  final CreneauHoraireProvider creneauxHoraires;

  final void Function(List<DateHeure> creneaux, List<int> semaines) onAdd;

  const WeekCalendar(this.creneauxHoraires, this.onAdd, {super.key});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  List<DateHeure> creneaux = [];
  TextEditingController semainesController = TextEditingController();
  bool showSamedi = false;

  @override
  void initState() {
    semainesController.addListener(() => setState(() {}));
    super.initState();
  }

  void removeCreneau(DateHeure creneau) {
    setState(() {
      creneaux.remove(creneau);
    });
  }

  void addCreneau(DateHeure creneau) {
    setState(() {
      creneaux.add(creneau);
    });
  }

  void moveCreneau(DateHeure dst, DateHeure src) {
    setState(() {
      creneaux.remove(src);
      creneaux.add(dst);
    });
  }

  // returns an empty list for invalid values
  static List<int> _parseOneChunk(String s) {
    if (s.contains("-")) {
      final l = s.split("-");
      if (l.length != 2) {
        return [];
      }
      final debut = int.tryParse(l[0].trim());
      final fin = int.tryParse(l[1].trim());
      if (debut == null || fin == null || debut > fin) {
        return [];
      }
      return List<int>.generate(fin - debut + 1, (index) => debut + index);
    }
    final v = int.tryParse(s.trim());
    return v == null ? [] : [v];
  }

  List<int> get semaines {
    return semainesController.text
        .split(",")
        .map((s) => _parseOneChunk(s))
        .reduce((value, element) => [...value, ...element])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Horaires(widget.creneauxHoraires),
                  _Day(
                      widget.creneauxHoraires,
                      1,
                      creneaux.where((dt) => dt.weekday == 1).toList(),
                      removeCreneau,
                      addCreneau,
                      moveCreneau),
                  _Day(
                      widget.creneauxHoraires,
                      2,
                      creneaux.where((dt) => dt.weekday == 2).toList(),
                      removeCreneau,
                      addCreneau,
                      moveCreneau),
                  _Day(
                      widget.creneauxHoraires,
                      3,
                      creneaux.where((dt) => dt.weekday == 3).toList(),
                      removeCreneau,
                      addCreneau,
                      moveCreneau),
                  _Day(
                      widget.creneauxHoraires,
                      4,
                      creneaux.where((dt) => dt.weekday == 4).toList(),
                      removeCreneau,
                      addCreneau,
                      moveCreneau),
                  _Day(
                      widget.creneauxHoraires,
                      5,
                      creneaux.where((dt) => dt.weekday == 5).toList(),
                      removeCreneau,
                      addCreneau,
                      moveCreneau),
                  if (showSamedi)
                    _Day(
                        widget.creneauxHoraires,
                        6,
                        creneaux.where((dt) => dt.weekday == 6).toList(),
                        removeCreneau,
                        addCreneau,
                        moveCreneau),
                ],
              ),
            ),
            SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CheckboxListTile(
                        title: const Text("Afficher le samedi"),
                        value: showSamedi,
                        onChanged: (b) => setState(() {
                              showSamedi = b!;
                            })),
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: semainesController,
                        decoration: const InputDecoration(
                            label: Text("Semaines"),
                            helperText: "Exemples: 1,3,5 ; 1-12"),
                      ),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                        onPressed: semaines.isEmpty || creneaux.isEmpty
                            ? null
                            : () => widget.onAdd(creneaux, semaines),
                        child: const Text("Ajouter")),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

const _totalHeight = 400.0;
const _dayWidth = 100.0;

class _Day extends StatefulWidget {
  final CreneauHoraireProvider horaires;

  final int weekday;
  final List<DateHeure> creneaux;
  final void Function(DateHeure) onRemove;
  final void Function(DateHeure) onAdd;
  final void Function(DateHeure dst, DateHeure src) onMove;

  const _Day(this.horaires, this.weekday, this.creneaux, this.onRemove,
      this.onAdd, this.onMove,
      {super.key});

  @override
  State<_Day> createState() => _DayState();
}

class _DayState extends State<_Day> {
  int get _firstHour => widget.horaires.firstHour;
  double get _oneHourRatio => widget.horaires.oneHourRatio;
  double get _oneHourHeight => _totalHeight * _oneHourRatio;

  double? hoverTop;

  // round to the closest creneau
  double _clip(double height) {
    final hourDistance = height / _oneHourHeight;
    final inMinutes = ((_firstHour + hourDistance) * 60).round();
    final bestHoraire = minBy(
        widget.horaires.values,
        (e) => (e.hour * 60 + e.minute + e.lengthInMinutes / 2 - inMinutes)
            .abs())!;
    final centerInHour =
        (bestHoraire.hour - _firstHour) + bestHoraire.minute / 60;
    return centerInHour * _oneHourHeight;
  }

  DateHeure fromHeight(double height) {
    final minutes = (60 * height / _oneHourHeight).round();
    final tmp = Duration(hours: _firstHour, minutes: minutes);
    return DateHeure(0 /*ignored*/, widget.weekday, tmp.inHours,
        tmp.inMinutes - 60 * tmp.inHours);
  }

  DateHeure _fromOffset(Offset local) {
    final height = _clip(local.dy);
    // compute the corresponding hour
    return fromHeight(height);
  }

  void _onHover(PointerHoverEvent event) {
    final newHoverTop = _clip(event.localPosition.dy);
    if (newHoverTop != hoverTop) {
      setState(() {
        hoverTop = widget.creneaux.contains(fromHeight(newHoverTop))
            ? null
            : newHoverTop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatWeekday(widget.weekday)),
          MouseRegion(
            onExit: (event) => setState(() {
              hoverTop = null;
            }),
            onHover: _onHover,
            child: GestureDetector(
              onTapUp: (details) {
                final time = _fromOffset(details.localPosition);
                widget.onAdd(time);
              },
              child: Container(
                  height: _totalHeight,
                  width: _dayWidth,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: hoverTop != null ? Colors.blue : Colors.black),
                      borderRadius: const BorderRadius.all(Radius.circular(8))),
                  child: Stack(children: [
                    if (hoverTop != null)
                      Positioned(
                          left: 0,
                          top: hoverTop,
                          height: _oneHourHeight,
                          child: _CreneauW(
                              _oneHourHeight, fromHeight(hoverTop!), null)),
                    ...widget.creneaux.map((e) {
                      final topRatio =
                          (e.hour * 60 + e.minute - _firstHour * 60) *
                              _oneHourRatio /
                              60;
                      return Positioned(
                        left: 0,
                        top: topRatio * _totalHeight,
                        height: _oneHourHeight,
                        child: _CreneauW(
                            _oneHourHeight, e, () => widget.onRemove(e)),
                      );
                    }).toList(),
                  ])),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreneauW extends StatelessWidget {
  final double height;
  final DateHeure creneau;
  final void Function()? onRemove;

  const _CreneauW(this.height, this.creneau, this.onRemove, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dayWidth,
      height: height,
      decoration: BoxDecoration(
          color: Colors.lightBlue.withOpacity(onRemove == null ? 0.2 : 0.5),
          borderRadius: const BorderRadius.all(Radius.circular(6))),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(creneau.formatHeure()),
        ),
        const Spacer(),
        IconButton(
          iconSize: 16,
          splashRadius: 20,
          onPressed: onRemove,
          icon: deleteIcon,
          color: Colors.red,
        )
      ]),
    );
  }
}

class _Horaires extends StatelessWidget {
  final CreneauHoraireProvider horaires;

  const _Horaires(this.horaires, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: _totalHeight,
        width: 50,
        child: Stack(
          children: horaires.values.map((e) {
            final topRatio = (e.hour + e.minute / 60 - horaires.firstHour) *
                horaires.oneHourRatio;
            return Positioned(
              left: 0,
              top: topRatio * _totalHeight,
              height: 20,
              child: Text("${e.hour}h${e.minute.toString().padLeft(2, "0")}"),
            );
          }).toList(),
        ),
      ),
    );
  }
}
