import '../models/mission_model.dart'; // Assurez-vous d'importer votre modèle Mission

class CalendarUtils {
  // Nombre de jours dans le mois
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Jour de la semaine du premier jour (lundi = 0)
  static int getFirstDayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1).weekday;
    return firstDay == 7 ? 6 : firstDay - 1;
  }

  // Obtenir les missions pour une date donnée (UNIQUEMENT à la date de début)
  static List<Mission> getMissionsForDate(List<Mission> missions, DateTime date) {
    return missions.where((m) {
      if (m.dateDebutMission.isEmpty) return false;
      final startDate = DateTime.parse(m.dateDebutMission);
      
      final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedTarget = DateTime(date.year, date.month, date.day);

      return normalizedStart.isAtSameMomentAs(normalizedTarget);
    }).toList();
  }

  // Si vous voulez garder l'ancienne fonction pour afficher sur toute la durée
  static List<Mission> getMissionsForDateRange(List<Mission> missions, DateTime date) {
    return missions.where((m) {
      if (m.dateDebutMission.isEmpty) return false;
      final start = DateTime.parse(m.dateDebutMission);
      final end = DateTime.parse(m.dateFinMission ?? m.dateDebutMission);

      final normalizedStart = DateTime(start.year, start.month, start.day);
      final normalizedEnd = DateTime(end.year, end.month, end.day);
      final normalizedTarget = DateTime(date.year, date.month, date.day);

      return (normalizedTarget.isAfter(normalizedStart) || normalizedTarget.isAtSameMomentAs(normalizedStart)) &&
             (normalizedTarget.isBefore(normalizedEnd) || normalizedTarget.isAtSameMomentAs(normalizedEnd));
    }).toList();
  }

  // Navigation entre les mois
  static DateTime navigateMonth(DateTime currentDate, String direction) {
    final newMonth = direction == "next" ? currentDate.month + 1 : currentDate.month - 1;
    return DateTime(currentDate.year, newMonth, 1);
  }

  static const List<String> weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
  
  static const List<String> monthNames = [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Août",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre",
  ];

  static List<Mission> filterMissions(List<Mission> missions, String missionFilter) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    switch (missionFilter) {
      case "all":
        return missions;

      case "today":
        return missions.where((mission) => mission.dateDebutMission.startsWith(todayStr)).toList();

      case "week":
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        
        return missions.where((mission) {
          if (mission.dateDebutMission.isEmpty) return false;
          final missionDate = DateTime.parse(mission.dateDebutMission);
          return (missionDate.isAfter(weekStart) || missionDate.isAtSameMomentAs(weekStart)) &&
                 (missionDate.isBefore(weekEnd) || missionDate.isAtSameMomentAs(weekEnd));
        }).toList();

      case "month":
        return missions.where((mission) {
          if (mission.dateDebutMission.isEmpty) return false;
          final missionDate = DateTime.parse(mission.dateDebutMission);
          return missionDate.month == now.month && missionDate.year == now.year;
        }).toList();

      case "Planifier":
        return missions.where((mission) => mission.status == "Planifier").toList();

      case "Non planifier":
        return missions.where((mission) => mission.status == "Non planifier").toList();

      default:
        return missions;
    }
  }
}