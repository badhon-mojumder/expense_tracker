import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../widgets/summary_card.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';
import 'transaction_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = data;
      _isLoading = false;
    });
  }

  double get _totalIncome {
    return _transactions
        .where((item) => item.type == 'Income')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalExpense {
    return _transactions
        .where((item) => item.type == 'Expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _balance => _totalIncome - _totalExpense;

  Future<void> _addTransaction() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (added == true) _loadTransactions();
  }

  Future<void> _openDetails(TransactionModel transaction) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transactionId: transaction.id!,
        ),
      ),
    );
    if (changed == true) _loadTransactions();
  }

  Future<void> _openAllTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionListScreen()),
    );
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions = _transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'All transactions',
            onPressed: _openAllTransactions,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: const Color(0xFF315C4C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                children: [
                  const Text(
                    'Your money at a glance',
                    style: TextStyle(color: Color(0xFF68716C)),
                  ),
                  const SizedBox(height: 14),
                  SummaryCard(
                    title: 'Total Income',
                    amount: _totalIncome,
                    icon: Icons.south_west,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'Total Expense',
                    amount: _totalExpense,
                    icon: Icons.north_east,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 10),
                  SummaryCard(
                    title: 'Current Balance',
                    amount: _balance,
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF315C4C),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _openAllTransactions,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (recentTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 36, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No transactions yet'),
                          SizedBox(height: 4),
                          Text(
                            'Tap the + button to add your first transaction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentTransactions.map(
                      (transaction) => _RecentTransactionTile(
                        transaction: transaction,
                        onTap: () => _openDetails(transaction),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _RecentTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'Income';
    final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.10),
          child: Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            color: color,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${transaction.category} • ${DateFormat('dd MMM').format(DateTime.parse(transaction.date))}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ৳${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
