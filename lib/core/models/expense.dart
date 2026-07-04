class ExpenseModel {
  final String title;
  final double amount;
  final String paidBy; // Name or ID of the member who paid
  final String splitType; // e.g., 'Equal', '%', 'Custom'
  final List<Map<String, dynamic>> splitBetween; // Members involved and their selections/shares
  final String category;

  ExpenseModel({
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.splitBetween,
    this.category = 'Food',
  });

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
