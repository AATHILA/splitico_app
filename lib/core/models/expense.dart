class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy; // Name or ID of the member who paid
  final String splitType; // e.g., 'Equal', '%', 'Custom'
  final List<Map<String, dynamic>> splitBetween; // Members involved and their selections/shares
  final String category;
  final DateTime dateTime;

  ExpenseModel({
    String? id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.splitBetween,
    this.category = 'Food',
    DateTime? dateTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
  dateTime = dateTime ?? DateTime.now();

  String get emoji {
    switch (category) {
      case 'Food':
        return '🍽️';
      case 'Transport':
        return '🚗';
      case 'Stay':
        return '🏨';
      case 'Activity':
        return '🎯';
      default:
        return '💸';
    }
  }
}
