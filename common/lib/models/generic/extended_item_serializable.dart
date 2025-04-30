import 'package:enhanced_containers_foundation/item_serializable.dart';

abstract class ExtendedItemSerializable<T> extends ItemSerializable {
  T copyWithData(Map<String, dynamic> data);

  ExtendedItemSerializable({super.id});

  @override
  ExtendedItemSerializable.fromSerialized(super.map) : super.fromSerialized();
}
