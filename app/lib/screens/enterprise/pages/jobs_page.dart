import 'package:common/models/enterprises/enterprise.dart';
import 'package:common/models/enterprises/job.dart';
import 'package:common/utils.dart';
import 'package:common_flutter/providers/enterprises_provider.dart';
import 'package:common_flutter/widgets/animated_expanding_card.dart';
import 'package:crcrme_banque_stages/common/extensions/enterprise_extension.dart';
import 'package:crcrme_banque_stages/common/widgets/dialogs/add_sst_event_dialog.dart';
import 'package:crcrme_banque_stages/common/widgets/dialogs/add_text_dialog.dart';
import 'package:crcrme_banque_stages/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:crcrme_banque_stages/common/widgets/dialogs/job_creator_dialog.dart';
import 'package:crcrme_banque_stages/common/widgets/sub_title.dart';
import 'package:crcrme_banque_stages/misc/storage_service.dart';
import 'package:crcrme_banque_stages/screens/enterprise/pages/jobs_expansion_panels/incidents_expansion_panel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'jobs_expansion_panels/comments_expansion_panel.dart';
import 'jobs_expansion_panels/photo_expansion_panel.dart';
import 'jobs_expansion_panels/prerequisites_expansion_panel.dart';
import 'jobs_expansion_panels/sst_expansion_panel.dart';
import 'jobs_expansion_panels/supervision_expansion_panel.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.enterprise,
  });

  final Enterprise enterprise;

  @override
  State<JobsPage> createState() => JobsPageState();
}

class JobsPageState extends State<JobsPage> {
  final Map<String, UniqueKey> _cardKey = {};
  final Map<String, List> _expandedSections = {};
  final Map<String, GlobalKey<PrerequisitesBodyState>> _prerequisitesFormKeys =
      {};
  final Map<String, bool> _isEditingPrerequisites = {};

  bool get isEditing => _isEditingPrerequisites.containsValue(true);
  void cancelEditing() {
    for (final e in _isEditingPrerequisites.keys) {
      _isEditingPrerequisites[e] = false;
    }
    setState(() {});
  }

