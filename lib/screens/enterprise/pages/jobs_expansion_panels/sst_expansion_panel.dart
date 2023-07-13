import 'package:crcrme_banque_stages/common/models/enterprise.dart';
import 'package:crcrme_banque_stages/common/models/job.dart';
import 'package:crcrme_banque_stages/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SstExpansionPanel extends ExpansionPanel {
  SstExpansionPanel({
    required super.isExpanded,
    required Enterprise enterprise,
    required Job job,
    required void Function(Job job) addSstEvent,
  }) : super(
          canTapOnHeader: true,
          body: SstBody(enterprise, job, addSstEvent),
          headerBuilder: (context, isExpanded) => ListTile(
            title: const Text('Santé et Sécurité (SST)'),
            trailing: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[900]!,
                    blurRadius: 8.0,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Visibility(
                visible: job.sstEvaluation.incidents.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        );
}

class SstBody extends StatelessWidget {
  const SstBody(
    this.enterprise,
    this.job,
    this.addSstEvent, {
    super.key,
  });

  final Enterprise enterprise;
  final Job job;
  final void Function(Job job) addSstEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Size.infinite.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => addSstEvent(job),
                child: const Text('Signaler un événement'),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique d\'accidents et d\'incidents au poste de travail',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '(ex. blessure d\'élève même mineure, agression verbale '
                      'harcèlement subis par l\'élève)',
                    ),
                  ),
                  if (job.sstEvaluation.incidents.isEmpty)
                    const Text('Aucun incident n\'a été signalé'),
                  if (job.sstEvaluation.incidents.isNotEmpty)
                    ...job.sstEvaluation.incidents
                        .map((e) => Text('\u2022 $e')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personne de l\'entreprise à qui s\'adresser en cas de blessure '
              'ou d\'incident',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: job.sstEvaluation.incidentContact.isNotEmpty
                  ? Text(job.sstEvaluation.incidentContact)
                  : const Text('Aucun contact enregistré'),
            ),
            const SizedBox(height: 8),
            Text(
              'Situations dangereuses repérées sur le poste de travail',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: job.sstEvaluation.dangerousSituations.isNotEmpty
                    ? job.sstEvaluation.dangerousSituations
                        .map((e) => Text('\u2022 $e'))
                        .toList()
                    : [const Text('Aucune situation')],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Détail des tâches et risques associés',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(job.sstEvaluation.incidentContact.isEmpty
                ? 'Le formulaire n\'a jamais été rempli avec cette entreprise'
                : 'Formulaire SST rempli avec l\'entreprise\n'
                    'Mis à jour le ${DateFormat.yMMMEd('fr_CA').format(job.sstEvaluation.date)}'),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => GoRouter.of(context).pushNamed(
                  Screens.jobSstForm,
                  params: Screens.params(enterprise, jobId: job),
                ),
                child: const Text(
                  'Afficher le\nformulaire',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
