import 'package:crcrme_banque_stages/crcrme_enhanced_containers/lib/list_firebase.dart';

import '/common/models/enterprise.dart';

class EnterprisesProvider extends ListFirebase<Enterprise> {
  EnterprisesProvider()
      : super(availableIdsPath: "enterprises-list", dataPath: "enterprises");

  @override
  Enterprise deserializeItem(data) {
    return Enterprise.fromSerialized(
        (data as Map).map((key, value) => MapEntry(key.toString(), value)));
  }
}