  Future<void> addJob() async {
    final enterprises = EnterprisesProvider.of(context, listen: false);

    // Building the dialog in a Scaffold allows for the Snackbar to be shown
    // over the dialog box
    final newJob = await showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: JobCreatorDialog(enterprise: widget.enterprise),
      ),
    );

    if (newJob == null) return;
    widget.enterprise.jobs.add(newJob);
    enterprises.replace(widget.enterprise);
  }

  void _addImage(Job job, ImageSource source) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);

    late List<XFile?> images;
    if (source == ImageSource.camera) {
      images = [(await ImagePicker().pickImage(source: ImageSource.camera))];
    } else {
      images = await ImagePicker().pickMultiImage();
    }

    for (XFile? file in images) {
      if (file == null) continue;
      var url = await StorageService.instance.uploadJobImage(file.path);
      job.photosUrl.add(url);
    }

    enterprises.replace(widget.enterprise);
  }

  void _removeImage(Job job, int index) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);
    await StorageService.instance.removeJobImage(job.photosUrl[index]);
    job.photosUrl.removeAt(index);

    enterprises.replace(widget.enterprise);
  }

  void _addSstEvent(Job job) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddSstEventDialog(),
    );
    if (result == null) return;

    final incident = Incident(result['description']);
    switch (result['eventType']) {
      case SstEventType.severe:
        job.incidents.severeInjuries.add(incident);
        break;
      case SstEventType.verbal:
        job.incidents.verbalAbuses.add(incident);
        break;
      case SstEventType.minor:
        job.incidents.minorInjuries.add(incident);
        break;
    }
    enterprises.replaceJob(widget.enterprise, job);
  }

  void _addComment(Job job) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final newComment = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const AddTextDialog(
        title: 'Ajouter un commentaire',
      ),
    );

    if (newComment == null) return;
    job.comments.add(newComment);
    enterprises.replace(widget.enterprise);
  }

  void _updateSectionsIfNeeded() {
    for (Job job in widget.enterprise.jobs) {
      _cardKey.putIfAbsent(job.id, () => UniqueKey());
      _expandedSections.putIfAbsent(
          job.id, () => [false, false, false, false, false, false]);
      _prerequisitesFormKeys.putIfAbsent(
          job.id, () => GlobalKey<PrerequisitesBodyState>());
      _isEditingPrerequisites.putIfAbsent(job.id, () => false);
    }
  }

  void _onClickPrerequisiteEdit(Job job) {
    // If we have to validate something before switching
    if (_isEditingPrerequisites[job.id]!) {
      final formKey =
          _prerequisitesFormKeys[job.id]!.currentState!.formKey.currentState!;
      if (!formKey.validate()) {
        return;
      }

      final enterprises = EnterprisesProvider.of(context, listen: false);

      final newJob = job.copyWith(
        minimumAge: _prerequisitesFormKeys[job.id]!.currentState!.minimumAge,
        preInternshipRequests: PreInternshipRequests.fromStrings(
          _prerequisitesFormKeys[job.id]!.currentState!.prerequisites,
        ),
        uniforms: _prerequisitesFormKeys[job.id]!.currentState!.uniforms,
        protections: _prerequisitesFormKeys[job.id]!.currentState!.protections,
      );
      if (job.getDifference(newJob).isNotEmpty) {
        widget.enterprise.jobs.replace(newJob);
        enterprises.replace(widget.enterprise);
      }
    }

    _isEditingPrerequisites[job.id] = !_isEditingPrerequisites[job.id]!;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _updateSectionsIfNeeded();

    final jobs = [...widget.enterprise.availablejobs(context)];
    jobs.sort(
      (a, b) => a.specialization.name
          .toLowerCase()
          .compareTo(b.specialization.name.toLowerCase()),
    );

    return jobs.isEmpty
        ? Center(
            child: Text('Aucun poste disponible pour cette entreprise.',
                style: Theme.of(context).textTheme.bodyLarge),
          )
        : ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return AnimatedExpandingCard(
                key: _cardKey[job.id],
                header: SubTitle(job.specialization.name, top: 12, bottom: 12),
                initialExpandedState: jobs.length == 1,
                child: ExpansionPanelList(
                  expansionCallback: (panelIndex, isExpanded) async {
                    if (isEditing) {
                      if (!await ConfirmExitDialog.show(
                        context,
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
                            text:
                                '. **\n\nToutes vos modifications seront perdues.',
                          ),
                        ])),
                      )) {
                        return;
                      }
                      cancelEditing();
                    }
                    _expandedSections[job.id]![panelIndex] = isExpanded;
                    setState(() {});
                  },
                  children: [
                    PrerequisitesExpansionPanel(
                      key: _prerequisitesFormKeys[job.id]!,
                      isExpanded: _expandedSections[job.id]![0],
                      isEditing: _isEditingPrerequisites[job.id]!,
                      enterprise: widget.enterprise,
                      job: job,
                      onClickEdit: () => _onClickPrerequisiteEdit(job),
                    ),
                    SstExpansionPanel(
                      isExpanded: _expandedSections[job.id]![1],
                      enterprise: widget.enterprise,
                      job: job,
                      addSstEvent: _addSstEvent,
                    ),
                    IncidentsExpansionPanel(
                      isExpanded: _expandedSections[job.id]![2],
                      enterprise: widget.enterprise,
                      job: job,
                      addSstEvent: _addSstEvent,
                    ),
                    SupervisionExpansionPanel(
                      isExpanded: _expandedSections[job.id]![3],
                      job: job,
                    ),
                    PhotoExpansionPanel(
                      isExpanded: _expandedSections[job.id]![4],
                      job: job,
                      addImage: _addImage,
                      removeImage: _removeImage,
                    ),
                    CommentsExpansionPanel(
                      isExpanded: _expandedSections[job.id]![5],
                      job: job,
                      addComment: _addComment,
                    ),
                  ],
                ),
              );
            },
          );
  }
}
