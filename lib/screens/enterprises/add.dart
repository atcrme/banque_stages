import 'package:flutter/material.dart';

import '/common/models/activity_types.dart';
import 'widgets/activity_types_selector_dialog.dart';

class AddEnterprise extends StatefulWidget {
  const AddEnterprise({Key? key}) : super(key: key);

  static const route = "/enterprises/add";

  @override
  State<AddEnterprise> createState() => _AddEnterpriseState();
}

class _AddEnterpriseState extends State<AddEnterprise> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Infos
  static const _choicesRecrutedBy = ["?"];
  String _recrutedBy = _choicesRecrutedBy[0];

  final Map<ActivityTypes, bool> _activityTypes =
      Map.fromIterable(ActivityTypes.values, value: (key) => false);

  bool _shareToOthers = true;

  // Métiers
  static const _choicesSectors = ["sector", "sector2", "sector3"];
  static const _choicesSpecialisation = [
    "specialisation",
    "specialisation2",
    "specialisation3"
  ];

  final List<Metier> _metiers = [
    Metier(_choicesSectors[0], _choicesSpecialisation[0])
  ];

  void _showActivityTypeSelector() {
    showDialog(
        context: context,
        builder: (context) => ActivityTypesSelectorDialog(
              activityTypes: _activityTypes,
            ));
  }

  void _addMetier() {
    setState(() {
      _metiers.add(Metier(_choicesSectors[0], _choicesSpecialisation[0]));
    });
  }

  void _removeMetier(int index) {
    setState(() {
      _metiers.removeAt(index);

      if (_metiers.isEmpty) {
        _addMetier();
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle enterprise"),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () => setState(() {
            if (_currentStep == 2) {
              _submit();
            } else {
              _currentStep += 1;
            }
          }),
          onStepTapped: (int index) => setState(() => _currentStep = index),
          onStepCancel: () => Navigator.pop(context),
          steps: [
            Step(
                isActive: _currentStep == 0,
                title: const Text("Informations"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(labelText: "Nom *"),
                          validator: (text) {
                            if (text!.isEmpty) {
                              return "Le champ ne peut pas être vide";
                            }
                            return null;
                          },
                        ),
                      ),
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(labelText: "NEQ"),
                          validator: (text) {
                            if (text!.isNotEmpty &&
                                !RegExp(r'^\d{10}$').hasMatch(text)) {
                              return "Le NEQ est composé de 10 chiffres";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ListTile(
                          title: const Text("Types d'activités"),
                          subtitle: Text(
                            _activityTypes.entries
                                .where((e) => e.value)
                                .map((e) => e.key.humanName)
                                .join(", "),
                            maxLines: 1,
                          ),
                          trailing: TextButton(
                            child: const Text("Modifier"),
                            onPressed: () => _showActivityTypeSelector(),
                          )),
                      ListTile(
                        title: const Text("Enterprise recrutée par"),
                        trailing: DropdownButton<String>(
                          value: _recrutedBy,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          onChanged: (String? newValue) {
                            setState(() {
                              _recrutedBy = newValue!;
                            });
                          },
                          items: _choicesRecrutedBy.map((String value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      SwitchListTile(
                          title: const Text("Partager l'enterprise"),
                          value: _shareToOthers,
                          onChanged: (bool newValue) => setState(() {
                                _shareToOthers = newValue;
                              })),
                    ],
                  ),
                )),
            Step(
              isActive: _currentStep == 1,
              title: const Text("Métiers"),
              content: ListView.builder(
                shrinkWrap: true,
                itemCount: _metiers.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(
                            vertical: VisualDensity.minimumDensity),
                        title: Text("Métier ${index + 1}",
                            textAlign: TextAlign.left),
                        trailing: IconButton(
                          onPressed: () => _removeMetier(index),
                          icon: const Icon(Icons.delete_forever),
                          color: Colors.redAccent,
                        ),
                      ),
                      ListTile(
                        title: const Text("Secteur d'activités"),
                        trailing: DropdownButton<String>(
                          value: _metiers[index].sector,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          onChanged: (String? newValue) {
                            setState(() {
                              _metiers[index].sector = newValue!;
                            });
                          },
                          items: _choicesSectors.map((String value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      ListTile(
                        title: const Text("Métier semi-spécialisé"),
                        trailing: DropdownButton<String>(
                          value: _metiers[index].specialisation,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          onChanged: (String? newValue) {
                            setState(() {
                              _metiers[index].specialisation = newValue!;
                            });
                          },
                          items: _choicesSpecialisation.map((String value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      )
                    ]),
              ),
            ),
            Step(
                isActive: _currentStep == 2,
                title: const Text("Contact"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      const ListTile(
                        visualDensity: VisualDensity(
                            vertical: VisualDensity.minimumDensity),
                        title: Text("Personne contact en enterprise"),
                      ),
                      ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(labelText: "Nom *"),
                          validator: (text) {
                            if (text!.isEmpty) {
                              return "Le champ ne peut pas être vide";
                            }
                            return null;
                          },
                        ),
                      ),
                      ListTile(
                        title: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Fonction"),
                        ),
                      ),
                      ListTile(
                        title: TextFormField(
                          decoration: InputDecoration(
                              label: Row(children: const [
                            Icon(Icons.phone),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text("Téléphone *"),
                            )
                          ])),
                          validator: (phone) {
                            if (phone!.isEmpty) {
                              return "Le champ ne peut pas être vide";
                            }
                            if (!RegExp(
                                    r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
                                .hasMatch(phone)) {
                              return "Le numéro entré doit être valide";
                            }
                            return null;
                          },
                        ),
                      ),
                      ListTile(
                        title: TextFormField(
                          decoration: InputDecoration(
                              label: Row(children: const [
                            Icon(Icons.mail),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text("Courriel"),
                            )
                          ])),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const ListTile(
                          visualDensity: VisualDensity(
                              vertical: VisualDensity.minimumDensity),
                          title: Text("Adresse de l'établissement")),
                      ListTile(
                        title: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Addresse"),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
          controlsBuilder: (context, details) => Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Visibility(
                visible: _currentStep == 1,
                child: ElevatedButton(
                  onPressed: () => _addMetier(),
                  child: const Text("Ajouter un métier"),
                ),
              ),
              const Expanded(child: SizedBox()),
              OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text("Annuler")),
              const SizedBox(
                width: 20,
              ),
              TextButton(
                  onPressed: details.onStepContinue,
                  child: _currentStep == 2
                      ? const Text("Ajouter")
                      : const Text("Suivant"))
            ],
          ),
        ),
      ),
    );
  }
}

class Metier {
  Metier(this.sector, this.specialisation);

  String sector;
  String specialisation;
}
