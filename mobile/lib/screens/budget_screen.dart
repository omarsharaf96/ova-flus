import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, dynamic>? budgetData;
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final budgets = await apiService.getBudgets();
      if (budgets.isNotEmpty) {
        budgetData = budgets[0];
        final trans = await apiService.getBudgetTransactions(budgetData!['id']);
        transactions = trans;
      }
    } catch (e) {
      print('Error loading budget: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _calculateTotalSpent() {
    if (budgetData == null) return 0;
    final categories = budgetData!['categories'] as List<dynamic>? ?? [];
    return categories.fold(0.0, (sum, cat) => sum + (cat['spent'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (budgetData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Tracking')),
        body: const Center(
          child: Text('No budget found. Create your first budget.'),
        ),
      );
    }

    final totalSpent = _calculateTotalSpent();
    final totalLimit = budgetData!['totalLimit']?.toDouble() ?? 0;
    final remaining = totalLimit - totalSpent;
    final usagePercent = totalLimit > 0 ? (totalSpent / totalLimit) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgetData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Budget',
                    '\$${totalLimit.toStringAsFixed(0)}',
                    budgetData!['period'],
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Spent',
                    '\$${totalSpent.toStringAsFixed(0)}',
                    '${usagePercent.toStringAsFixed(1)}%',
                    usagePercent > 90 ? Colors.red : usagePercent > 75 ? Colors.orange : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildStatCard(
              'Remaining',
              '\$${remaining.toStringAsFixed(0)}',
              '${((remaining / totalLimit) * 100).toStringAsFixed(1)}% available',
              remaining > 0 ? Colors.green : Colors.red,
            ),
            
            const SizedBox(height: 24),
            
            // Categories
            const Text(
              'Budget Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            ..._buildCategoryCards(),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            if (transactions.isNotEmpty) ...[
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Column(
                  children: transactions.map((transaction) {
                    final category = (budgetData!['categories'] as List).firstWhere(
                      (c) => c['id'] == transaction['categoryId'],
                      orElse: () => {'name': 'Unknown'},
                    );
                    
                    return ListTile(
                      title: Text(transaction['description']),
                      subtitle: Text(
                        '${category['name']} • ${DateTime.parse(transaction['date']).toString().split(' ')[0]}',
                      ),
                      trailing: Text(
                        '${transaction['type'] == 'expense' ? '-' : '+'}\$${transaction['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction['type'] == 'expense' ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryCards() {
    final categories = budgetData!['categories'] as List<dynamic>? ?? [];
    
    return categories.map((category) {
      final spent = category['spent']?.toDouble() ?? 0;
      final limit = category['limit']?.toDouble() ?? 0;
      final percentage = limit > 0 ? (spent / limit) * 100 : 0;
      final isOverBudget = spent > limit;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isOverBudget
                            ? 'Over by \$${(spent - limit).toStringAsFixed(0)}'
                            : 'Remaining: \$${(limit - spent).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: percentage > 100 ? 1.0 : percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 100
                      ? Colors.red
                      : percentage > 90
                          ? Colors.orange
                          : Colors.green,
                ),
                minHeight: 8,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
