import 'package:intl/intl.dart';

class DateUtilsHelper {
  static String formatDate(String? dateString) {
    // Vérifier si la date est valide
    if (dateString == null || dateString.isEmpty) {
      return "Date non disponible";
    }

    try {
      final date = DateTime.parse(dateString);
      
      // Crée un formateur de date en français (équivalent de fr-FR avec jour numérique, mois long et année)
      final formatter = DateFormat('d MMMM yyyy', 'fr_FR');
      return formatter.format(date);
    } catch (e) {
      // Retourner "Date non disponible" si la conversion échoue
      return "Date non disponible";
    }
  }

  static String formatLocalDate(int year, int month, int day) {
    final mm = (month + 1).toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  // Renvoie une date locale au format yyyy-mm-dd
  static String getLocalDateString(DateTime date) {
    final year = date.year;
    final month = date.month; // En Dart, date.month va déjà de 1 à 12
    final day = date.day;

    final mm = month < 10 ? '0$month' : '$month';
    final dd = day < 10 ? '0$day' : '$day';

    return '$year-$mm-$dd';
  }
}