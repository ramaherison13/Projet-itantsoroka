import 'package:flutter/foundation.dart';

class CalendarLogicController with ChangeNotifier {
  DateTime displayedDate;
  final DateTime todayOnly;
  final List<dynamic> missions;
  final Function(String) setCurrentDateAction;
  final Function(List<dynamic>) setMissionsAction;

  Set<int> expandedMissionTerritoires = {};

  CalendarLogicController({
    required DateTime initialCurrentDate,
    required this.todayOnly,
    required this.missions,
    required this.setCurrentDateAction,
    required this.setMissionsAction,
  }) : displayedDate = DateTime(initialCurrentDate.year, initialCurrentDate.month, initialCurrentDate.day) {
    setCurrentDateAction(displayedDate.toIso8601String());
  }

  void updateDisplayedDate(DateTime date) {
    displayedDate = date;
    setCurrentDateAction(date.toIso8601String());
    notifyListeners();
  }

  void handlePrevMonth() {
    updateDisplayedDate(DateTime(displayedDate.year, displayedDate.month - 1, 1));
  }

  void handleNextMonth() {
    updateDisplayedDate(DateTime(displayedDate.year, displayedDate.month + 1, 1));
  }

  void handlePrevYear() {
    updateDisplayedDate(DateTime(displayedDate.year - 1, displayedDate.month, 1));
  }

  void handleNextYear() {
    updateDisplayedDate(DateTime(displayedDate.year + 1, displayedDate.month, 1));
  }

  void toggleMissionTerritoireExpand(int missionId) {
    if (expandedMissionTerritoires.contains(missionId)) {
      expandedMissionTerritoires.remove(missionId);
    } else {
      expandedMissionTerritoires.add(missionId);
    }
    notifyListeners();
  }

  Future<bool> moveMissionToDate(dynamic mission, DateTime destinationDate) async {
    final cleanToday = DateTime(todayOnly.year, todayOnly.month, todayOnly.day);
    final cleanDest = DateTime(destinationDate.year, destinationDate.month, destinationDate.day);

    if (cleanDest.isBefore(cleanToday)) return false;

    // Simulation de MissionService.moveMission
    final missionId = mission is Map ? mission['id'] : mission.id;
    final updatedMissionData = {'date_debut_mission': destinationDate.toIso8601String()};
    
    final previousMissions = List.from(missions);
    final updatedMissions = missions.map((m) {
      final mId = m is Map ? m['id'] : m.id;
      if (mId == missionId) {
        if (m is Map) {
          return {...m, ...updatedMissionData};
        }
      }
      return m;
    }).toList();

    setMissionsAction(updatedMissions);
    notifyListeners();

    try {
      // Simulation MissionService.updateMission(missionId, updatedMissionData);
      updateDisplayedDate(destinationDate);
      return true;
    } catch (error) {
      setMissionsAction(previousMissions);
      notifyListeners();
      return false;
    }
  }

  Future<bool> moveTerritoireToDate(dynamic territoire, int missionId, DateTime destinationDate) async {
    final territoireId = territoire is Map ? territoire['id'] : territoire.id;
    if (territoireId == null) return false;

    final newDateVisite = "${destinationDate.year}-${destinationDate.month.toString().padLeft(2, '0')}-${destinationDate.day.toString().padLeft(2, '0')}";

    final previousMissions = List.from(missions);
    final updatedMissions = missions.map((m) {
      final mId = m is Map ? m['id'] : m.id;
      if (mId == missionId && (m is Map ? m['territoiresVisites'] : null) != null) {
        final List visites = List.from(m['territoiresVisites']);
        final newVisites = visites.map((tv) {
          final tvId = tv is Map ? tv['id'] : tv.id;
          if (tvId == territoireId) {
            if (tv is Map) {
              return {...tv, 'date_visite': newDateVisite};
            }
          }
          return tv;
        }).toList();
        return {...m, 'territoiresVisites': newVisites};
      }
      return m;
    }).toList();

    setMissionsAction(updatedMissions);
    notifyListeners();

    try {
      // Simulation MissionService.updateTerritoireVisite(territoireId, {'date_visite': newDateVisite});
      updateDisplayedDate(destinationDate);
      return true;
    } catch (error) {
      setMissionsAction(previousMissions);
      notifyListeners();
      return false;
    }
  }
}