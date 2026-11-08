// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Repository with Prototype Scope and Lifecycle Hooks
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';

abstract interface class ItemsRepository {
  List<String> getItems();
  void addItem(String item);
}

@Repository('itemsRepository')
@Scope('prototype')
@Description('Prototype-scoped items repository')
@Role(DesignRole.APPLICATION)
class DefaultItemsRepository implements ItemsRepository {
  final List<String> _items = ['alpha', 'beta', 'gamma'];

  DefaultItemsRepository();

  @override
  List<String> getItems() => List.unmodifiable(_items);

  @override
  void addItem(String item) {
    _items.add(item);
  }
}