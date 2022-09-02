import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/utils.dart';

class WeekCalendar extends StatefulWidget {
  final void Function(List<DateTime> creneaux, List<int> semaines) onAdd;
  const WeekCalendar(this.onAdd, {super.key});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  List<DateTime> creneaux = [];
  TextEditingController semainesController = TextEditingController();

  @override
  void initState() {
    semainesController.addListener(() => setState(() {}));
    super.initState();
  }

  void removeCreneau(DateTime creneau) {
    setState(() {
      creneaux.remove(creneau);
    });
  }

  void addCreneau(DateTime creneau) {
    setState(() {
      creneaux.add(creneau);
    });
  }

  void moveCreneau(DateTime dst, DateTime src) {
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: semainesController,
                        decoration:
                            const InputDecoration(label: Text("Semaines")),
                      ),
                    ),
                  ),
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

final dimanche = DateTime(2022, 9, 4);

class _Day extends StatelessWidget {
  final int weekday;
  final List<DateTime> creneaux;
  final void Function(DateTime) onRemove;
  final void Function(DateTime) onAdd;
  final void Function(DateTime dst, DateTime src) onMove;

  const _Day(
      this.weekday, this.creneaux, this.onRemove, this.onAdd, this.onMove,
      {super.key});

  DateTime _fromOffset(Offset local) {
    // compute the corresponding hour
    final minutes = (60 * local.dy / _oneHourHeight).round();

    return dimanche.add(Duration(
        days: weekday,
        hours: _firstHour,
        minutes: minutes - minutes % 30)); // lundi = 1
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatWeekday(weekday)),
          GestureDetector(
            onTapUp: (details) {
              final time = _fromOffset(details.localPosition);
              onAdd(time);
            },
            child: DragTarget<DateTime>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  height: _totalHeight,
                  width: _dayWidth,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: candidateData.isNotEmpty
                              ? Colors.blue
                              : Colors.black),
                      borderRadius: const BorderRadius.all(Radius.circular(8))),
                  child: Stack(
                    children: creneaux.map((e) {
                      final topRatio =
                          (e.hour * 60 + e.minute - _firstHour * 60) *
                              _oneHourRatio /
                              60;
                      return Positioned(
                        left: 0,
                        top: topRatio * _totalHeight,
                        height: _oneHourHeight,
                        child: _CreneauW(e, () => onRemove(e)),
                      );
                    }).toList(),
                  ),
                );
              },
              onAcceptWithDetails: (details) {
                final local = (context.findRenderObject() as RenderBox)
                    .globalToLocal(details.offset);
                final dst = _fromOffset(local);
                onMove(dst, details.data);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreneauW extends StatelessWidget {
  final DateTime creneau;
  final void Function() onRemove;

  const _CreneauW(this.creneau, this.onRemove, {super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable(
      feedback: Card(
          color: Colors.blue,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(formatHeure(creneau)),
          )),
      dragAnchorStrategy: childDragAnchorStrategy,
      data: creneau,
      childWhenDragging: Container(
        width: _dayWidth,
        decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(6))),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(formatHeure(creneau)),
          ),
        ]),
      ),
      child: Container(
        width: _dayWidth,
        decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.5),
            borderRadius: const BorderRadius.all(Radius.circular(6))),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(formatHeure(creneau)),
          ),
          const Spacer(),
          IconButton(
            iconSize: 20,
            onPressed: onRemove,
            icon: deleteIcon,
            color: Colors.red,
          )
        ]),
      ),
    );
  }
}

class _Horaires extends StatelessWidget {
  const _Horaires({super.key});

  static final ticks = [
    DateTime(2000, 1, 1, 8),
    DateTime(2000, 1, 1, 9),
    DateTime(2000, 1, 1, 10),
    DateTime(2000, 1, 1, 11),
    DateTime(2000, 1, 1, 12),
    DateTime(2000, 1, 1, 13),
    DateTime(2000, 1, 1, 14),
    DateTime(2000, 1, 1, 15),
    DateTime(2000, 1, 1, 16),
    DateTime(2000, 1, 1, 17),
    DateTime(2000, 1, 1, 18),
    DateTime(2000, 1, 1, 19),
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
