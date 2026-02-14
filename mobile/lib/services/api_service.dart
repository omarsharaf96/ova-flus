import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Budget API
  Future<List<dynamic>> getBudgets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/budgets'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching budgets: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBudgetById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/budgets/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching budget: $e');
      return null;
    }
  }

  Future<List<dynamic>> getBudgetTransactions(String budgetId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budgets/$budgetId/transactions'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<bool> addTransaction(String budgetId, Map<String, dynamic> transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/budgets/$budgetId/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  // Portfolio API
  Future<List<dynamic>> getPortfolios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/portfolios'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching portfolios: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPortfolioById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/portfolios/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching portfolio: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPortfolioPerformance(String portfolioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/portfolios/$portfolioId/performance'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching performance: $e');
      return null;
    }
  }

  Future<List<dynamic>> getPortfolioTransactions(String portfolioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/portfolios/$portfolioId/transactions'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<bool> addPortfolioTransaction(
    String portfolioId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/portfolios/$portfolioId/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  // Stock API
  Future<Map<String, dynamic>?> getStockQuote(String symbol) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stocks/quote/$symbol'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching stock quote: $e');
      return null;
    }
  }

  Future<List<dynamic>> searchStocks(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stocks/search?q=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }
}
