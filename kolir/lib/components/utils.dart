import 'package:flutter/material.dart';
import 'package:kolir/logic/colloscope.dart';
import 'package:kolir/logic/settings.dart';
import 'package:kolir/logic/utils.dart';

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
          Text("S ${semaine.toString().padRight(2, '  ')} :"),
          const SizedBox(width: 10),
          Expanded(child: body)
        ],
      ),
    );
  }
}

enum ChipState {
  regular,
  highlighted,
  blurred;

  factory ChipState.fromGroupe(GroupeID? selected, GroupeID? groupe) {
    if (selected == null) return ChipState.regular;
    return groupe == selected ? ChipState.highlighted : ChipState.blurred;
  }

  factory ChipState.fromMatiere(MatiereID? selected, MatiereID matiere) {
    if (selected == null) return ChipState.regular;
    return matiere == selected ? ChipState.highlighted : ChipState.blurred;
  }

  double get opacity {
    switch (this) {
      case ChipState.regular:
        return 0.5;
      case ChipState.highlighted:
        return 0.7;
      case ChipState.blurred:
        return 0.2;
    }
  }

  Color get color {
    switch (this) {
      case ChipState.regular:
        return Colors.black87;
      case ChipState.highlighted:
        return Colors.black;
      case ChipState.blurred:
        return Colors.black26;
    }
  }
}

class ColleW extends StatefulWidget {
  final Colle colle;
  final bool showMatiere;
  final ChipState state;

  final void Function(bool allMatiere)? onDelete;
  final void Function(String)? onEditColleur;
  final void Function(String)? onEditSalle;

  final void Function(Horaire)? onEditHoraire;
  final CreneauHoraireProvider? horaires;

  const ColleW(this.colle,
      {this.showMatiere = true,
      this.state = ChipState.regular,
      this.onDelete,
      this.onEditColleur,
      this.onEditSalle,
      this.onEditHoraire,
      this.horaires,
      super.key});

  @override
  State<ColleW> createState() => _ColleWState();
}

class _ColleWState extends State<ColleW> {
  var colleurController = TextEditingController();
  var salleController = TextEditingController();
  Horaire horaire = const Horaire(0, 0);

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

  void showEditSalle() async {
    salleController.text = widget.colle.salle;
    salleController.selection =
        TextSelection(baseOffset: 0, extentOffset: salleController.text.length);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Modifier la salle",
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Valider"))
        ],
        content: TextFormField(
            autofocus: true,
            controller: salleController,
            decoration: const InputDecoration(labelText: "Salle de colle")),
      ),
    );
    if (ok != null) {
      widget.onEditSalle!(salleController.text);
    }
  }

  void showEditHoraire() async {
    horaire = widget.colle.date.horaire;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Modifier l'horaire",
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Valider"))
        ],
        content: DropdownMenu(
          initialSelection: horaire,
          width: 200,
          label: const Text("Horaire"),
          dropdownMenuEntries: widget.horaires!.values
              .map((cr) => DropdownMenuEntry(
                  value: cr.horaire, label: "${cr.hour}:${cr.minute}"))
              .toList(),
          onSelected: (key) => setState(() => horaire = key!),
        ),
      ),
    );
    if (ok != null) {
      widget.onEditHoraire!(horaire);
    }
  }

  bool get showMenuDetails =>
      widget.onDelete != null &&
      widget.onEditColleur != null &&
      widget.onEditSalle != null;

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
                onTap: () => Future.delayed(const Duration(), showEditSalle),
                child: const ListTile(
                  title: Text("Modifier la salle"),
                  horizontalTitleGap: 10,
                  minLeadingWidth: 0,
                ),
              ),
              PopupMenuItem(
                onTap: () => Future.delayed(const Duration(), showEditHoraire),
                child: const ListTile(
                  title: Text("Modifier l'horaire"),
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
          color: widget.colle.matiere.color
              .withOpacity(widget.state.opacity - 0.1),
          border: Border.all(
              color: widget.colle.matiere.color
                  .withOpacity(widget.state.opacity + 0.2)),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(color: widget.state.color)),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(widget.colle.colleur,
                  style: TextStyle(
                      color: widget.state.color, fontStyle: FontStyle.italic)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// [MatieresTabs] is a tab view, indexed by [Matiere]
class MatieresTabs extends StatefulWidget {
  final MatiereProvider matieres;

  final Widget Function(Matiere mat) builder;

  const MatieresTabs(this.matieres, this.builder, {super.key});

  @override
  State<MatieresTabs> createState() => _MatieresTabsState();
}

class _MatieresTabsState extends State<MatieresTabs>
    with TickerProviderStateMixin {
  late final TabController ct;

  @override
  void initState() {
    ct = TabController(length: widget.matieres.list.length, vsync: this);
    super.initState();
  }

  Matiere get mat => widget.matieres.list[ct.index];

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
                  tabs: widget.matieres.list
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
