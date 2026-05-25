import 'dart:convert';
import 'store.dart';

class StorePreferencesCodec {
  static List<Store> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((entry) => Store.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<Store> stores) {
    return jsonEncode(stores.map((entry) => entry.toJson()).toList());
  }
}
