
class DragAndDropController {
  final DateTime displayedDate;
  final DateTime todayOnly;
  final Future<bool> Function(dynamic mission, DateTime date) moveMissionToDate;
  final Future<bool> Function(dynamic territoire, int missionId, DateTime date) moveTerritoireToDate;

  DragAndDropController({
    required this.displayedDate,
    required this.todayOnly,
    required this.moveMissionToDate,
    required this.moveTerritoireToDate,
  });

  Future<void> handleDragEnd({
    required String draggableId,
    required String droppableId,
    required List<dynamic> missions,
  }) async {
    final today = DateTime(todayOnly.year, todayOnly.month, todayOnly.day);

    final destParts = droppableId.split("-");
    if (destParts.length < 2) return;

    final int dayDest = int.tryParse(destParts[1]) ?? 1;
    final int monthDest = destParts.length > 2 && destParts[2].isNotEmpty 
        ? (int.tryParse(destParts[2]) ?? displayedDate.month) 
        : displayedDate.month;
    final int yearDest = destParts.length > 3 && destParts[3].isNotEmpty 
        ? (int.tryParse(destParts[3]) ?? displayedDate.year) 
        : displayedDate.year;

    final destinationDate = DateTime(yearDest, monthDest, dayDest);
    final cleanDest = DateTime(destinationDate.year, destinationDate.month, destinationDate.day);

    if (cleanDest.isBefore(today)) return;

    if (draggableId.startsWith('territory-')) {
      final parts = draggableId.split('-');
      if (parts.length < 3) return;
      final territoryId = parts[1];
      final missionIdStr = parts[2];
      final missionId = int.tryParse(missionIdStr) ?? 0;

      dynamic mission;
      try {
        mission = missions.firstWhere((m) => (m is Map ? m['id'] : m.id).toString() == missionIdStr);
      } catch (e) {
        mission = null;
      }
      if (mission == null) return;

      final territoiresVisites = mission is Map ? mission['territoiresVisites'] : mission.territoiresVisites;
      if (territoiresVisites == null || territoiresVisites is! List) return;

      dynamic territoire;
      try {
        territoire = territoiresVisites.firstWhere((tv) => (tv is Map ? tv['id'] : tv.id)?.toString() == territoryId);
      } catch (e) {
        territoire = null;
      }
      if (territoire == null) return;

      await moveTerritoireToDate(territoire, missionId, destinationDate);
    } else {
      final missionIdStr = draggableId.split("-")[0];
      dynamic missionMoved;
      try {
        missionMoved = missions.firstWhere((m) => (m is Map ? m['id'] : m.id).toString() == missionIdStr);
      } catch (e) {
        missionMoved = null;
      }
      if (missionMoved == null) return;

      await moveMissionToDate(missionMoved, destinationDate);
    }
  }
}