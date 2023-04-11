import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/common/models/enterprise.dart';
import '/common/providers/enterprises_provider.dart';
import '/common/widgets/dialogs/confirm_pop_dialog.dart';
import '/router.dart';
import 'pages/about_page.dart';
import 'pages/contact_page.dart';
import 'pages/internships_page.dart';
import 'pages/jobs_page.dart';

class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key, required this.id});

  final String id;

  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController =
      TabController(initialIndex: 0, length: 4, vsync: this);

  late IconButton _actionButton;

  final _aboutPageKey = GlobalKey<EnterpriseAboutPageState>();
  final _contactPageKey = GlobalKey<ContactPageState>();
  final _jobsPageKey = GlobalKey<JobsPageState>();
  final _stagePageKey = GlobalKey<InternshipsPageState>();

  bool get _editing =>
      (_aboutPageKey.currentState?.editing ?? false) ||
      (_contactPageKey.currentState?.editing ?? false);

  void _updateActionButton() {
    late Icon icon;

    if (_tabController.index == 0) {
      icon = _aboutPageKey.currentState?.editing ?? false
          ? const Icon(Icons.save)
          : const Icon(Icons.edit);
    } else if (_tabController.index == 1) {
      icon = _contactPageKey.currentState?.editing ?? false
          ? const Icon(Icons.save)
          : const Icon(Icons.edit);
    } else if (_tabController.index == 2) {
      icon = const Icon(Icons.add);
    } else if (_tabController.index == 3) {
      icon = const Icon(Icons.add);
    }
    _actionButton = IconButton(
      icon: icon,
      onPressed: () async {
        if (_tabController.index == 0) {
          _aboutPageKey.currentState?.toggleEdit();
        } else if (_tabController.index == 1) {
          await _contactPageKey.currentState?.toggleEdit();
        } else if (_tabController.index == 2) {
          await _jobsPageKey.currentState?.addJob();
        } else if (_tabController.index == 3) {
          await _stagePageKey.currentState?.addStage();
        }

        _updateActionButton();
      },
    );
    setState(() {});
  }

  Future<void> addInternship(Enterprise enterprise) async {
    if (enterprise.jobs.fold<int>(
            0, (previousValue, e) => e.positionsRemaining(context)) ==
        0) {
      await showDialog(
          context: context,
          builder: (ctx) => const AlertDialog(
                title: Text('Plus de stage disponible'),
                content: Text(
                    'Il n\'y a plus de stage disponible dans cette entreprise'),
              ));
      return;
    }

    GoRouter.of(context).goNamed(
      Screens.internshipEnrollement,
      params: Screens.withId(enterprise.id),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateActionButton();
    _tabController.addListener(() => _updateActionButton());
  }

  @override
  Widget build(BuildContext context) {
    return Selector<EnterprisesProvider, Enterprise>(
      builder: (context, enterprise, _) => Scaffold(
        appBar: AppBar(
          title: Text(enterprise.name),
          actions: [_actionButton],
          bottom: TabBar(
            onTap: (index) async {
              if (!_editing || !_tabController.indexIsChanging) return;

              _tabController.index = _tabController.previousIndex;
              final shouldShow = await ConfirmPopDialog.show(context);
              if (shouldShow) {
                _tabController.animateTo(index);
              }
            },
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.info_outlined), text: 'À propos'),
              Tab(icon: Icon(Icons.contact_phone), text: 'Contact'),
              Tab(icon: Icon(Icons.location_city_rounded), text: 'Métiers'),
              Tab(icon: Icon(Icons.assignment), text: 'Stages'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: _editing ? const NeverScrollableScrollPhysics() : null,
          children: [
            EnterpriseAboutPage(
              key: _aboutPageKey,
              enterprise: enterprise,
              onAddInternshipRequest: addInternship,
            ),
            ContactPage(key: _contactPageKey, enterprise: enterprise),
            JobsPage(key: _jobsPageKey, enterprise: enterprise),
            InternshipsPage(
              key: _stagePageKey,
              enterprise: enterprise,
              onAddIntershipRequest: addInternship,
            ),
          ],
        ),
      ),
      selector: (context, enterprises) => enterprises[widget.id],
    );
  }
}
