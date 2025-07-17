import 'package:auto_size_text/auto_size_text.dart';
import 'package:common/services/job_data_file_service.dart';
import 'package:common_flutter/helpers/responsive_service.dart';
import 'package:crcrme_banque_stages/common/widgets/main_drawer.dart';
import 'package:crcrme_banque_stages/misc/risk_data_file_service.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/common/risk.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/specialization_list_risks_and_skills/widgets/tile_job_risk.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('SpecializationListScreen');

class SpecializationListScreen extends StatelessWidget {
  static const route = '/job-risks';

  final String id;
  const SpecializationListScreen({super.key, required this.id});

  List<Specialization> filledList(BuildContext context) {
    List<Specialization> out = [];
    for (final sector in ActivitySectorsService.activitySectors) {
      for (final specialization in sector.specializations) {
        // If there is no risk, it does not mean this specialization
        // is risk-free, it means it was not evaluated
        var hasRisks = false;
        for (final skill in specialization.skills) {
          if (hasRisks) break;
          hasRisks = skill.risks.isNotEmpty;
        }
        if (hasRisks) out.add(specialization);
      }
    }
    return out;
  }

  List<Risk> _extractAllRisks(Specialization specialization) {
    _logger.finer(
        'Extracting all risks for specialization: ${specialization.name}');

    final out = <String>[];
    for (final skill in specialization.skills) {
      for (final risk in skill.risks) {
        if (!out.contains(risk)) out.add(risk);
      }
    }
    return out.map<Risk>((e) => RiskDataFileService.fromAbbrv(e)!).toList();
  }

  List<Risk> _risksSkillHas(Skill skill, List<Risk> allRisks) {
    final out = <Risk>[];
    for (final risk in skill.risks) {
      final skillRisk = RiskDataFileService.fromAbbrv(risk);
      if (out.contains(skillRisk) || skillRisk == null) continue;
      out.add(skillRisk);
    }
    return out;
  }

  List<Skill> _skillsThatHasThisRisk(Risk risk, List<Skill> skills) {
    final out = <Skill>[];
    for (final skill in skills) {
      if (skill.risks.toList().indexWhere((e) => e == risk.abbrv) < 0) {
        continue;
      }
      out.add(skill);
    }
    return out;
  }

  void _showHelp(BuildContext context, {required bool force}) async {
    bool shouldShowHelp = force;
    if (!shouldShowHelp) {
      final prefs = await SharedPreferences.getInstance();
      final wasShown = prefs.getBool('SstHelpWasShown');
      if (wasShown == null || !wasShown) shouldShowHelp = true;
    }

    if (!shouldShowHelp) return;

    if (!context.mounted) return;
    _logger.info('Showing help dialog, force: $force');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'REPÈRES',
          textAlign: TextAlign.center,
        ),
        content: const Text(
            'L\'analyse indique le nombre de risques potentiellement présents '
            'pour chaque compétence d\'un métier et inversement.\n'
            '\n'
            'Elle a été faite pour les 45 métiers les plus populaires du '
            'répertoire du Ministère de l\'éducation.\n'
            '\n'
            'Elle ne tient pas compte du contexte de chaque milieu de stage.\n'
            '\n'
            'Pour connaitre les risques dans une entreprise spécifique, '
            'consulter sa fiche, onglet «\u00a0Postes\u00a0».'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'))
        ],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('SstHelpWasShown', true);
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SpecializationListScreen for ID: $id');

    _showHelp(context, force: false);

    final specialization = ActivitySectorsService.specialization(id);

    final risks = _extractAllRisks(specialization);
    final skillsAssociatedToRisks = <Risk, List<Skill>>{};
    for (final risk in risks) {
      skillsAssociatedToRisks[risk] =
          _skillsThatHasThisRisk(risk, specialization.skills.toList());
    }
    risks.sort((a, b) =>
        skillsAssociatedToRisks[b]!.length -
        skillsAssociatedToRisks[a]!.length);

    final skills = [...specialization.skills];
    final risksAssociatedToSkill = <Skill, List<Risk>>{};
    for (final skill in skills) {
      risksAssociatedToSkill[skill] = _risksSkillHas(skill, risks).toList();
    }
    skills.sort((a, b) =>
        risksAssociatedToSkill[b]!.length - risksAssociatedToSkill[a]!.length);

    return DefaultTabController(
      length: 2,
      child: ResponsiveService.scaffoldOf(context,
          appBar: ResponsiveService.appBarOf(
            context,
            title: Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 5),
              child: AutoSizeText(specialization.name, maxLines: 2),
            ),
            actions: [
              InkWell(
                onTap: () => _showHelp(context, force: true),
                borderRadius: BorderRadius.circular(25),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.info),
                ),
              )
            ],
            bottom: const TabBar(tabs: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_circle_sharp),
                    SizedBox(width: 10),
                    Text(
                      'Affichage par\ncompétence',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning),
                    SizedBox(width: 10),
                    Text(
                      'Affichage par\nrisque',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ]),
          ),
          smallDrawer: null,
          mediumDrawer: MainDrawer.medium,
          largeDrawer: MainDrawer.large,
          body: TabBarView(children: [
            ListView.separated(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: specialization.skills.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => TileJobRisk(
                title: skills[i].name,
                elements: risksAssociatedToSkill[skills[i]]!,
                nbMaximumElements: 1000, // Show all in orange
                tooltipMessage:
                    'Nombre de compétences possiblement concernées par ce risque',
              ),
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Colors.grey,
                  height: 16,
                );
              },
            ),
            ListView.separated(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: risks.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => TileJobRisk(
                title: risks[i].name,
                elements: skillsAssociatedToRisks[risks[i]]!,
                nbMaximumElements: 1000, // Show all in orange
                tooltipMessage:
                    'Nombre de risques potentiellement présents pour cette compétence',
              ),
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Colors.grey,
                  height: 16,
                );
              },
            )
          ])),
    );
  }
}
