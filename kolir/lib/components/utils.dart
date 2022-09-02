import 'package:flutter/material.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

extension ColorM on Matiere {
  Color get color {
    switch (this) {
      case Matiere.maths:
        return Colors.blue.shade200;
      case Matiere.esh:
        return Colors.green.shade200;
      case Matiere.anglais:
        return Colors.orange.shade300;
      case Matiere.allemand:
        return Colors.yellow.shade300;
      case Matiere.espagnol:
        return Colors.pink.shade300;
      case Matiere.francais:
        return Colors.purple.shade300;
      case Matiere.philo:
        return Colors.teal.shade300;
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
      mainAxisSize: MainAxisSize.min,
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
  final void Function()? onDelete;

  const ColleW(this.colle, {this.showMatiere = true, this.onDelete, super.key});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            if (onDelete != null)
              IconButton(
                  splashRadius: 10,
                  onPressed: onDelete,
                  icon: deleteIcon,
                  color: Colors.red)
          ],
        ),
      ),
    );
  }
}

const deleteIcon = Icon(
  IconData(0xe1b9, fontFamily: 'MaterialIcons'),
);
