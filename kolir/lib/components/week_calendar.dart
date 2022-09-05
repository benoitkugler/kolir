import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/utils.dart';

class WeekCalendar extends StatefulWidget {
  final void Function(List<DateHeure> creneaux, List<int> semaines) onAdd;
  const WeekCalendar(this.onAdd, {super.key});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  List<DateHeure> creneaux = [];
  TextEditingController semainesController = TextEditingController();

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

  List<int> get semaines {
    return semainesController.text
        .split(",")
        .map((e) => int.tryParse(e.trim()))
        .where((element) => element != null)
        .map((e) => e!)
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
                  const _Horaires(),
                  _Day(1, creneaux.where((dt) => dt.weekday == 1).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                  _Day(2, creneaux.where((dt) => dt.weekday == 2).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                  _Day(3, creneaux.where((dt) => dt.weekday == 3).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                  _Day(4, creneaux.where((dt) => dt.weekday == 4).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                  _Day(5, creneaux.where((dt) => dt.weekday == 5).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                  _Day(6, creneaux.where((dt) => dt.weekday == 6).toList(),
                      removeCreneau, addCreneau, moveCreneau),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: semainesController,
                        decoration: const InputDecoration(
                            label: Text("Semaines"),
                            helperText: "Semaines séparées par une virgule"),
                      ),
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
            )
          ],
        ),
      ),
    );
  }
}

const _firstHour = 8;
const _lastHour = 19;
const _totalHeight = 400.0;
const _dayWidth = 100.0;
const _oneHourRatio = 1 / (_lastHour - _firstHour);
const _oneHourHeight = _totalHeight * _oneHourRatio;

class _Day extends StatefulWidget {
  final int weekday;
  final List<DateHeure> creneaux;
  final void Function(DateHeure) onRemove;
  final void Function(DateHeure) onAdd;
  final void Function(DateHeure dst, DateHeure src) onMove;

  const _Day(
      this.weekday, this.creneaux, this.onRemove, this.onAdd, this.onMove,
      {super.key});

  @override
  State<_Day> createState() => _DayState();
}

class _DayState extends State<_Day> {
  double? hoverTop;

  // round to half hour, height is the position of the mouse
  double _clip(double height) {
    // express distance in half hour
    final halfHourDistance = height / (_oneHourHeight / 2);
    final inHours = halfHourDistance.round() * 0.5 -
        0.5; // -0.5 to be in the center of the hour
    return inHours * _oneHourHeight;
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
                          child: _CreneauW(fromHeight(hoverTop!), null)),
                    ...widget.creneaux.map((e) {
                      final topRatio =
                          (e.hour * 60 + e.minute - _firstHour * 60) *
                              _oneHourRatio /
                              60;
                      return Positioned(
                        left: 0,
                        top: topRatio * _totalHeight,
                        height: _oneHourHeight,
                        child: _CreneauW(e, () => widget.onRemove(e)),
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
  final DateHeure creneau;
  final void Function()? onRemove;

  const _CreneauW(this.creneau, this.onRemove, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dayWidth,
      height: _oneHourHeight,
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
  const _Horaires({super.key});

  static const ticks = [
    DateHeure(2000, 1, 8, 0),
    DateHeure(2000, 1, 9, 0),
    DateHeure(2000, 1, 10, 0),
    DateHeure(2000, 1, 11, 0),
    DateHeure(2000, 1, 12, 0),
    DateHeure(2000, 1, 13, 0),
    DateHeure(2000, 1, 14, 0),
    DateHeure(2000, 1, 15, 0),
    DateHeure(2000, 1, 16, 0),
    DateHeure(2000, 1, 17, 0),
    DateHeure(2000, 1, 18, 0),
    DateHeure(2000, 1, 19, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: _totalHeight,
        width: 50,
        child: Stack(
          children: ticks.map((e) {
            final topRatio = (e.hour - _firstHour) * _oneHourRatio;
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
