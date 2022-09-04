import 'package:flutter/material.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/utils.dart';

final matieresColors = [
  Colors.blue.shade200,
  Colors.green.shade200,
  Colors.orange.shade300,
  Colors.yellow.shade300,
  Colors.pink.shade300,
  Colors.purple.shade300,
  Colors.teal.shade300,
];

extension ColorM on Matiere {
  Color get color {
    return matieresColors[index];
  }
}

enum ModeView { matieres, groupes, semaines }

extension Title on ModeView {
  String get title {
    switch (this) {
      case ModeView.matieres:
        return "Vue par matières";
      case ModeView.groupes:
        return "Vue par groupes";
      case ModeView.semaines:
        return "Vue d'ensemble";
    }
  }
}

class ViewNotification extends Notification {}

class VueSkeleton extends StatelessWidget {
  final ModeView mode;
  final List<Widget> actions;
  final Widget child;

  const VueSkeleton(
      {required this.mode,
      required this.actions,
      required this.child,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: "Passer à la vue suivante",
                  child: ElevatedButton.icon(
                      onPressed: () => ViewNotification().dispatch(context),
                      icon: const Icon(
                        IconData(0xf028c,
                            fontFamily: 'MaterialIcons',
                            matchTextDirection: true),
                        size: 42,
                      ),
                      label: Text(mode.title)),
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
    final text = showMatiere
        ? "${formatMatiere(colle.matiere, dense: true)} $time"
        : time;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: colle.matiere.color,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            onDelete == null
                ? const SizedBox(
                    height: 30,
                    width: 10,
                  )
                : IconButton(
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
