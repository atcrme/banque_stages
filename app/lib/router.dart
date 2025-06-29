import 'package:common_flutter/providers/auth_provider.dart';
import 'package:crcrme_banque_stages/screens/add_enterprise/add_enterprise_screen.dart';
import 'package:crcrme_banque_stages/screens/enterprise/enterprise_screen.dart';
import 'package:crcrme_banque_stages/screens/enterprises_list/enterprises_list_screen.dart';
import 'package:crcrme_banque_stages/screens/internship_enrollment/internship_enrollment_screen.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/enterprise_steps/enterprise_evaluation_screen.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/student_steps/attitude_evaluation_form_controller.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/student_steps/attitude_evaluation_screen.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/student_steps/skill_evaluation_form_screen.dart';
import 'package:crcrme_banque_stages/screens/internship_forms/student_steps/skill_evaluation_main_screen.dart';
import 'package:crcrme_banque_stages/screens/job_sst_form/job_sst_form_screen.dart';
import 'package:crcrme_banque_stages/screens/login_screen.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/home_sst/home_sst_screen.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/incident_history/incident_history_screen.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/risks_list/risks_list_screen.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/specialization_list_risks_and_skills/specialization_list_screen.dart';
import 'package:crcrme_banque_stages/screens/student/student_screen.dart';
import 'package:crcrme_banque_stages/screens/students_list/students_list_screen.dart';
import 'package:crcrme_banque_stages/screens/supervision_chart/supervision_chart_screen.dart';
import 'package:crcrme_banque_stages/screens/supervision_chart/supervision_student_details.dart';
import 'package:crcrme_banque_stages/screens/tasks_to_do/tasks_to_do_screen.dart';
import 'package:crcrme_banque_stages/screens/visiting_students/itinerary_screen.dart';
import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:go_router/go_router.dart';

abstract class Screens {
  static const home = enterprisesList;

  static const login = LoginScreen.route;
  static const itinerary = ItineraryMainScreen.route;

  static const tasksToDo = TasksToDoScreen.route;

  static const enterprisesList = EnterprisesListScreen.route;
  static const enterprise = EnterpriseScreen.route;
  static const addEnterprise = AddEnterpriseScreen.route;
  static const jobSstForm = JobSstFormScreen.route;

  static const supervisionChart = SupervisionChart.route;
  static const supervisionStudentDetails =
      SupervisionStudentDetailsScreen.route;

  static const studentsList = StudentsListScreen.route;
  static const student = StudentScreen.route;

  static const internshipEnrollementFromEnterprise =
      InternshipEnrollmentScreen.route;
  static const enterpriseEvaluationScreen = EnterpriseEvaluationScreen.route;
  static const skillEvaluationMainScreen = SkillEvaluationMainScreen.route;
  static const skillEvaluationFormScreen = SkillEvaluationFormScreen.route;
  static const attitudeEvaluationScreen = AttitudeEvaluationScreen.route;

  static const homeSst = HomeSstScreen.route;
  static const cardsSst = SstCardsScreen.route;
  static const incidentHistorySst = IncidentHistoryScreen.route;
  static const jobSst = SpecializationListScreen.route;

  static Map<String, String> params(id, {jobId}) {
    return {
      'id': (id is String)
          ? id
          : (id is ItemSerializable ? id.id : throw TypeError()),
      if (jobId != null)
        'jobId': (jobId is String)
            ? jobId
            : (jobId is ItemSerializable ? jobId.id : throw TypeError()),
    };
  }

  static Map<String, String> queryParams({pageIndex, editMode}) {
    return {
      if (pageIndex != null)
        'pageIndex': (pageIndex is String)
            ? pageIndex
            : (pageIndex is ItemSerializable
                ? pageIndex.id
                : throw TypeError()),
      if (editMode != null)
        'editMode': (editMode is String)
            ? editMode
            : (editMode is ItemSerializable ? editMode.id : throw TypeError()),
    };
  }
}

