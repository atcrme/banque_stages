import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crcrme_banque_stages/screens/ref_sst/common/risk.dart';
import 'package:flutter/services.dart';

abstract class RiskDataFileService {
  static List<Risk> _risks = [];
  static List<Risk> get risks => _risks;

  static Future<void> loadData() async {
    final file = await rootBundle.loadString('assets/risks-data.json');
    final json = jsonDecode(file) as List;

    _risks = List.from(
      json.map((e) => Risk.fromSerialized(e)),
      growable: false,
    );
  }

  static Risk? fromId(String id) {
    return _risks.firstWhereOrNull((risk) => risk.id == id);
  }

  static Risk? fromAbbrv(String abbrv) {
    return _risks.firstWhereOrNull((risk) => risk.abbrv == abbrv);
  }
}
