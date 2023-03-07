//import 'dart:js_util';

import 'package:crcrme_banque_stages/router.dart';
import 'package:flutter/material.dart';

import '../../common/Risk.dart';

//SST
class SSTCard extends StatelessWidget {
  //params and variables
  const SSTCard(this.risk, {super.key});
  final Risk risk;

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0.5,
        child: ListTile(
            title: Text(
              'FICHE ${risk.number}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              risk.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            isThreeLine: true,
            //onTap should redirect to the risk
            onTap: () => Navigator.pushNamed(
                  context,
                  Screens.risksCardsSST,
                  arguments: risk.id,
                )));
  }
}