import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

class CreneauxController extends ChangeNotifier {
  final bool enableDuplicateCreneau;
  List<DateHeure> creneaux = [];
  CreneauxController(this.enableDuplicateCreneau);

  void remove(DateHeure creneau) {
    creneaux.remove(creneau);
    notifyListeners();
  }

  void add(DateHeure creneau) {
    if (!enableDuplicateCreneau && creneaux.contains(creneau)) {
      return;
    }
    creneaux.add(creneau);
    notifyListeners();
  }
}

class WeekCalendar extends StatefulWidget {
  final CreneauHoraireProvider creneauxHoraires;
  final CreneauxController controller;

  final List<DateHeure> placeholders;

  final Color activeCreneauColor;

  const WeekCalendar(this.creneauxHoraires, this.controller,
      {super.key,
      this.placeholders = const [],
      this.activeCreneauColor = Colors.lightBlue});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  bool showSamedi = false;

  void removeCreneau(DateHeure creneau) {
    setState(() {
      widget.controller.remove(creneau);
    });
  }

  void addCreneau(DateHeure creneau) {
    setState(() {
      widget.controller.add(creneau);
    });
  }

  List<DateHeure> creneauxForDay(int weekday) =>
      widget.controller.creneaux.where((dt) => dt.weekday == weekday).toList();

  List<DateHeure> placeholdersForDay(int weekday) =>
      widget.placeholders.where((dt) => dt.weekday == weekday).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Horaires(widget.creneauxHoraires),
            _Day(
              widget.creneauxHoraires,
              1,
              creneauxForDay(1),
              placeholdersForDay(1),
              widget.activeCreneauColor,
              removeCreneau,
              addCreneau,
            ),
            _Day(
              widget.creneauxHoraires,
              2,
              creneauxForDay(2),
              placeholdersForDay(2),
              widget.activeCreneauColor,
              removeCreneau,
              addCreneau,
            ),
            _Day(
              widget.creneauxHoraires,
              3,
              creneauxForDay(3),
              placeholdersForDay(3),
              widget.activeCreneauColor,
              removeCreneau,
              addCreneau,
            ),
            _Day(
              widget.creneauxHoraires,
              4,
              creneauxForDay(4),
              placeholdersForDay(4),
              widget.activeCreneauColor,
              removeCreneau,
              addCreneau,
            ),
            _Day(
              widget.creneauxHoraires,
              5,
              creneauxForDay(5),
              placeholdersForDay(5),
              widget.activeCreneauColor,
              removeCreneau,
              addCreneau,
            ),
            if (showSamedi)
              _Day(
                widget.creneauxHoraires,
                6,
                creneauxForDay(6),
                placeholdersForDay(6),
                widget.activeCreneauColor,
                removeCreneau,
                addCreneau,
              ),
          ],
        ),
        // const SizedBox(height: 10),
        // SizedBox(
        //   width: 300,
        //   child: CheckboxListTile(
        //       title: const Text("Afficher le samedi"),
        //       value: showSamedi,
        //       shape: const RoundedRectangleBorder(
        //           borderRadius: BorderRadius.all(Radius.circular(4))),
        //       onChanged: (b) => setState(() {
        //             showSamedi = b!;
        //           })),
        // ),
      ],
    );
  }
}

class AssistantCreneaux extends StatefulWidget {
  final CreneauHoraireProvider creneauxHoraires;

  final void Function(
      List<DateHeure> creneaux, List<int> semaines, String colleur) onAdd;

  const AssistantCreneaux(this.creneauxHoraires, this.onAdd, {super.key});

  @override
  State<AssistantCreneaux> createState() => _AssistantCreneauxState();
}

class _AssistantCreneauxState extends State<AssistantCreneaux> {
  var semainesController = TextEditingController();
  var colleurController = TextEditingController();
  var selectedCreneaux = CreneauxController(true);

  @override
  void initState() {
    semainesController.addListener(() => setState(() {}));
    super.initState();
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WeekCalendar(widget.creneauxHoraires, selectedCreneaux),
        SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: colleurController,
                    decoration: const InputDecoration(
                        label: Text("Colleur"),
                        helperText:
                            "Nom du colleur pour les créneaux choisis."),
                  ),
                ),
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
                    onPressed:
                        semaines.isEmpty || selectedCreneaux.creneaux.isEmpty
                            ? null
                            : () => widget.onAdd(selectedCreneaux.creneaux,
                                semaines, colleurController.text),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Ajouter")),
              ],
            ),
          ),
        )
      ],
    );
  }
}

const _totalHeight = 400.0;
const _dayWidth = 110.0;
const _dayPaddingX = _dayWidth * 0.06;
const _dayLeftPadding = _dayPaddingX * 0.42;

class _Day extends StatefulWidget {
  final CreneauHoraireProvider horaires;

  final int weekday;
  final List<DateHeure> creneaux;
  final List<DateHeure> placeholders;

  final Color creneauColor;

  final void Function(DateHeure) onRemove;
  final void Function(DateHeure) onAdd;

  const _Day(this.horaires, this.weekday, this.creneaux, this.placeholders,
      this.creneauColor, this.onRemove, this.onAdd,
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

  Positioned buildCreneau(DateHeure dt, bool asPlaceholder) {
    final topRatio =
        (dt.hour * 60 + dt.minute - _firstHour * 60) * _oneHourRatio / 60;
    return Positioned(
      left: _dayLeftPadding,
      top: topRatio * _totalHeight,
      height: _oneHourHeight,
      child: _CreneauW(
          _oneHourHeight,
          dt,
          asPlaceholder ? null : () => widget.onRemove(dt),
          asPlaceholder,
          widget.creneauColor),
    );
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
                          color:
                              hoverTop != null ? Colors.blue : Colors.black54),
                      borderRadius: const BorderRadius.all(Radius.circular(6))),
                  child: Stack(children: [
                    if (hoverTop != null)
                      Positioned(
                          left: _dayLeftPadding,
                          top: hoverTop,
                          height: _oneHourHeight,
                          child: _CreneauW(
                              _oneHourHeight,
                              fromHeight(hoverTop!),
                              null,
                              false,
                              widget.creneauColor)),
                    ...widget.placeholders
                        .map((cr) => buildCreneau(cr, true))
                        .toList(),
                    ...widget.creneaux
                        .map((cr) => buildCreneau(cr, false))
                        .toList(),
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
  final bool asPlaceholder;
  final Color color;

  const _CreneauW(
      this.height, this.creneau, this.onRemove, this.asPlaceholder, this.color,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dayWidth - _dayPaddingX,
      height: height,
      decoration: BoxDecoration(
          color: asPlaceholder
              ? Colors.grey.withOpacity(0.2)
              : color.withOpacity(onRemove == null ? 0.3 : 0.5),
          borderRadius: const BorderRadius.all(Radius.circular(6))),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(creneau.formatHeure(),
              style: TextStyle(color: asPlaceholder ? Colors.grey : null)),
        ),
        const Spacer(),
        if (onRemove != null)
          IconButton(
            iconSize: 20,
            splashRadius: 20,
            onPressed: onRemove,
            icon: const Icon(Icons.clear),
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
