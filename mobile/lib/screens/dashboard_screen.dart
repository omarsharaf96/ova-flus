import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? budgetData;
  Map<String, dynamic>? portfolioData;
  Map<String, dynamic>? performanceData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final budgets = await apiService.getBudgets();
      if (budgets.isNotEmpty) {
        budgetData = budgets[0];
      }

      final portfolios = await apiService.getPortfolios();
      if (portfolios.isNotEmpty) {
        portfolioData = portfolios[0];
        final performance = await apiService.getPortfolioPerformance(
          portfolioData!['id'],
        );
        performanceData = performance;
      }
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _calculateBudgetSpent() {
    if (budgetData == null) return 0;
    final categories = budgetData!['categories'] as List<dynamic>? ?? [];
    return categories.fold(0.0, (sum, cat) => sum + (cat['spent'] ?? 0));
  }

  double _calculateBudgetLimit() {
    return budgetData?['totalLimit']?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final budgetSpent = _calculateBudgetSpent();
    final budgetLimit = _calculateBudgetLimit();
    final budgetRemaining = budgetLimit - budgetSpent;
    final budgetPercent = budgetLimit > 0 ? (budgetSpent / budgetLimit) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 OVA FLUS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Overview of your budget and portfolio',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Budget Stats
              _buildStatCard(
                'Total Budget',
                '\$${budgetLimit.toStringAsFixed(0)}',
                'Monthly limit',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              
              _buildStatCard(
                'Budget Remaining',
                '\$${budgetRemaining.toStringAsFixed(0)}',
                '${budgetPercent.toStringAsFixed(1)}% used',
                budgetPercent > 90
                    ? Colors.red
                    : budgetPercent > 75
                        ? Colors.orange
                        : Colors.green,
              ),
              const SizedBox(height: 12),
              
              // Portfolio Stats
              if (performanceData != null) ...[
                _buildStatCard(
                  'Portfolio Value',
                  '\$${performanceData!['totalValue'].toStringAsFixed(0)}',
                  'Total assets',
                  Colors.green,
                ),
                const SizedBox(height: 12),
                
                _buildStatCard(
                  'Profit/Loss',
                  '${performanceData!['profitLoss'] >= 0 ? '+' : ''}\$${performanceData!['profitLoss'].toStringAsFixed(2)}',
                  '${performanceData!['returnPercentage'] >= 0 ? '+' : ''}${performanceData!['returnPercentage'].toStringAsFixed(2)}% return',
                  performanceData!['profitLoss'] >= 0 ? Colors.green : Colors.red,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Budget Categories
              if (budgetData != null) ...[
                const Text(
                  'Budget Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBudgetCategories(),
              ],
              
              const SizedBox(height: 24),
              
              // Portfolio Holdings
              if (portfolioData != null) ...[
                const Text(
                  'Portfolio Holdings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildPortfolioHoldings(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategories() {
    final categories = budgetData!['categories'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: categories.map((category) {
            final spent = category['spent']?.toDouble() ?? 0;
            final limit = category['limit']?.toDouble() ?? 0;
            final percentage = limit > 0 ? (spent / limit) * 100 : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 90
                          ? Colors.red
                          : percentage > 75
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPortfolioHoldings() {
    final holdings = portfolioData!['holdings'] as List<dynamic>? ?? [];
    
    return Card(
      child: Column(
        children: holdings.map((holding) {
          final shares = holding['shares']?.toDouble() ?? 0;
          final currentPrice = holding['currentPrice']?.toDouble() ?? 0;
          final avgPrice = holding['avgPurchasePrice']?.toDouble() ?? 0;
          final currentValue = shares * currentPrice;
          final cost = shares * avgPrice;
          final profitLoss = currentValue - cost;
          final profitLossPercent = cost > 0 ? (profitLoss / cost) * 100 : 0;
          
          return ListTile(
            title: Text(
              holding['symbol'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${shares.toStringAsFixed(0)} shares @ \$${currentPrice.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)} (${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: profitLoss >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
