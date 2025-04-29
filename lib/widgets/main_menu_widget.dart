import 'package:flutter/material.dart';
import '../pages/balance_page.dart';
import '../pages/transactions_page.dart'; // Import the new TransactionsPage
import '../pages/user_page.dart';

class MainMenuWidget extends StatefulWidget {
  const MainMenuWidget({super.key});

  @override
  _MainMenuWidgetState createState() => _MainMenuWidgetState();
}

class _MainMenuWidgetState extends State<MainMenuWidget> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Balance',
    'Expenses',
    'Income',
    'User Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const BalancePage();
      case 1:
        return TransactionsPage(
          key: ValueKey('expenses'),
          isExpense: true,
        ); // <-- no const
      case 2:
        return TransactionsPage(
          key: ValueKey('income'),
          isExpense: false,
        ); // <-- no const
      case 3:
        return const UserPage();
      default:
        return const BalancePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _getPage(_selectedIndex), // <- build dynamically
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Balance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.remove), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Income'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'User',
          ),
        ],
      ),
    );
  }
}
