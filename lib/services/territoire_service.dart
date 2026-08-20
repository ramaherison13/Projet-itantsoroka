class TerritoireService {
  static String getTerritoireName(Map<String, dynamic> territoire) {
    return territoire['name'] ?? '';
  }

  static List<Map<String, dynamic>> groupTerritoiresByMission(List<dynamic> missions, DateTime date) {
    final List<Map<String, dynamic>> territoiresVisitesForDay = [];

    for (var m in missions) {
      final territoiresVisites = m['territoiresVisites'] as List<dynamic>?;
      if (territoiresVisites != null) {
        for (var tv in territoiresVisites) {
          final dateVisiteStr = tv['date_visite'];
          if (dateVisiteStr != null) {
            final tvDate = DateTime.parse(dateVisiteStr);
            if (
              tvDate.day == date.day &&
              tvDate.month == date.month &&
              tvDate.year == date.year
            ) {
              territoiresVisitesForDay.add({
                ...tv,
                'missionId': m['id'],
                'missionTitre': m['titre'],
                'type': 'territoire',
              });
            }
          }
        }
      }
    }

    return territoiresVisitesForDay;
  }
}