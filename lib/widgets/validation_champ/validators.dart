
// -------------------------
// Regex pour les validations de base
// -------------------------

final RegExp nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$");
final RegExp emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
final RegExp phoneRegex = RegExp(r"^(032|033|034|037|038|039|020)\d{7}$");

// -------------------------
// Validateurs de champs simples
// -------------------------

String? validateName(String value) {
  return nameRegex.hasMatch(value) ? null : "Nom invalide";
}

String? validateEmail(String value) {
  return emailRegex.hasMatch(value) ? null : "Email invalide";
}

String? validatePhone(String value) {
  return phoneRegex.hasMatch(value) ? null : "Numéro de téléphone invalide";
}

String? requiredText(String value, String fieldName, {int minLength = 1, int maxLength = 255}) {
  if (value.trim().length < minLength) {
    return "$fieldName est obligatoire";
  }
  if (value.trim().length > maxLength) {
    return "$fieldName ne doit pas dépasser $maxLength caractères";
  }
  return null;
}

String? requiredSelect(String value, String fieldName) {
  if (value.trim().isEmpty) {
    return "$fieldName est obligatoire";
  }
  return null;
}

// -------------------------
// Validateurs de dates
// -------------------------

bool isFutureDate(String dateString) {
  final DateTime? date = DateTime.tryParse(dateString);
  if (date == null) return false;
  return date.isAfter(DateTime.now());
}

String? validateDates(String startDate, String endDate, {String fieldNameStart = 'Date de début', String fieldNameEnd = 'Date de fin'}) {
  if (startDate.isEmpty) return "$fieldNameStart est obligatoire";
  if (endDate.isEmpty) return "$fieldNameEnd est obligatoire";
  
  final DateTime? start = DateTime.tryParse(startDate);
  final DateTime? end = DateTime.tryParse(endDate);
  
  if (start == null || end == null) return "Format de date invalide";
  if (end.isBefore(start)) return "$fieldNameEnd doit être après $fieldNameStart";
  
  return null;
}

String? validateDeadline(String deadline, String startDate) {
  if (deadline.isEmpty) return "La date limite est obligatoire";
  
  final DateTime? start = DateTime.tryParse(startDate);
  final DateTime? end = DateTime.tryParse(deadline);
  
  if (start == null || end == null) return "Format de date invalide";
  if (end.isBefore(start)) return "La date limite doit être après la date de début";
  
  return null;
}

// -------------------------
// Validateurs de fichiers
// -------------------------

class FileInfoMock {
  final String mimeType;
  final int sizeInBytes;

  const FileInfoMock({required this.mimeType, required this.sizeInBytes});
}

String? validateImageFile(FileInfoMock? file) {
  if (file == null) return null;
  const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
  if (!allowedTypes.contains(file.mimeType)) {
    return "Format non supporté. Seuls JPG, PNG et WEBP sont autorisés.";
  }
  const maxSizeMB = 5;
  if (file.sizeInBytes > maxSizeMB * 1024 * 1024) {
    return "Fichier trop volumineux. Maximum ${maxSizeMB}MB autorisé.";
  }
  return null;
}

String? validateMonographieFile(FileInfoMock? file) {
  if (file == null) return "Veuillez sélectionner un fichier de monographie.";
  const allowedTypes = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain",
  ];
  if (!allowedTypes.contains(file.mimeType)) {
    return "Format non supporté. Seuls PDF, DOC, DOCX et TXT sont autorisés.";
  }
  const maxSizeMB = 10;
  if (file.sizeInBytes > maxSizeMB * 1024 * 1024) {
    return "Fichier trop volumineux. Maximum ${maxSizeMB}MB autorisé.";
  }
  return null;
}

// -------------------------
// Validateurs de formulaires complexes & Spécifiques
// -------------------------

typedef ValidationErrors = Map<String, String>;

class ProposalFormModel {
  final String contenu;
  final String meetingId;

  const ProposalFormModel({required this.contenu, required this.meetingId});

  ValidationErrors validate() {
    final ValidationErrors errors = {};
    if (contenu.isEmpty) {
      errors['contenu'] = "Le contenu de la proposition est requis";
    } else if (contenu.length > 255) {
      errors['contenu'] = "Le contenu ne doit pas dépasser 255 caractères";
    }

    if (meetingId.isEmpty) {
      errors['meetingId'] = "Veuillez sélectionner une réunion";
    }
    return errors;
  }
}

