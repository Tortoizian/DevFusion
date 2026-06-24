import '../models/expense_model.dart';

class CategoryClassifier {
  static const _keywords = {
    ExpenseCategory.food: [
      'pizza', 'swiggy', 'zomato', 'dominos', 'dinner', 'lunch',
      'breakfast', 'cafe', 'food'
    ],
    ExpenseCategory.travel: [
      'petrol', 'uber', 'ola', 'cab', 'flight', 'train', 'bus', 'goa'
    ],
    ExpenseCategory.rent: ['rent', 'airbnb', 'hotel', 'hostel'],
    ExpenseCategory.utilities: ['electricity', 'wifi', 'internet', 'water', 'gas'],
    ExpenseCategory.entertainment: ['movie', 'netflix', 'spotify', 'concert', 'party'],
  };

  static ExpenseCategory classify(String description) {
    final lowerDesc = description.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (lowerDesc.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return ExpenseCategory.other;
  }
}
