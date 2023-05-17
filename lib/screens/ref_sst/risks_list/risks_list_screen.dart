import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:crcrme_banque_stages/misc/risk_data_file_service.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/risk_card/risk_card_screen.dart';
import 'widgets/clickable_risk_tile.dart';

class SstCardsScreen extends StatefulWidget {
  const SstCardsScreen({Key? key}) : super(key: key);

  static const route = '/sst-cards';

  @override
  State<SstCardsScreen> createState() => _SstCardsScreenState();
}

class _SstCardsScreenState extends State<SstCardsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
      vsync: this,
      length: 1 + RiskDataFileService.risks.length,
      animationDuration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _tabController.animation!.addListener(() {
      if (_tabController.animation!.value.round() != _tabController.index) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _navigate(int page) {
    _tabController.index = page;
    setState(() {});
  }

  void _onTapBack() {
    if (_tabController.index != 0) {
      _tabController.index = 0;
      setState(() {});
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _appBarBuilder(int index) {
    return AutoSizeText(
      index == 0
          ? 'Fiches de risques'
          : '$index. ${RiskDataFileService.risks[index - 1].nameHeader}',
      maxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _appBarBuilder(_tabController.animation!.value
            .round()), // animation is more reactive than index
        leading: IconButton(
            onPressed: _onTapBack, icon: const Icon(Icons.arrow_back)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MenuRisksFormScreen(navigate: _navigate),
          ...RiskDataFileService.risks
              .map<Widget>((risk) => RisksCardsScreen(id: risk.id))
              .toList(),
        ],
      ),
    );
  }
}

class _MenuRisksFormScreen extends StatelessWidget {
  const _MenuRisksFormScreen({required this.navigate});

  final Function(int) navigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: RiskDataFileService.risks
          .map((e) =>
              ClickableRiskTile(e, onTap: (risk) => navigate(risk.number)))
          .toList(),
    );
  }
}
