import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  TransactionModel? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    final result = await DatabaseHelper.instance
        .getTransactionById(widget.transactionId);
    if (!mounted) return;
    setState(() {
      _transaction = result;
      _isLoading = false;
    });
  }

  Future<void> _editTransaction() async {
    final current = _transaction;
    if (current == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: current),
      ),
    );

    if (changed == true) {
      setState(() => _isLoading = true);
      await _loadTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _transaction?.id != null) {
      await DatabaseHelper.instance.deleteTransaction(_transaction!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final isIncome = transaction?.type == 'Income';
    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : transaction == null
              ? const Center(child: Text('Transaction not found.'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: amountColor,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              transaction.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${isIncome ? '+' : '-'} ৳ ${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _detailRow('Category', transaction.category),
                      _detailRow('Type', transaction.type),
                      _detailRow(
                        'Date',
                        DateFormat('dd MMM yyyy').format(
                          DateTime.parse(transaction.date),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _editTransaction,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Transaction'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _deleteTransaction,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Transaction'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