final router = GoRouter(
  redirect: (context, state) =>
      AuthProvider.of(context).isFullySignedIn ? null : Screens.login,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) =>
          AuthProvider.of(context).isFullySignedIn ? null : Screens.login,
    ),
    GoRoute(
      path: Screens.login,
      name: Screens.login,
      builder: (context, state) => const LoginScreen(),
      redirect: (context, state) =>
          AuthProvider.of(context).isFullySignedIn ? '/' : null,
    ),
    GoRoute(
      path: Screens.enterprisesList,
      name: Screens.enterprisesList,
      builder: (context, state) => const EnterprisesListScreen(),
      routes: [
        GoRoute(
          path: Screens.addEnterprise,
          name: Screens.addEnterprise,
          builder: (context, state) => const AddEnterpriseScreen(),
        ),
        GoRoute(
          path: '${Screens.internshipEnrollementFromEnterprise}_id=:id',
          name: Screens.internshipEnrollementFromEnterprise,
          builder: (context, state) => InternshipEnrollmentScreen(
              enterpriseId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '${Screens.enterpriseEvaluationScreen}_id=:id',
          name: Screens.enterpriseEvaluationScreen,
          builder: (context, state) =>
              EnterpriseEvaluationScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '${Screens.enterprise}_id=:id',
          name: Screens.enterprise,
          builder: (context, state) => EnterpriseScreen(
            id: state.pathParameters['id']!,
            pageIndex: int.parse(state.pathParameters['pageIndex'] ?? '0'),
          ),
          routes: [
            GoRoute(
              path: ':jobId',
              name: Screens.jobSstForm,
              builder: (context, state) => JobSstFormScreen(
                enterpriseId: state.pathParameters['id']!,
                jobId: state.pathParameters['jobId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Screens.studentsList,
      name: Screens.studentsList,
      builder: (context, state) => const StudentsListScreen(),
      routes: [
        GoRoute(
          path: '${Screens.student}_id=:id',
          name: Screens.student,
          builder: (context, state) => StudentScreen(
              id: state.pathParameters['id']!,
              initialPage:
                  int.parse(state.uri.queryParameters['pageIndex'] ?? '0')),
        ),
      ],
    ),
    GoRoute(
      path: Screens.supervisionChart,
      name: Screens.supervisionChart,
      builder: (context, state) => const SupervisionChart(),
      routes: [
        GoRoute(
          path: '${Screens.supervisionStudentDetails}/:id',
          name: Screens.supervisionStudentDetails,
          builder: (context, state) => SupervisionStudentDetailsScreen(
            studentId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: Screens.itinerary,
      name: Screens.itinerary,
      builder: (context, state) => const ItineraryMainScreen(),
    ),
    GoRoute(
      path: Screens.tasksToDo,
      name: Screens.tasksToDo,
      builder: (context, state) => const TasksToDoScreen(),
    ),
    GoRoute(
      path: '${Screens.skillEvaluationMainScreen}_id=:id',
      name: Screens.skillEvaluationMainScreen,
      builder: (context, state) => SkillEvaluationMainScreen(
        internshipId: state.pathParameters['id']!,
        editMode: state.uri.queryParameters['editMode']! == '1',
      ),
    ),
    GoRoute(
      path: Screens.skillEvaluationFormScreen,
      name: Screens.skillEvaluationFormScreen,
      builder: (context, state) {
        return SkillEvaluationFormScreen(
          formController: state.extra as SkillEvaluationFormController,
          editMode: state.uri.queryParameters['editMode']! == '1',
        );
      },
    ),
    GoRoute(
      path: Screens.attitudeEvaluationScreen,
      name: Screens.attitudeEvaluationScreen,
      builder: (context, state) => AttitudeEvaluationScreen(
        formController: state.extra as AttitudeEvaluationFormController,
        editMode: state.uri.queryParameters['editMode'] == '1',
      ),
    ),
    GoRoute(
      path: Screens.homeSst,
      name: Screens.homeSst,
      builder: (context, state) => const HomeSstScreen(),
      routes: [
        GoRoute(
          path: Screens.cardsSst,
          name: Screens.cardsSst,
          builder: (context, state) => const SstCardsScreen(),
        ),
        GoRoute(
          path: Screens.incidentHistorySst,
          name: Screens.incidentHistorySst,
          builder: (context, state) => const IncidentHistoryScreen(),
        ),
        GoRoute(
          path: '${Screens.jobSst}_id=:id',
          name: Screens.jobSst,
          builder: (context, state) {
            return SpecializationListScreen(id: state.pathParameters['id']!);
          },
        ),
      ],
    ),
  ],
);
