import 'package:flutter/material.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

extension ColorM on Matiere {
  Color get color {
    switch (this) {
      case Matiere.maths:
        return Colors.blue;
      case Matiere.esh:
        return Colors.green;
      case Matiere.anglais:
        return Colors.orange;
      case Matiere.allemand:
        return Colors.yellow;
      case Matiere.espagnol:
        return Colors.yellowAccent;
      case Matiere.francais:
        return Colors.purple;
      case Matiere.philo:
        return Colors.pink;
    }
  }
}

class ListHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget child;
  const ListHeader(
      {required this.title,
      required this.actions,
      required this.child,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18),
                ),
                const Spacer(),
                ...actions
              ],
            ),
          ),
          child
        ],
      ),
    );
  }
}

class SemaineList extends StatelessWidget {
  final int premiereSemaine;
  final List<Widget> semaines;

  const SemaineList(this.premiereSemaine, this.semaines, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(
          semaines.length, (s) => _SemaineRow(premiereSemaine, s, semaines[s])),
    );
  }
}

class _SemaineRow extends StatelessWidget {
  final int premiereSemaine;
  final int semaineIndex;
  final Widget body;
  const _SemaineRow(this.premiereSemaine, this.semaineIndex, this.body,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Text(
              "Semaine ${(premiereSemaine + semaineIndex).toString().padLeft(2, '  ')} :"),
          Expanded(child: body)
        ],
      ),
    );
  }
}

class ColleW extends StatelessWidget {
  final Colle colle;
  final bool showMatiere;
  const ColleW(this.colle, {this.showMatiere = true, super.key});

  @override
  Widget build(BuildContext context) {
    final time = formatDateHeure(colle.date);
    final text = showMatiere ? "${formatMatiere(colle.matiere)} : $time" : time;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: colle.matiere.color,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(text),
      ),
    );
  }
}

const deleteIcon = Icon(
  IconData(0xe1b9, fontFamily: 'MaterialIcons'),
);
