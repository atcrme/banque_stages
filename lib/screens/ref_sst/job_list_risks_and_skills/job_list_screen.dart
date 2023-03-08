import 'package:flutter/material.dart';

import '/misc/job_data_file_service.dart';
import '/misc/risk_data_file_service.dart';
import '/screens/ref_sst/common/risk.dart';
import 'widgets/tile_job_risk.dart';

class JobListScreen extends StatelessWidget {
  final String id;
  const JobListScreen({super.key, required this.id});

  List<Specialization> filledList(BuildContext context) {
    List<Specialization> out = [];
    for (final sector in JobDataFileService.sectors) {
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

  List<Risk> _extractAllRisks(Specialization job) {
    final out = <String>[];
    for (final skill in job.skills) {
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

  @override
  Widget build(BuildContext context) {
    final job =
        JobDataFileService.specializations.firstWhere((e) => e.id == id);

    final risks = _extractAllRisks(job);
    final skillsAssociatedToRisks = <Risk, List<String>>{};
    for (final risk in risks) {
      skillsAssociatedToRisks[risk] = _skillsThatHasThisRisk(risk, job.skills)
          .map<String>((e) => e.name)
          .toList();
    }
    risks.sort((a, b) =>
        skillsAssociatedToRisks[b]!.length -
        skillsAssociatedToRisks[a]!.length);

    final skills = job.skills.map((e) => e).toList();
    final risksAssociatedToSkill = <Skill, List<String>>{};
    for (final skill in skills) {
      risksAssociatedToSkill[skill] =
          _risksSkillHas(skill, risks).map<String>((e) => e.name).toList();
    }
    skills.sort((a, b) =>
        risksAssociatedToSkill[b]!.length - risksAssociatedToSkill[a]!.length);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            title: Text(job.name),
            bottom: TabBar(tabs: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Par\nrisques',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.warning),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Par\ncompétences',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.school),
                  ],
                ),
              ),
            ]),
          ),
          body: TabBarView(children: [
            ListView.separated(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: risks.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => TileJobRisk(
                title: risks[i].name,
                elements: skillsAssociatedToRisks[risks[i]]!,
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
              itemCount: job.skills.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => TileJobRisk(
                title: skills[i].name,
                elements: risksAssociatedToSkill[skills[i]]!,
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
