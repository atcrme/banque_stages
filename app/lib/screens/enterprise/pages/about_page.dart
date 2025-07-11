import 'package:common/models/enterprises/enterprise.dart';
import 'package:common/models/enterprises/job.dart';
import 'package:common/models/enterprises/job_list.dart';
import 'package:common/models/persons/teacher.dart';
import 'package:common/utils.dart';
import 'package:common_flutter/helpers/form_service.dart';
import 'package:common_flutter/helpers/responsive_service.dart';
import 'package:common_flutter/providers/auth_provider.dart';
import 'package:common_flutter/providers/enterprises_provider.dart';
import 'package:common_flutter/providers/teachers_provider.dart';
import 'package:common_flutter/widgets/enterprise_activity_type_list_tile.dart';
import 'package:common_flutter/widgets/show_snackbar.dart';
import 'package:crcrme_banque_stages/common/extensions/enterprise_extension.dart';
import 'package:crcrme_banque_stages/common/extensions/job_extension.dart';
import 'package:crcrme_banque_stages/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:crcrme_banque_stages/common/widgets/disponibility_circle.dart';
import 'package:crcrme_banque_stages/common/widgets/sub_title.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EnterpriseAboutPage extends StatefulWidget {
  const EnterpriseAboutPage({
    super.key,
    required this.enterprise,
    required this.onAddInternshipRequest,
  });

  final Enterprise enterprise;
  final Function(Enterprise) onAddInternshipRequest;

  @override
  State<EnterpriseAboutPage> createState() => EnterpriseAboutPageState();
}

class EnterpriseAboutPageState extends State<EnterpriseAboutPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  late final _activityTypesController = EnterpriseActivityTypeListController(
      initial: {...widget.enterprise.activityTypes});
  final Map<String, int> _positionOffered = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = AuthProvider.of(context, listen: false);
    if (authProvider.schoolId == null) {
      showSnackBar(context,
          message: 'Impossible de charger les informations de l\'école.');
      return;
    }
    _name = widget.enterprise.name;

    _positionOffered.clear();
    for (var job in widget.enterprise.availablejobs(context)) {
      _positionOffered[job.id] =
          job.positionsOffered[authProvider.schoolId] ?? 0;
    }
  }

  bool _editing = false;
  bool get editing => _editing;

  void toggleEdit({bool save = true}) {
    if (_editing) {
      _editing = false;
      if (!save) {
        setState(() {});
        return;
      }
    } else {
      setState(() => _editing = true);
      return;
    }

    if (!FormService.validateForm(_formKey, save: true)) {
      return;
    }

    final schoolId = AuthProvider.of(context, listen: false).schoolId;
    if (schoolId == null) {
      showSnackBar(context,
          message: 'Impossible de sauvegarder, l\'école est introuvable.');
      return;
    }
    if (_name != widget.enterprise.name ||
        areSetsNotEqual(_activityTypesController.activityTypes,
            widget.enterprise.activityTypes) ||
        areMapsNotEqual(_positionOffered, {
          for (var job in widget.enterprise.availablejobs(context))
            job.id: job.positionsOffered[schoolId],
        })) {
      EnterprisesProvider.of(context, listen: false).replace(
        widget.enterprise.copyWith(
            name: _name,
            activityTypes: _activityTypesController.activityTypes,
            jobs: JobList()
              ..addAll(widget.enterprise.availablejobs(context).map((job) {
                return job.copyWith(
                    positionsOffered: {schoolId: _positionOffered[job.id]!});
              }))),
      );
    }

    setState(() => _editing = false);
  }

  bool _canPop = false;

  @override
  Widget build(BuildContext context) {
    // Register so the build is triggered if the enterprises are changed
    EnterprisesProvider.of(context, listen: true);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (_canPop) return;

        _canPop = await ConfirmExitDialog.show(context,
            content: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: '** Vous quittez la page sans avoir '
                      'cliqué sur Enregistrer '),
              WidgetSpan(
                  child: SizedBox(
                height: 22,
                width: 22,
                child: Icon(
                  Icons.save,
                  color: Theme.of(context).primaryColor,
                ),
              )),
              const TextSpan(
                text: '. **\n\nToutes vos modifications seront perdues.',
              ),
            ])),
            isEditing: editing);

        // If the user confirms the exit, redo the pop
        if (_canPop && context.mounted) ResponsiveService.popOf(context);
      },
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GeneralInformation(
                  enterprise: widget.enterprise,
                  editMode: _editing,
                  onSaved: (name) => _name = name),
              _AvailablePlace(
                initial: _positionOffered.map(
                  (key, value) => MapEntry(
                      widget.enterprise
                          .availablejobs(context)
                          .firstWhere((e) => e.id == key),
                      value),
                ),
                editMode: _editing,
                onChanged: (Job job, int newValue) =>
                    setState(() => _positionOffered[job.id] = newValue),
              ),
              _ActivityType(
                  controller: _activityTypesController,
                  editMode: _editing,
                  setState: setState),
              _RecrutedBy(enterprise: widget.enterprise),
              _AddInternshipButton(
                editingMode: _editing,
                onPressed: () async =>
                    await widget.onAddInternshipRequest(widget.enterprise),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralInformation extends StatelessWidget {
  const _GeneralInformation(
      {required this.enterprise,
      required this.editMode,
      required this.onSaved});

  final Enterprise enterprise;
  final bool editMode;
  final Function(String?) onSaved;

  @override
  Widget build(BuildContext context) {
    return editMode
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubTitle('Nom de l\'entreprise'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:
                            TextEditingController(text: enterprise.name),
                        enabled: editMode,
                        onSaved: onSaved,
                        validator: (text) => text!.isEmpty
                            ? 'Ajouter le nom de l\'entreprise.'
                            : null,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        : Container();
  }
}

class _AvailablePlace extends StatelessWidget {
  const _AvailablePlace({
    required this.initial,
    required this.editMode,
    required this.onChanged,
  });

  final Map<Job, int> initial;
  final bool editMode;
  final Function(Job job, int newValue) onChanged;

  @override
  Widget build(BuildContext context) {
    final schoolId = AuthProvider.of(context, listen: true).schoolId;
    if (schoolId == null) {
      return const Center(child: Text('Impossible de charger les stages.'));
    }

    final jobs = initial.keys.toList();
    jobs.sort(
      (a, b) => a.specialization.name
          .toLowerCase()
          .compareTo(b.specialization.name.toLowerCase()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Places de stage disponibles'),
        if (jobs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Aucun stage disponible pour cette entreprise.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        if (jobs.isNotEmpty)
          Column(
            children: jobs.map(
              (job) {
                final int positionsOffered = initial[job]!;
                final positionsRemaining =
                    positionsOffered - job.positionsOccupied(context);

                return ListTile(
                  visualDensity: VisualDensity.compact,
                  leading: DisponibilityCircle(
                    positionsOffered: positionsOffered,
                    positionsOccupied: job.positionsOccupied(context),
                  ),
                  title: Text(job.specialization.idWithName),
                  trailing: editMode
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                onPressed: positionsOffered == 0
                                    ? null
                                    : () =>
                                        onChanged(job, positionsOffered - 1),
                                icon: Icon(Icons.remove,
                                    color: positionsRemaining == 0
                                        ? Colors.grey
                                        : Colors.black)),
                            Text(
                              '$positionsRemaining / $positionsOffered',
                            ),
                            IconButton(
                                onPressed: () =>
                                    onChanged(job, positionsOffered + 1),
                                icon:
                                    const Icon(Icons.add, color: Colors.black)),
                          ],
                        )
                      : Text(
                          '${job.positionsRemaining(context, schoolId: schoolId)} / $positionsOffered',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                );
              },
            ).toList(),
          )
      ],
    );
  }
}

class _ActivityType extends StatelessWidget {
  const _ActivityType(
      {required this.controller,
      required this.editMode,
      required this.setState});

  final EnterpriseActivityTypeListController controller;
  final bool editMode;
  final Function(Function()) setState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Types d\'activités'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: EnterpriseActivityTypeListTile(
              hideTitle: true,
              controller: controller,
              editMode: editMode,
              activityTabAtTop: true,
              tilePadding: const EdgeInsets.all(0),
            ),
          ),
        )
      ],
    );
  }
}

