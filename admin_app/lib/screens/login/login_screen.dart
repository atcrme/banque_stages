import 'package:admin_app/screens/drawer/main_drawer.dart';
import 'package:admin_app/screens/router.dart';
import 'package:common_flutter/helpers/form_service.dart';
import 'package:common_flutter/providers/admins_provider.dart';
import 'package:common_flutter/providers/auth_provider.dart';
import 'package:common_flutter/providers/enterprises_provider.dart';
import 'package:common_flutter/providers/internships_provider.dart';
import 'package:common_flutter/providers/school_boards_provider.dart';
import 'package:common_flutter/providers/students_provider.dart';
import 'package:common_flutter/providers/teachers_provider.dart';
import 'package:common_flutter/widgets/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _password;

  void _signIn() async {
    if (!FormService.validateForm(_formKey, save: true)) return;

    try {
      await AuthProvider.of(
        context,
      ).signInWithEmailAndPassword(email: _email!, password: _password!);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, message: 'Erreur de connexion');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Calling the provider jumps start the authentication process and ensures data arrival
    final schoolBoardsProvider = SchoolBoardsProvider.of(context, listen: true);
    AdminsProvider.of(context, listen: false);
    EnterprisesProvider.of(context, listen: false);
    InternshipsProvider.of(context, listen: false);
    StudentsProvider.of(context, listen: false);
    TeachersProvider.of(context, listen: false);

    final authProvider = AuthProvider.of(context, listen: true);
    if (authProvider.isFullySignedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => GoRouter.of(context).goNamed(Screens.home),
      );
    }

    return PopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Banque de stages')),
        drawer:
            authProvider.isAuthenticatorSignedIn ? const MainDrawer() : null,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child:
                  authProvider.isAuthenticatorSignedIn
                      ? Center(
                        child: Text(
                          schoolBoardsProvider.hasProblemConnecting
                              ? 'Impossible de se connecter à la base de données, \n'
                                  'vérifiez votre connexion internet.'
                              : schoolBoardsProvider.connexionRefused
                              ? 'Connexion refusée, \n'
                                  'veuillez contacter votre administrateur'
                              : 'Connexion en cours...',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                      : Column(
                        children: [
                          Text(
                            'Connectez-vous à votre compte avant de poursuivre.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.mail),
                              labelText: 'Courriel',
                            ),
                            validator: FormService.emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (email) => _email = email,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.lock),
                              labelText: 'Mot de passe',
                            ),
                            validator: FormService.passwordValidator,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            onSaved: (password) => _password = password,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _signIn,
                            child: const Text('Se connecter'),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