String? validateBudget(double? budget) {
  if (budget == null) return "Le budget est obligatoire";
  if (budget < 0) return "Le budget doit être positif";
  return null;
}

String? validatePartners(List<String> partners) {
  if (partners.isEmpty) return "Au moins un partenaire est requis";
  return null;
}

String? validateVisibility(String visibility) {
  if (visibility.isEmpty) return "La visibilité est obligatoire";
  if (!['public', 'private'].contains(visibility)) return "La visibilité est invalide";
  return null;
}

String? validateReminderDays(int? days) {
  if (days == null) return "Veuillez entrer un nombre de jours";
  if (days < 1 || days > 5) return "Le nombre de jours doit être compris entre 1 et 5";
  return null;
}

String? validateResume(String resume) {
  if (resume.trim().isEmpty) return "Le résumé est obligatoire.";
  const minLength = 20;
  if (resume.trim().length < minLength) return "Le résumé doit contenir au moins $minLength caractères.";
  return null;
}

String? validateDetails(String details) {
  if (details.trim().isEmpty) return "Les détails du territoire sont obligatoires.";
  const minLength = 50;
  if (details.trim().length < minLength) return "Les détails doivent contenir au moins $minLength caractères.";
  return null;
}

String? validateDistrict(String districtId) {
  if (districtId.isEmpty || districtId == "0") return "Veuillez sélectionner un district.";
  return null;
}

String? validateSearchTerm(String term) {
  if (term.trim().isEmpty) return "Veuillez entrer un terme de recherche.";
  final RegExp invalidChars = RegExp(r"[^a-zA-Z0-9\s\-À-ÿ]");
  if (invalidChars.hasMatch(term)) return "Le terme de recherche contient des caractères non autorisés.";
  const minLength = 2;
  if (term.trim().length < minLength) return "Le terme de recherche doit contenir au moins $minLength caractères.";
  return null;
}

String? validateSearchType(String type) {
  const allowedTypes = ["communes", "districts"];
  if (!allowedTypes.contains(type)) return "Type de recherche invalide.";
  return null;
}

String? validateMissionTitle(String titre) {
  if (titre.trim().isEmpty) return "Le titre de la mission est obligatoire.";
  if (titre.trim().length < 5) return "Le titre de la mission doit contenir au moins 5 caractères.";
  if (titre.trim().length > 100) return "Le titre de la mission ne doit pas dépasser 100 caractères.";
  return null;
}

String? validateSelectedTerritoires(List<Map<String, dynamic>> territoires) {
  if (territoires.isEmpty) return "Au moins un territoire doit être sélectionné.";
  return null;
}

String? validateSelectedParticipants(List<Map<String, dynamic>> participants) {
  if (participants.isEmpty) return "Au moins un participant doit être sélectionné.";
  return null;
}

String? validateAutoGenerateItinerary(bool? autoGenerate) {
  if (autoGenerate == null) return "L'option de génération d'itinéraire doit être définie.";
  return null;
}

ValidationErrors validateMissionForm({
  required String titre,
  required String dateDebutMission,
  required String dateFinMission,
  required List<Map<String, dynamic>> territoires,
  required List<Map<String, dynamic>> participants,
  required bool autoGenerateItinerary,
}) {
  final ValidationErrors errors = {};

  final titreError = validateMissionTitle(titre);
  if (titreError != null) errors['titre'] = titreError;

  final datesError = validateDates(dateDebutMission, dateFinMission, fieldNameStart: "Date de début de la mission", fieldNameEnd: "Date de fin de la mission");
  if (datesError != null) errors['date_debut_mission'] = datesError;

  final territoiresError = validateSelectedTerritoires(territoires);
  if (territoiresError != null) errors['territoires'] = territoiresError;

  final participantsError = validateSelectedParticipants(participants);
  if (participantsError != null) errors['participants'] = participantsError;

  final itineraryError = validateAutoGenerateItinerary(autoGenerateItinerary);
  if (itineraryError != null) errors['autoGenerateItinerary'] = itineraryError;

  return errors;
}

