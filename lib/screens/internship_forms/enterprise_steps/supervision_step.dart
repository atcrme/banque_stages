import 'package:crcrme_banque_stages/common/models/job.dart';
import 'package:crcrme_banque_stages/common/widgets/form_fields/low_high_slider_form_field.dart';
import 'package:crcrme_banque_stages/common/widgets/sub_title.dart';
import 'package:flutter/material.dart';

List<String> labelAbsenceAcceptance = [
  'Aucune\ntolérance',
  'Grande\ntolérance',
];
List<String> labelEaseOfCommunication = [
  'Rétroaction\ndifficile à\nobtenir',
  'Rétroaction\ntrès facile à\nobtenir',
];
List<String> labelSupervisionStyle = [
  'Milieu peu\nencadrant',
  'Milieu très\nencadrant',
];
List<String> labelEfficiencyExpected = [
  'Aucun\nrendement\nexigé',
  'Élève\nproductif',
];
List<String> labelAutonomyExpected = [
  'Élève pas\nautonome',
  'Élève très\nautonome',
];

class SupervisionStep extends StatefulWidget {
  const SupervisionStep({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  State<SupervisionStep> createState() => SupervisionStepState();
}

class SupervisionStepState extends State<SupervisionStep> {
  final _formKey = GlobalKey<FormState>();

  // Expectations
  double? autonomyExpected;
  double? efficiencyExpected;

  // Management
  double? supervisionStyle;
  double? easeOfCommunication;
  double? absenceAcceptance;

  // Commentaires
  final _commentsController = TextEditingController();
  String get supervisionComments => _commentsController.text;

  Future<String?> validate() async {
    if (!_formKey.currentState!.validate()) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubTitle('Attentes envers le ou la stagiaire', left: 0),
            _buildAutonomyRequired(context),
            const SizedBox(height: 8),
            _buildEfficiency(context),
            const SubTitle('Encadrement', left: 0),
            _buildSupervisionStyle(context),
            const SizedBox(height: 8),
            _buildCommunication(context),
            const SizedBox(height: 8),
            _buildAbsenceTolerance(context),
            const SizedBox(height: 8),
            _Comments(controller: _commentsController),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceTolerance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Tolérance du milieu à l\'égard des retards et absences de l\'élève',
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            onSaved: (value) => absenceAcceptance = value,
            lowLabel: labelAbsenceAcceptance[0],
            highLabel: labelAbsenceAcceptance[1],
          ),
        )
      ],
    );
  }

  Widget _buildCommunication(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Communication avec l\'entreprise',
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            onSaved: (value) => easeOfCommunication = value,
            lowLabel: labelEaseOfCommunication[0],
            highLabel: labelEaseOfCommunication[1],
          ),
        )
      ],
    );
  }

  Widget _buildSupervisionStyle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Type d\'encadrement',
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            onSaved: (value) => supervisionStyle = value,
            lowLabel: labelSupervisionStyle[0],
            highLabel: labelSupervisionStyle[1],
          ),
        )
      ],
    );
  }

  Widget _buildEfficiency(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Rendement de l\'élève',
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            onSaved: (value) => efficiencyExpected = value,
            lowLabel: labelEfficiencyExpected[0],
            highLabel: labelEfficiencyExpected[1],
          ),
        )
      ],
    );
  }

  Widget _buildAutonomyRequired(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Niveau d\'autonomie de l\'élève souhaité',
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            onSaved: (value) => autonomyExpected = value,
            lowLabel: labelAutonomyExpected[0],
            highLabel: labelAutonomyExpected[1],
          ),
        ),
      ],
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Text(
            'Autres commentaires sur l\'encadrement\u00a0:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: true,
          maxLines: null,
        ),
      ],
    );
  }
}
