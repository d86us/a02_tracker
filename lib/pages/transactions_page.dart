import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'add_transaction_page.dart';
import '../database/database_helper.dart';
import '../utils/categories.dart';

class TransactionsPage extends StatefulWidget {
  final bool isExpense;

  const TransactionsPage({super.key, required this.isExpense});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactionsFuture = DatabaseHelper().getTransactionsByType(
      widget.isExpense ? 'Expense' : 'Income',
    );
  }

  void _navigateToAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(isExpense: widget.isExpense),
      ),
    );
    setState(() => _loadTransactions());
  }

  String formatAmount(num amount) {
    // Display with + for income and - for expenses
    if (widget.isExpense) {
      return '-${amount.toInt()} KSh'; // For expenses
    } else {
      return '+${amount.toInt()} KSh'; // For income
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(date); // Jan 23, 1525
      } else {
        return timeago.format(date); // 2 days ago, 4 hours ago
      }
    } catch (e) {
      // Handle invalid date format or null date
      return 'Invalid Date'; // Return a default value when the date is invalid
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          content = Expanded(
            child: Center(
              child: Text(
                widget.isExpense
                    ? 'No Expenses Available.'
                    : 'No Income Available.',
              ),
            ),
          );
        } else {
          content = Expanded(
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var transaction = snapshot.data![index];
                Color color =
                    categoryColors[transaction['category']] ?? Colors.black;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddTransactionPage(
                              isExpense: widget.isExpense,
                              transactionId: transaction['id'],
                              price: transaction['amount']?.toDouble(),
                              category: transaction['category'],
                              date: transaction['date'],
                              description: transaction['description'],
                            ),
                      ),
                    ).then((_) => setState(() => _loadTransactions()));
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 15.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.rectangle,
                                    ),
                                  ),
                                  Text(
                                    transaction['category'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formatAmount(transaction['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  transaction['description']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? transaction['description']
                                      : '',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                formatDate(transaction['date']),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ElevatedButton(
                onPressed: _navigateToAddTransaction,
                child: Text(widget.isExpense ? 'Add Expense' : 'Add Income'),
              ),
            ),
            Divider(
              thickness: 2,
              height: 2, // Add this line
              color: Colors.black,
            ),
            content,
          ],
        );
      },
    );
  }
}
