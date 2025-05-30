import 'package:common/models/enterprises/enterprise.dart';
import 'package:crcrme_banque_stages/common/widgets/address_list_tile.dart';
import 'package:crcrme_banque_stages/common/widgets/form_fields/activity_types_picker_form_field.dart';
import 'package:flutter/material.dart';

class InformationsPage extends StatefulWidget {
  const InformationsPage({super.key});

  @override
  State<InformationsPage> createState() => InformationsPageState();
}

class InformationsPageState extends State<InformationsPage> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  final addressController = AddressController();
  String? neq;

  Set<ActivityTypes> activityTypes = {};

  Future<String?> validate() async {
    await addressController.requestValidation();

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
        child: FocusScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: '* Nom de l\'entreprise'),
                validator: (text) =>
                    text!.isEmpty ? 'Ajouter le nom de l\'entreprise.' : null,
                onSaved: (name) => this.name = name,
              ),
              ActivityTypesPickerFormField(
                onSaved: (Set<ActivityTypes>? activityTypes) =>
                    setState(() => this.activityTypes = activityTypes!),
                activityTabAtTop: false,
              ),
              AddressListTile(
                title: 'Adresse',
                isMandatory: true,
                enabled: true,
                addressController: addressController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
