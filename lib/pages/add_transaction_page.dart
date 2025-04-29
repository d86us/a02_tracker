import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../utils/categories.dart';

class AddTransactionPage extends StatefulWidget {
  final bool isExpense;
  final int? transactionId;
  final double? price;
  final String? category;
  final String? date;
  final String? description;

  const AddTransactionPage({
    super.key,
    required this.isExpense,
    this.transactionId,
    this.price,
    this.category,
    this.date,
    this.description,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _categoryWasSelected = false;

  static const String _defaultCategory = 'Select Category';

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransaction();
    } else {
      _selectedDate = DateTime.now();
      _selectedCategory = _defaultCategory;
    }
  }

  Future<void> _loadTransaction() async {
    final transaction = await DatabaseHelper().getTransactionById(
      widget.transactionId!,
    );

    if (transaction != null) {
      setState(() {
        _amountController.text =
            (transaction['amount'] as num).toInt().toString();
        _descriptionController.text = transaction['description'] ?? '';
        _selectedCategory = transaction['category'];
        _categoryWasSelected = true;
        try {
          _selectedDate = DateTime.parse(transaction['date']);
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate() &&
        _selectedCategory != _defaultCategory) {
      final amount = int.parse(_amountController.text);
      final formattedDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(_selectedDate);

      final transaction = {
        'amount': amount,
        'type': widget.isExpense ? 'Expense' : 'Income',
        'category': _selectedCategory,
        'date': formattedDate,
        'description':
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
      };

      if (widget.transactionId != null) {
        await DatabaseHelper().updateTransaction(
          transaction,
          widget.transactionId!,
        );
      } else {
        await DatabaseHelper().insertTransaction(transaction);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1500),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (picked.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
          _selectedDate = now;
        } else {
          _selectedDate = DateTime(picked.year, picked.month, picked.day, 8, 0);
        }
      });
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transactionId != null) {
      await DatabaseHelper().deleteTransaction(widget.transactionId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _confirmDelete() async {
    String transactionType = widget.isExpense ? 'expense' : 'income';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $transactionType?'),
          content: Text('Do you want to delete this $transactionType?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.close, color: Colors.white, size: 18),
                  SizedBox(width: 5),
                  Text('Cancel'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 0, 0),
              ),
              onPressed: () {
                _deleteTransaction();
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete, color: Colors.white, size: 18),
                  SizedBox(width: 5),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories =
        categories[widget.isExpense ? 'Expense' : 'Income']!;
    final List<String> dropdownItems =
        !_categoryWasSelected
            ? [_defaultCategory, ...availableCategories]
            : availableCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionId == null
              ? (widget.isExpense ? 'Add Expense' : 'Add Income')
              : (widget.isExpense ? 'Edit Expense' : 'Edit Income'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Category'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _defaultCategory) {
                    setState(() {
                      _selectedCategory = newValue;
                      _categoryWasSelected = true;
                    });
                  }
                },
                validator:
                    (value) =>
                        (value == null || value == _defaultCategory)
                            ? 'Please select a category'
                            : null,
                items:
                    dropdownItems.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            value == _defaultCategory
                                ? Text(value)
                                : Row(
                                  children: [
                                    Container(
                                      width: 15,
                                      height: 15,
                                      color:
                                          categoryColors[value] ?? Colors.grey,
                                      margin: const EdgeInsets.only(right: 10),
                                    ),
                                    Text(value),
                                  ],
                                ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 15),
              const Text('Amount'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: '0'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Enter amount'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('KSh'),
                ],
              ),
              const SizedBox(height: 15),
              const Text('Description'),
              TextFormField(controller: _descriptionController, maxLines: 1),
              const SizedBox(height: 15),
              const Text('Date'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: ListTile(
                  title: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Save'),
                  ],
                ),
              ),
              if (widget.transactionId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton(
                    onPressed: _confirmDelete,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete, color: Colors.black),
                        SizedBox(width: 5),
                        Text('Delete', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
