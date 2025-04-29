// utils/categories.dart

import 'package:flutter/material.dart';

const Map<String, List<String>> categories = {
  'Expense': [
    'Food',
    'Transport',
    'School',
    'Rent',
    'Clothes',
    'Medicine',
    'Entertainment',
    'Utilities',
    'Other',
  ],
  'Income': ['Stipend', 'Family', 'State', 'Side Hustle', 'Other'],
};

const Map<String, Color> categoryColors = {
  'Food': Colors.red,
  'Transport': Colors.blue,
  'School': Colors.orange,
  'Rent': Colors.green,
  'Clothes': Colors.purple,
  'Medicine': Colors.teal,
  'Entertainment': Colors.pink,
  'Utilities': Colors.brown,
  'Other': Colors.grey,
  'Stipend': Colors.cyan,
  'Family': Colors.indigo,
  'State': Colors.lime,
  'Side Hustle': Colors.amber,
};