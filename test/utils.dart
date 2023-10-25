import 'package:crcrme_banque_stages/common/providers/enterprises_provider.dart';
import 'package:crcrme_banque_stages/common/providers/internships_provider.dart';
import 'package:crcrme_banque_stages/common/providers/schools_provider.dart';
import 'package:crcrme_banque_stages/common/providers/students_provider.dart';
import 'package:crcrme_banque_stages/common/providers/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

///
/// Overlay are required for widgets such as Tootip
Widget addOverlay(Widget child) {
  return MaterialApp(
    builder: (context, ch) => Overlay(initialEntries: [
      OverlayEntry(builder: (context) => child),
    ]),
  );
}

extension BanqueStageWidgetTester on WidgetTester {
  Future<void> loadDummyData() async {
    // Find the reinitalize data button in the drawer
    await openDrawer();
    await tap(find.text(reinitializedDataButtonText));
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  BuildContext context(Finder finder) => element(finder);

  Future<void> openDrawer() async {
    final drawerIcon = find.byIcon(Icons.menu);
    await tap(drawerIcon);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> closeDrawer() async {
    Navigator.pop(context(find.byType(Drawer)));
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> navigateToScreen(ScreenTest target) async {
    // This function assumes drawer menu is shown
    await openDrawer();
    final targetButton =
        find.ancestor(of: find.text(target.name), matching: find.byType(Card));
    await tap(targetButton);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<BuildContext> contextWithNotifiers({
    bool withSchools = false,
    bool withTeachers = false,
    bool withStudents = false,
    bool withEnterprises = false,
    bool withInternships = false,
  }) async {
    final container = Container();
    await pumpWidgetWithNotifiers(container,
        withSchools: withSchools,
        withTeachers: withTeachers,
        withStudents: withStudents,
        withEnterprises: withEnterprises,
        withInternships: withInternships);
    return context(find.byWidget(container));
  }

  Future<void> pumpWidgetWithNotifiers(
    Widget child, {
    bool withSchools = false,
    bool withTeachers = false,
    bool withStudents = false,
    bool withEnterprises = false,
    bool withInternships = false,
  }) async {
    // Add the providers to the widget tree
    if (withSchools) {
      child = ChangeNotifierProvider<SchoolsProvider>(
        create: (context) => SchoolsProvider(mockMe: true),
        child: child,
      );
    }

    if (withTeachers) {
      child = ChangeNotifierProvider<TeachersProvider>(
        create: (context) => TeachersProvider(mockMe: true),
        child: child,
      );
    }

    if (withStudents) {
      child = ChangeNotifierProvider<StudentsProvider>(
        create: (context) => StudentsProvider(mockMe: true),
        child: child,
      );
    }

    if (withEnterprises) {
      child = ChangeNotifierProvider<EnterprisesProvider>(
        create: (context) => EnterprisesProvider(mockMe: true),
        child: child,
      );
    }

    if (withInternships) {
      child = ChangeNotifierProvider<InternshipsProvider>(
        create: (context) => InternshipsProvider(mockMe: true),
        child: child,
      );
    }

    await pumpWidget(MaterialApp(builder: (ctx, ch) => child));
  }
}

// Add the providers to the widget tree

void expectStyle({
  required Text of,
  required TextStyle comparedTo,
  bool skipColor = false,
  bool skipFontWeight = false,
  bool skipFontSize = false,
}) {
  if (!skipColor) expect(of.style!.color, comparedTo.color);
  if (!skipFontWeight) expect(of.style!.fontWeight, comparedTo.fontWeight);
  if (!skipFontSize) expect(of.style!.fontSize, comparedTo.fontSize);
}

const drawerTitle = 'Banque de stages';
const reinitializedDataButtonText = 'Réinitialiser la base de données';

enum ScreenTest {
  myStudents,
  supervisionTable,
  tasks,
  enterprises,
  healthAndSafetyAtPFAE;

  String get name {
    switch (this) {
      case ScreenTest.myStudents:
        return 'Mes élèves';
      case ScreenTest.supervisionTable:
        return 'Tableau des supervisions';
      case ScreenTest.tasks:
        return 'Tâches à réaliser';
      case ScreenTest.enterprises:
        return 'Entreprises';
      case ScreenTest.healthAndSafetyAtPFAE:
        return 'Santé et Sécurité au PFAE';
    }
  }
}

enum StudentTest {
  cedricMasson,
  thomasCaron,
  mikaelBoucher,
  kevinLeblanc,
  diegoVargas,
  jeanneTremblay,
  vincentPicard,
  vanessaMonette,
  melissaPoulain;

  String get name {
    switch (this) {
      case StudentTest.cedricMasson:
        return 'Cedric Masson';
      case StudentTest.thomasCaron:
        return 'Thomas Caron';
      case StudentTest.mikaelBoucher:
        return 'Mikael Boucher';
      case StudentTest.kevinLeblanc:
        return 'Kevin Leblanc';
      case StudentTest.diegoVargas:
        return 'Diego Vargas';
      case StudentTest.jeanneTremblay:
        return 'Jeanne Tremblay';
      case StudentTest.vincentPicard:
        return 'Vincent Picard';
      case StudentTest.vanessaMonette:
        return 'Vanessa Monette';
      case StudentTest.melissaPoulain:
        return 'Melissa Poulain';
    }
  }

  static int get length => StudentTest.values.length;
}

enum EnterpriseTest {
  metroGagnon,
  jeanCoutu,
  autoCare,
  autoRepair,
  boucherieMarien,
  iga,
  pharmaprix,
  subway,
  walmart,
  leJardinDeJoanie,
  fleuristeJoli;

  String get name {
    switch (this) {
      case EnterpriseTest.metroGagnon:
        return 'Metro Gagnon';
      case EnterpriseTest.jeanCoutu:
        return 'Jean Coutu';
      case EnterpriseTest.autoCare:
        return 'Auto Care';
      case EnterpriseTest.autoRepair:
        return 'Auto Repair';
      case EnterpriseTest.boucherieMarien:
        return 'Boucherie Marien';
      case EnterpriseTest.iga:
        return 'IGA';
      case EnterpriseTest.pharmaprix:
        return 'Pharmaprix';
      case EnterpriseTest.subway:
        return 'Subway';
      case EnterpriseTest.walmart:
        return 'Walmart';
      case EnterpriseTest.leJardinDeJoanie:
        return 'Le jardin de Joanie';
      case EnterpriseTest.fleuristeJoli:
        return 'Fleuriste Joli';
    }
  }

  static int get length => EnterpriseTest.values.length;
}

enum InternshipsTest {
  thomasCaronBoucherieMarien,
  cedaricMassonAutoCare,
  vincentPicardIga,
  diegoVargasMetroGagnon;

  String get studentName {
    switch (this) {
      case InternshipsTest.thomasCaronBoucherieMarien:
        return StudentTest.thomasCaron.name;
      case InternshipsTest.cedaricMassonAutoCare:
        return StudentTest.cedricMasson.name;
      case InternshipsTest.vincentPicardIga:
        return StudentTest.vincentPicard.name;
      case InternshipsTest.diegoVargasMetroGagnon:
        return StudentTest.diegoVargas.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case InternshipsTest.thomasCaronBoucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
      case InternshipsTest.cedaricMassonAutoCare:
        return EnterpriseTest.autoCare.name;
      case InternshipsTest.vincentPicardIga:
        return EnterpriseTest.iga.name;
      case InternshipsTest.diegoVargasMetroGagnon:
        return EnterpriseTest.metroGagnon.name;
    }
  }

  static int get length => InternshipsTest.values.length;
}

enum TasksSstTest {
  boucherieMarien,
  iga,
  metroGagnon;

  String get name {
    switch (this) {
      case TasksSstTest.boucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
      case TasksSstTest.iga:
        return EnterpriseTest.iga.name;
      case TasksSstTest.metroGagnon:
        return EnterpriseTest.metroGagnon.name;
    }
  }

  static int get length => TasksSstTest.values.length;
}

enum TaskEndInternshipTest {
  thomasCaronBoucherieMarien;

  String get name {
    switch (this) {
      case TaskEndInternshipTest.thomasCaronBoucherieMarien:
        return StudentTest.thomasCaron.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case TaskEndInternshipTest.thomasCaronBoucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
    }
  }

  static int get length => TaskEndInternshipTest.values.length;
}

enum TaskPostEvaluationTest {
  vanessaMonettePharmaprix,
  vanessaMonetteJeanCoutu;

  String get studentName {
    switch (this) {
      case TaskPostEvaluationTest.vanessaMonettePharmaprix:
        return StudentTest.vanessaMonette.name;
      case TaskPostEvaluationTest.vanessaMonetteJeanCoutu:
        return StudentTest.vanessaMonette.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case TaskPostEvaluationTest.vanessaMonettePharmaprix:
        return EnterpriseTest.pharmaprix.name;
      case TaskPostEvaluationTest.vanessaMonetteJeanCoutu:
        return EnterpriseTest.jeanCoutu.name;
    }
  }

  static int get length => TaskPostEvaluationTest.values.length;
}

enum TasksTest {
  sst,
  endInternship,
  postEvaluation;

  String get name {
    switch (this) {
      case TasksTest.sst:
        return 'Repérer les risques SST';
      case TasksTest.endInternship:
        return 'Terminer les stages';
      case TasksTest.postEvaluation:
        return 'Faire les évaluations post-stage';
    }
  }

  static int get length =>
      TasksSstTest.length +
      TaskEndInternshipTest.length +
      TaskPostEvaluationTest.length;
}