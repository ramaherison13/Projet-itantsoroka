import 'package:hive_flutter/hive_flutter.dart';
import '../models/mission_model.dart'; // Assurez-vous d'importer votre modèle Territoire

class TerritoireDatabaseService {
  static const String boxName = 'territoires_box';
  static const String keyAll = 'all';

  // Initialisation de Hive (à appeler dans le main si ce n'est pas déjà fait)
  static Future<void> initDB() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  static Future<void> saveTerritoires(List<Territoire> territoires) async {
    final box = await _getBox();
    // On convertit la liste d'objets en liste de Maps (JSON) pour le stockage local
    final serializedData = territoires.map((t) => t.toJson()).toList();
    await box.put(keyAll, serializedData);
  }

  static Future<List<Territoire>?> getTerritoiresFromDB() async {
    final box = await _getBox();
    final data = box.get(keyAll);
    
    if (data == null) {
      return null;
    }

    try {
      final List<dynamic> list = data;
      return list.map((item) => Territoire.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return null;
    }
  }
}