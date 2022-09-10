import 'package:flutter/material.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';

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
                      _ViewChip(Icons.school, ModeView.matieres.title,
                          "Visualiser le colloscope par matières"),
                      _ViewChip(Icons.group, ModeView.groupes.title,
                          "Visualiser le colloscope par groupes"),
                      _ViewChip(Icons.calendar_month, ModeView.semaines.title,
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

class ColleW extends StatefulWidget {
  final Colle colle;
  final bool showMatiere;

  final void Function(bool allMatiere)? onDelete;
  final void Function(String)? onEditColleur;

  const ColleW(this.colle,
      {this.showMatiere = true, this.onDelete, this.onEditColleur, super.key});

  @override
  State<ColleW> createState() => _ColleWState();
}

class _ColleWState extends State<ColleW> {
  var colleurController = TextEditingController();

  void showEditColleur() async {
    colleurController.text = widget.colle.colleur;
    colleurController.selection = TextSelection(
        baseOffset: 0, extentOffset: colleurController.text.length);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Modifier le colleur",
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Valider"))
        ],
        content: TextFormField(
            autofocus: true,
            controller: colleurController,
            decoration: const InputDecoration(labelText: "Colleur")),
      ),
    );
    if (ok != null) {
      widget.onEditColleur!(colleurController.text);
    }
  }

  bool get showMenuDetails =>
      widget.onDelete != null && widget.onEditColleur != null;

  @override
  Widget build(BuildContext context) {
    final time = widget.colle.date.formatDateHeure();
    final text = widget.showMatiere
        ? "${widget.colle.matiere.format(dense: true)} $time"
        : time;

    final trailing = showMenuDetails
        ? PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => Future.delayed(const Duration(), showEditColleur),
                child: const ListTile(
                  title: Text("Modifier le colleur"),
                  horizontalTitleGap: 10,
                  minLeadingWidth: 0,
                ),
              ),
              PopupMenuItem(
                onTap: () => widget.onDelete!(false),
                child: const ListTile(
                  leading: Icon(Icons.clear_rounded, color: Colors.red),
                  title: Text("Supprimer"),
                  horizontalTitleGap: 10,
                  minLeadingWidth: 0,
                ),
              )
            ],
            icon: const Icon(Icons.more_vert),
            splashRadius: 14,
            tooltip: "Editer...",
          )
        : (widget.onDelete != null
            ? GestureDetector(
                onLongPress: () => widget.onDelete!(true),
                child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16,
                    onPressed: () => widget.onDelete!(false),
                    icon: const Icon(Icons.clear_rounded, color: Colors.red)),
              )
            : const SizedBox(
                height: 25,
                width: 10,
              ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: widget.colle.matiere.color.withOpacity(0.3),
          border: Border.all(color: widget.colle.matiere.color),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(widget.colle.colleur,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// [MatieresTabs] is a tab view, indexed by [MatiereID]
class MatieresTabs extends StatefulWidget {
  final MatiereProvider matieres;

  final Widget Function(MatiereID mat) builder;

  const MatieresTabs(this.matieres, this.builder, {super.key});

  @override
  State<MatieresTabs> createState() => _MatieresTabsState();
}

class _MatieresTabsState extends State<MatieresTabs>
    with TickerProviderStateMixin {
  late final TabController ct;

  @override
  void initState() {
    ct = TabController(length: widget.matieres.values.length, vsync: this);
    super.initState();
  }

  MatiereID get mat => widget.matieres.values[ct.index].index;

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
                  // isScrollable: true,
                  labelColor: Colors.black,
                  splashBorderRadius:
                      const BorderRadius.all(Radius.circular(4)),
                  tabs: widget.matieres.values
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(e.format()),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Flexible(child: child),
              ],
            )));
  }
}