class _RecrutedBy extends StatelessWidget {
  const _RecrutedBy({required this.enterprise});

  final Enterprise enterprise;

  void _sendEmail(Teacher teacher) {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: teacher.email!,
    );
    launchUrl(emailLaunchUri);
  }

  Future<Teacher?> _getTeacherFromId(BuildContext context) async {
    if (enterprise.recruiterId.isEmpty) return null;

    while (true) {
      if (!context.mounted) return null;
      final teachers = TeachersProvider.of(context);
      final teacher = teachers.fromIdOrNull(enterprise.recruiterId);
      if (teacher != null) return teacher;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getTeacherFromId(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teacher = snapshot.data as Teacher?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubTitle('Entreprise recrutée par'),
              teacher == null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 24.0),
                      child: Text(
                        'Aucun enseignant n\'est assigné à cette entreprise.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : GestureDetector(
                      onTap: teacher.email == null
                          ? null
                          : () => _sendEmail(teacher),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Text(
                          teacher.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                decoration: teacher.email == null
                                    ? null
                                    : TextDecoration.underline,
                                color:
                                    teacher.email == null ? null : Colors.blue,
                              ),
                        ),
                      ),
                    )
            ],
          );
        });
  }
}

class _AddInternshipButton extends StatelessWidget {
  const _AddInternshipButton({
    required this.editingMode,
    required this.onPressed,
  });

  final bool editingMode;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: editingMode
            ? Container()
            : ElevatedButton(
                onPressed: onPressed,
                child: const Text('Inscrire un stagiaire')),
      ),
    );
  }
}
