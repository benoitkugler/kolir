import 'package:flutter/material.dart';
import 'package:kolir/components/utils.dart';
import 'package:kolir/logic/colloscope.dart';

class VueSemaineW extends StatelessWidget {
  final List<VueSemaine> semaines;
  const VueSemaineW(this.semaines, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListHeader(
        title: "Vue par semaines",
        actions: [],
        child: Expanded(
          child: SingleChildScrollView(
            child: SemaineList(
              1,
              semaines.map((e) => _SemaineBody(e)).toList(),
            ),
          ),
        ));
  }
}

class _SemaineBody extends StatelessWidget {
  final VueSemaine semaine;
  const _SemaineBody(this.semaine, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Matiere.values
          .map((e) => Column(
              children: (semaine[e] ?? [])
                  .map((groupID) => _Group(groupID, e.color))
                  .toList()))
          .toList(),
    );
  }
}

class _Group extends StatelessWidget {
  final String groupID;
  final Color color;

  const _Group(this.groupID, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)), color: color),
        child: Text(groupID == NoGroup ? "<Aucun groupe>" : groupID),
      ),
    );
  }
}
