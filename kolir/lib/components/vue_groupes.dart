import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';

class VueGroupeW extends StatelessWidget {
  final Map<GroupeID, VueGroupe> groupes;
  final void Function() onAddGroupe;
  final void Function(GroupeID) onRemoveGroupe;
  const VueGroupeW(this.groupes,
      {required this.onAddGroupe, required this.onRemoveGroupe, super.key});

  @override
  Widget build(BuildContext context) {
    final entries = groupes.entries.toList();
    return ListHeader(
      title: "Vue par groupes",
      actions: [
        ElevatedButton(
            onPressed: onAddGroupe, child: const Text("Ajouter un groupe"))
      ],
      child: Expanded(
        child: ListView(
          children: List<Widget>.generate(
              groupes.keys.length,
              (index) => _GroupeW(entries[index].key, entries[index].value,
                  () => onRemoveGroupe(entries[index].key))),
        ),
      ),
    );
  }
}

class _GroupeW extends StatelessWidget {
  final GroupeID groupe;
  final VueGroupe semaines;
  final void Function() onRemove;
  const _GroupeW(this.groupe, this.semaines, this.onRemove, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Row(
          children: [
            IconButton(
              onPressed: onRemove,
              icon: deleteIcon,
              splashRadius: 20,
              color: Colors.red,
            ),
            Text(
              "$groupe :",
              style: const TextStyle(fontSize: 18),
            ),
            Expanded(
              child: SemaineList(
                  1,
                  semaines
                      .map((colles) =>
                          // pour un groupe et une semaine
                          Wrap(children: colles.map((c) => ColleW(c)).toList()))
                      .toList()),
            ),
          ],
        ),
      ),
    );
  }
}