List<String> validateMonographieForm({
  FileInfoMock? file,
  required String resume,
  required String details,
  required String districtId,
}) {
  final List<String> errors = [];
  final fileError = validateMonographieFile(file);
  if (fileError != null) errors.add(fileError);
  
  final resumeError = validateResume(resume);
  if (resumeError != null) errors.add(resumeError);
  
  final detailsError = validateDetails(details);
  if (detailsError != null) errors.add(detailsError);
  
  final districtError = validateDistrict(districtId);
  if (districtError != null) errors.add(districtError);
  
  return errors;
}

List<String> validateSearchForm({
  required String term,
  required String type,
}) {
  final List<String> errors = [];
  final termError = validateSearchTerm(term);
  if (termError != null) errors.add(termError);
  
  final typeError = validateSearchType(type);
  if (typeError != null) errors.add(typeError);
  
  return errors;
}

List<String> validateRessource({
  required String nom,
  required String territoireCode,
  required String typeRessourceId,
}) {
  final List<String> errors = [];
  final RegExp allowedChars = RegExp(r"^[a-zA-Z0-9\s\-À-ÿ]+$");

  if (nom.trim().isEmpty) {
    errors.add("Le nom de la ressource est requis.");
  } else if (nom.trim().length < 3) {
    errors.add("Le nom de la ressource doit contenir au moins 3 caractères.");
  } else if (!allowedChars.hasMatch(nom)) {
    errors.add("Le nom contient des caractères non autorisés.");
  }

  if (territoireCode.trim().isEmpty) {
    errors.add("Le code territoire est requis.");
  }

  if (typeRessourceId.trim().isEmpty) {
    errors.add("Le type de ressource doit être sélectionné.");
  }

  return errors;
}

List<String> validateReservation({
  required List<String> selectedRessources,
  required String dateDebut,
  required String dateFin,
  required String raisonAffectation,
}) {
  final List<String> errors = [];
  if (dateDebut.isEmpty) errors.add("La date de début est requise.");
  if (dateFin.isEmpty) errors.add("La date de fin est requise.");

  final DateTime? start = DateTime.tryParse(dateDebut);
  final DateTime? end = DateTime.tryParse(dateFin);

  if (start != null && end != null) {
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      errors.add("La date de fin doit être postérieure à la date de début.");
    }
  }

  if (start != null && start.isBefore(DateTime.now())) {
    errors.add("La date de début ne peut pas être dans le passé.");
  }

  if (raisonAffectation.trim().length < 5) {
    errors.add("La raison de la réservation doit contenir au moins 5 caractères.");
  }

  if (selectedRessources.isEmpty) {
    errors.add("Vous devez sélectionner au moins une ressource.");
  }

  return errors;
}

ValidationErrors validateEntite({
  required String nom,
  required String categorie,
  String? description,
}) {
  final ValidationErrors errors = {};
  if (nom.trim().isEmpty) errors['nom'] = "Le nom de l'entité est obligatoire";
  if (categorie.trim().isEmpty) errors['categorie'] = "La catégorie est obligatoire";
  return errors;
}

ValidationErrors validateProgramme({
  required String codeProgramme,
  required String nom,
  required dynamic entiteId,
  String? description,
}) {
  final ValidationErrors errors = {};
  if (codeProgramme.trim().isEmpty) errors['codeProgramme'] = "Le code du programme est obligatoire";
  if (nom.trim().isEmpty) errors['nom'] = "Le nom du programme est obligatoire";
  if (entiteId == null || entiteId.toString().trim().isEmpty) errors['entiteId'] = "Vous devez sélectionner une entité";
  return errors;
}

ValidationErrors validateStd({
  required String codeSoa,
  required String nom,
  required String codeProgramme,
  required String territoireType,
  required dynamic territoireId,
  String? description,
}) {
  final ValidationErrors errors = {};
  if (codeSoa.trim().isEmpty) errors['codeSoa'] = "Le code de la STD est obligatoire";
  if (nom.trim().isEmpty) errors['nom'] = "Le nom de la STD est obligatoire";
  if (codeProgramme.trim().isEmpty) errors['codeProgramme'] = "Vous devez sélectionner un programme";
  if (territoireType.isNotEmpty && (territoireId == null || territoireId.toString().trim().isEmpty)) {
    errors['territoireId'] = "Vous devez sélectionner un territoire";
  }
  return errors;
}