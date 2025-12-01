/// Data model for an assignment (used in forms).
class Assignment {
  final String staffName;
  final String location;
  final String assignedFrom;
  final String admin;
  final DateTime returnDate;
  final DateTime timestamp;

  Assignment({
    required this.staffName,
    required this.location,
    required this.assignedFrom,
    required this.admin,
    required this.returnDate,
    required this.timestamp,
  });
}


