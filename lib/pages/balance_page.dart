import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../utils/categories.dart';
import 'package:intl/intl.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  late Future<List<Map<String, dynamic>>> transactions;
  int selectedTabIndex =
      0; // To keep track of the selected tab (Current month, Previous months, or Total)

  @override
  void initState() {
    super.initState();
    transactions = DatabaseHelper().getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;

    // Create a list of month abbreviations, starting from current month and going backwards
    List<String> monthNames = [];
    for (int i = 0; i < 3; i++) {
      DateTime monthDate = DateTime(now.year, currentMonth - i);
      String monthName = DateFormat.MMM().format(
        monthDate,
      ); // "MMM" will return abbreviated month name
      monthNames.add(monthName.toUpperCase());
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: transactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No transactions available.'));
        }

        final incomeCategories = categories['Income']!;
        final expenseCategories = categories['Expense']!;
        Map<String, double> categoryTotals = {};
        double totalIncome = 0;
        double totalExpense = 0;

        // Filter transactions based on selected tab
        List<Map<String, dynamic>> filteredTransactions = snapshot.data!;

        if (selectedTabIndex != 3) {
          // Total tab (index 3) shows all data
          final selectedMonth = selectedTabIndex;
          final startOfMonth = DateTime(
            now.year,
            currentMonth - selectedMonth,
            1,
          );
          final endOfMonth = DateTime(
            now.year,
            currentMonth - selectedMonth + 1,
            0,
          );

          filteredTransactions =
              filteredTransactions.where((transaction) {
                DateTime transactionDate = DateTime.parse(transaction['date']);
                return transactionDate.isAfter(
                      startOfMonth.subtract(const Duration(days: 1)),
                    ) &&
                    transactionDate.isBefore(
                      endOfMonth.add(const Duration(days: 1)),
                    );
              }).toList();
        }

        for (var transaction in filteredTransactions) {
          String category = transaction['category'];
          double amount = transaction['amount'];

          if (incomeCategories.contains(category)) {
            totalIncome += amount;
          } else if (expenseCategories.contains(category)) {
            totalExpense += amount;
          }

          if (expenseCategories.contains(category)) {
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }
        }

        double totalBalance = totalIncome - totalExpense;

        var sortedCategories =
            categoryTotals.entries.where((e) => e.key != 'Other').toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        if ((categoryTotals['Other'] ?? 0) > 0) {
          sortedCategories.add(MapEntry('Other', categoryTotals['Other']!));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // 4-tab switch for months, dynamically generated
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildTab(monthNames[0], 0), // Current month first
                      _buildTab(monthNames[1], 1),
                      _buildTab(monthNames[2], 2),
                      _buildTab('Total', 3),
                    ],
                  ),
                ),
              ),

              // Balance Summary
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow(
                      'Balance',
                      '${totalBalance.toInt()} KSh',
                      bold: true,
                    ),
                    _buildRow('Income', '+${totalIncome.toInt()} KSh'),
                    _buildRow('Expenses', '-${totalExpense.toInt()} KSh'),
                  ],
                ),
              ),

              // Pie Chart
              LayoutBuilder(
                builder: (context, constraints) {
                  double pieChartRadius = constraints.maxWidth / 2 - 15;

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth,
                    child: PieChart(
                      PieChartData(
                        sections:
                            sortedCategories.map((entry) {
                              final category = entry.key;
                              final amount = entry.value;
                              final color =
                                  categoryColors[category] ?? Colors.grey;

                              return PieChartSectionData(
                                value: amount,
                                color: color,
                                radius: pieChartRadius,
                                showTitle: false,
                              );
                            }).toList(),
                        centerSpaceRadius: 0,
                        startDegreeOffset: -90,
                        sectionsSpace: 0,
                      ),
                    ),
                  );
                },
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children:
                      sortedCategories.map((entry) {
                        final category = entry.key;
                        final amount = entry.value;
                        final color = categoryColors[category] ?? Colors.grey;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(width: 15, height: 15, color: color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '-${amount.toInt()} KSh',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build a single tab in the 4-tab switch
  Widget _buildTab(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedTabIndex == index ? Colors.black : Colors.white,
            borderRadius:
                index == 0
                    ? const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    )
                    : index == 3
                    ? const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    )
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selectedTabIndex == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
