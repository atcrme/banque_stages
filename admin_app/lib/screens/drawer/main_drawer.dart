import 'package:admin_app/dummy_data.dart';
import 'package:admin_app/screens/router.dart';
import 'package:common/models/generic/access_level.dart';
import 'package:common_flutter/providers/admins_provider.dart';
import 'package:common_flutter/providers/auth_provider.dart';
import 'package:common_flutter/providers/enterprises_provider.dart';
import 'package:common_flutter/providers/internships_provider.dart';
import 'package:common_flutter/providers/school_boards_provider.dart';
import 'package:common_flutter/providers/students_provider.dart';
import 'package:common_flutter/providers/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  void _logOut(BuildContext context) async {
    await AuthProvider.of(context).signOut();
    if (!context.mounted) return;

    await SchoolBoardsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    InternshipsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    await Future.wait([
      SchoolBoardsProvider.of(context, listen: false).disconnect(),
      InternshipsProvider.of(context, listen: false).disconnect(),
      StudentsProvider.of(context, listen: false).disconnect(),
      EnterprisesProvider.of(context, listen: false).disconnect(),
      TeachersProvider.of(context, listen: false).disconnect(),
      AdminsProvider.of(context, listen: false).disconnect(),
    ]);
    if (!context.mounted) return;

    // Pop the drawer and navigate to the login screen
    Navigator.pop(context);
    GoRouter.of(context).goNamed(Screens.login);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);

    return Drawer(
      child: Scaffold(
        appBar: AppBar(title: const Text('Banque de Stages')),
        body:
            authProvider.isFullySignedIn
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        if (authProvider.databaseAccessLevel >=
                            AccessLevel.admin)
                          const _DrawerItem(
                            titleText: 'Écoles',
                            icon: Icons.school,
                            route: Screens.schoolBoardsListScreen,
                          ),
                        if (authProvider.databaseAccessLevel >=
                            AccessLevel.superAdmin)
                          const _DrawerItem(
                            titleText: 'Administrateurs·trices',
                            icon: Icons.admin_panel_settings,
                            route: Screens.adminsListScreen,
                          ),
                        const _DrawerItem(
                          titleText: 'Enseignant·e·s',
                          icon: Icons.person,
                          route: Screens.teachersListScreen,
                        ),
                        const _DrawerItem(
                          titleText: 'Élèves',
                          icon: Icons.person,
                          route: Screens.studentsListScreen,
                        ),
                        const _DrawerItem(
                          titleText: 'Entreprises',
                          icon: Icons.business,
                          route: Screens.enterprisesListScreen,
                        ),
                        const _DrawerItem(
                          titleText: 'Stages',
                          icon: Icons.work,
                          route: Screens.internshipsListScreen,
                        ),
                        _DrawerItem(
                          titleText: 'Se déconnecter',
                          icon: Icons.logout,
                          onTap: () => _logOut(context),
                        ),
                      ],
                    ),
                    if (authProvider.databaseAccessLevel ==
                        AccessLevel.superAdmin)
                      _DrawerItem(
                        titleText: 'Réinitialiser la base de données',
                        icon: Icons.restore_from_trash_outlined,
                        onTap: () async {
                          await resetDummyData(context);
                          if (context.mounted) Navigator.pop(context);
                        },
                        tileColor: Colors.red,
                      ),
                  ],
                )
                : authProvider.isAuthenticatorSignedIn
                ? _DrawerItem(
                  titleText: 'Se déconnecter',
                  icon: Icons.logout,
                  onTap: () => _logOut(context),
                )
                : Container(),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.titleText,
    this.icon,
    this.route,
    this.onTap,
    this.tileColor,
  }) : assert(
         (route != null || onTap != null) && (route == null || onTap == null),
         'One parameter has to be null while the other one is not.',
       );

  final String? route;
  final IconData? icon;
  final String titleText;
  final void Function()? onTap;
  final Color? tileColor;

  @override
  Widget build(BuildContext context) {
    final isCurrentlySelectedTile =
        ModalRoute.of(context)!.settings.name == route;
    return Card(
      child: ListTile(
        onTap:
            onTap ??
            () {
              if (isCurrentlySelectedTile) Navigator.pop(context);
              GoRouter.of(context).goNamed(route!);
            },
        tileColor:
            isCurrentlySelectedTile
                ? Theme.of(context).primaryColor.withAlpha(40)
                : tileColor,
        leading:
            icon == null
                ? null
                : Icon(
                  icon,
                  color:
                      isCurrentlySelectedTile
                          ? Theme.of(context).primaryColor
                          : null,
                ),
        title: Text(titleText, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
