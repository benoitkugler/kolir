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

class ViewNotification extends Notification {
  final ModeView mode;
  const ViewNotification(this.mode);
}

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
                ToggleButtons(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    isSelected: ModeView.values.map((e) => e == mode).toList(),
                    onPressed: (index) =>
                        ViewNotification(ModeView.values[index])
                            .dispatch(context),
                    children: [
                      _ViewChip(
                          const IconData(0xe559, fontFamily: 'MaterialIcons'),
                          ModeView.matieres.title,
                          "Visualiser le colloscope par matières"),
                      _ViewChip(
                          const IconData(0xe2eb, fontFamily: 'MaterialIcons'),
                          ModeView.groupes.title,
                          "Visualiser le colloscope par groupes"),
                      _ViewChip(
                          const IconData(0xf06bb, fontFamily: 'MaterialIcons'),
                          ModeView.semaines.title,
                          "Afficher une vue d'ensemble, par semaines"),
                    ]),
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

class _ViewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _ViewChip(this.icon, this.label, this.tooltip, {super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 42,
            ),
            const SizedBox(width: 10),
            Text(label)
          ],
        ),
      ),
    );
  }
}

class SemaineList extends StatelessWidget {
  final List<SemaineTo<Widget>> semaines;
  final String noDataText;
  const SemaineList(this.semaines, this.noDataText, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: semaines.isEmpty
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: semaines.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  noDataText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            ]
          : semaines.map((s) => _SemaineRow(s.semaine, s.item)).toList(),
    );
  }
}

class _SemaineRow extends StatelessWidget {
  final int semaine;
  final Widget body;
  const _SemaineRow(this.semaine, this.body, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Text("Semaine ${semaine.toString().padLeft(2, '  ')} :"),
          const SizedBox(width: 10),
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
    final time = colle.date.formatDateHeure();
    final text = showMatiere
        ? "${formatMatiere(colle.matiere, dense: true)} $time"
        : time;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: colle.matiere.color.withOpacity(0.1),
          border: Border.all(color: colle.matiere.color),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            onDelete == null
                ? const SizedBox(
                    height: 25,
                    width: 10,
                  )
                : IconButton(
                    padding: const EdgeInsets.all(4),
                    splashRadius: 12,
                    onPressed: onDelete,
                    icon: const Icon(clearIcon),
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

const clearIcon = IconData(0xf645, fontFamily: 'MaterialIcons');

/// [MatieresTabs] is a tab view, indexed by [Matiere]
class MatieresTabs extends StatefulWidget {
  final Widget Function(Matiere mat) builder;

  const MatieresTabs(this.builder, {super.key});

  @override
  State<MatieresTabs> createState() => _MatieresTabsState();
}

class _MatieresTabsState extends State<MatieresTabs>
    with TickerProviderStateMixin {
  late final TabController ct;

  @override
  void initState() {
    ct = TabController(length: Matiere.values.length, vsync: this);
    super.initState();
  }

  Matiere get mat => Matiere.values[ct.index];

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(mat);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: ct,
                  onTap: (value) => setState(() {
                    ct.index = value;
                  }),
                  isScrollable: true,
                  labelColor: Colors.black,
                  splashBorderRadius:
                      const BorderRadius.all(Radius.circular(4)),
                  tabs: Matiere.values
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(formatMatiere(e)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Flexible(child: child),
              ],
            )));
  }
}
