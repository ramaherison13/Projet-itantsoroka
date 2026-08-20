import 'package:flutter/foundation.dart';

class CalendarFormData {
  int id;
  String titre;
  String dateDebutMission;
  String dateFinMission;
  String district;
  List<dynamic> territoireVisiter;
  List<dynamic> accompagnant;
  String status;
  List<dynamic> territoiresVisites;
  String? userID;

  CalendarFormData({
    required this.id,
    required this.titre,
    required this.dateDebutMission,
    required this.dateFinMission,
    required this.district,
    required this.territoireVisiter,
    required this.accompagnant,
    required this.status,
    required this.territoiresVisites,
    this.userID,
  });

  CalendarFormData copyWith({
    int? id,
    String? titre,
    String? dateDebutMission,
    String? dateFinMission,
    String? district,
    List<dynamic>? territoireVisiter,
    List<dynamic>? accompagnant,
    String? status,
    List<dynamic>? territoiresVisites,
    String? userID,
  }) {
    return CalendarFormData(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      dateDebutMission: dateDebutMission ?? this.dateDebutMission,
      dateFinMission: dateFinMission ?? this.dateFinMission,
      district: district ?? this.district,
      territoireVisiter: territoireVisiter ?? this.territoireVisiter,
      accompagnant: accompagnant ?? this.accompagnant,
      status: status ?? this.status,
      territoiresVisites: territoiresVisites ?? this.territoiresVisites,
      userID: userID ?? this.userID,
    );
  }
}

class CalendarProvider with ChangeNotifier {
  DateTime _currentDate = DateTime.now();
  int? _selectedDay = DateTime.now().day;
  List<dynamic> _missions = [];
  bool _showForm = false;
  
  late CalendarFormData _formData;
  
  String _missionFilter = "all";
  String? _currentMissionFilter = "all";
  int _refreshInterval = 1000;

  bool _isMissionFormOpen = false;
  bool _isMissionPlanningOpen = false;
  int _missionId = 0;
  String _districtUser = '';
  List<dynamic> _users = [];

  CalendarProvider() {
    final now = DateTime.now();
    final formattedDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00.000Z";
    
    _formData = CalendarFormData(
      id: 0,
      titre: "",
      dateDebutMission: formattedDate,
      dateFinMission: formattedDate,
      district: '{"code":"5","nom":"District 5"}',
      territoireVisiter: [],
      accompagnant: [],
      status: "Planifiée",
      territoiresVisites: [],
      userID: null,
    );
  }

  // Getters
  DateTime get currentDate => _currentDate;
  int? get selectedDay => _selectedDay;
  List<dynamic> get missions => _missions;
  bool get showForm => _showForm;
  CalendarFormData get formData => _formData;
  String get missionFilter => _missionFilter;
  String? get currentMissionFilter => _currentMissionFilter;
  int? get refreshInterval => _refreshInterval;
  bool get isMissionFormOpen => _isMissionFormOpen;
  bool get isMissionPlanningOpen => _isMissionPlanningOpen;
  int get missionId => _missionId;
  String get districtUser => _districtUser;
  List<dynamic> get users => _users;

  // Setters / Actions
  void setCurrentDate(String dateStr) {
    _currentDate = DateTime.parse(dateStr);
    notifyListeners();
  }

  void setSelectedDay(int? day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setMissionId(int id) {
    _missionId = id;
    notifyListeners();
  }

  void setDistrictUser(String district) {
    _districtUser = district;
    notifyListeners();
  }

  void setShowForm(bool show) {
    _showForm = show;
    notifyListeners();
  }

  void setFormData({
    int? id,
    String? titre,
    String? dateDebutMission,
    String? dateFinMission,
    dynamic district,
    List<dynamic>? territoireVisiter,
    List<dynamic>? accompagnant,
    String? status,
    List<dynamic>? territoiresVisites,
    String? userID,
  }) {
    String updatedDistrict = _formData.district;
    if (district != null) {
      updatedDistrict = district is String ? district : district.toString();
    }

    _formData = _formData.copyWith(
      id: id ?? _formData.id,
      titre: titre ?? _formData.titre,
      dateDebutMission: dateDebutMission ?? _formData.dateDebutMission,
      dateFinMission: dateFinMission ?? _formData.dateFinMission,
      district: updatedDistrict,
      territoireVisiter: territoireVisiter ?? _formData.territoireVisiter,
      accompagnant: accompagnant ?? _formData.accompagnant,
      status: status ?? _formData.status,
      territoiresVisites: territoiresVisites ?? _formData.territoiresVisites,
      userID: userID ?? _formData.userID,
    );
    notifyListeners();
  }

  void setMissions(List<dynamic> newMissions) {
    _missions = newMissions;
    notifyListeners();
  }

  void setAllUserDistrict(List<dynamic> newUsers) {
    _users = newUsers;
    notifyListeners();
  }

  void addMission(dynamic mission) {
    _missions.add(mission);
    notifyListeners();
  }

  void setMissionFilter(String filter) {
    _missionFilter = filter;
    notifyListeners();
  }

  void setCurrentMissionFilter(String? filter) {
    _currentMissionFilter = filter;
    notifyListeners();
  }

  void setRefreshInterval(int? interval) {
    if (interval != null) {
      _refreshInterval = interval;
      notifyListeners();
    }
  }

  void openMissionForm() {
    _isMissionFormOpen = true;
    notifyListeners();
  }

  void closeMissionForm() {
    _isMissionFormOpen = false;
    notifyListeners();
  }

  void openMissionPlanning() {
    _isMissionPlanningOpen = true;
    notifyListeners();
  }

  void closeMissionPlanning() {
    _isMissionPlanningOpen = false;
    notifyListeners();
  }
}