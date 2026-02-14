import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Map<String, dynamic>? portfolioData;
  Map<String, dynamic>? performanceData;
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final portfolios = await apiService.getPortfolios();
      if (portfolios.isNotEmpty) {
        portfolioData = portfolios[0];
        final perf = await apiService.getPortfolioPerformance(portfolioData!['id']);
        performanceData = perf;
        final trans = await apiService.getPortfolioTransactions(portfolioData!['id']);
        transactions = trans;
      }
    } catch (e) {
      print('Error loading portfolio: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (portfolioData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock Portfolio')),
        body: const Center(
          child: Text('No portfolio found. Create your first portfolio.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Portfolio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPortfolioData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Performance Overview
            if (performanceData != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Value',
                      '\$${performanceData!['totalValue'].toStringAsFixed(0)}',
                      '${performanceData!['holdingsCount']} holdings',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Cash',
                      '\$${performanceData!['cash'].toStringAsFixed(0)}',
                      'Available',
                      Colors.green,
                    ),
                  ),
                ],
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
            
            // Holdings
            const Text(
              'Holdings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            ..._buildHoldingCards(),
            
            const SizedBox(height: 24),
            
            // Transaction History
            if (transactions.isNotEmpty) ...[
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Column(
                  children: transactions.map((transaction) {
                    final shares = transaction['shares']?.toDouble() ?? 0;
                    final price = transaction['price']?.toDouble() ?? 0;
                    final fees = transaction['fees']?.toDouble() ?? 0;
                    final totalAmount = (shares * price) + fees;
                    
                    return ListTile(
                      title: Text(
                        '${transaction['type'].toString().toUpperCase()} ${transaction['symbol']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${shares.toStringAsFixed(0)} shares @ \$${price.toStringAsFixed(2)} • ${DateTime.parse(transaction['date']).toString().split(' ')[0]}',
                      ),
                      trailing: Text(
                        '${transaction['type'] == 'buy' ? '-' : '+'}\$${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction['type'] == 'buy' ? Colors.red : Colors.green,
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

  List<Widget> _buildHoldingCards() {
    final holdings = portfolioData!['holdings'] as List<dynamic>? ?? [];
    
    if (holdings.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No holdings yet. Add your first transaction to get started.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ];
    }
    
    return holdings.map((holding) {
      final shares = holding['shares']?.toDouble() ?? 0;
      final currentPrice = holding['currentPrice']?.toDouble() ?? 0;
      final avgPrice = holding['avgPurchasePrice']?.toDouble() ?? 0;
      final currentValue = shares * currentPrice;
      final cost = shares * avgPrice;
      final profitLoss = currentValue - cost;
      final profitLossPercent = cost > 0 ? (profitLoss / cost) * 100 : 0;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding['symbol'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shares.toStringAsFixed(0)} shares @ \$${currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Avg cost: \$${avgPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: profitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: profitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
