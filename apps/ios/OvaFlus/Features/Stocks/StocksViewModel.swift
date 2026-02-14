import Foundation

struct ChartDataPoint {
    let date: Date
    let value: Double
}

struct NewsArticle: Codable {
    let title: String
    let source: String
    let publishedAt: Date
    let url: String
}

@MainActor
class StocksViewModel: ObservableObject {
    @Published var portfolio: Portfolio?
    @Published var watchlist: [StockQuote] = []
    @Published var selectedQuote: StockQuote?
    @Published var chartData: [ChartDataPoint] = []
    @Published var news: [NewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    func fetchPortfolio() async {
        isLoading = true
        do {
            portfolio = try await apiClient.request(.getPortfolio)
            // Generate sample chart data based on portfolio value
            if let value = portfolio?.totalValue {
                chartData = generateChartData(baseValue: value)
            }
        } catch {
            errorMessage = "Failed to load portfolio"
        }
        isLoading = false
    }

    func fetchWatchlist() async {
        isLoading = true
        do {
            watchlist = try await apiClient.request(.getWatchlist)
        } catch {
            errorMessage = "Failed to load watchlist"
        }
        isLoading = false
    }

    func fetchStockDetail(symbol: String) async {
        isLoading = true
        do {
            selectedQuote = try await apiClient.request(.getStockQuote(symbol: symbol))
            if let price = selectedQuote?.price {
                chartData = generateChartData(baseValue: price)
            }
            news = try await apiClient.request(.getStockNews(symbol: symbol))
        } catch {
            errorMessage = "Failed to load stock details"
        }
        isLoading = false
    }

    func removeFromWatchlist(_ symbol: String) async {
        do {
            let _: EmptyResponse = try await apiClient.request(.removeFromWatchlist(symbol: symbol))
            watchlist.removeAll { $0.symbol == symbol }
        } catch {
            errorMessage = "Failed to remove from watchlist"
        }
    }

    private func generateChartData(baseValue: Double, days: Int = 30) -> [ChartDataPoint] {
        let calendar = Calendar.current
        return (0..<days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -days + dayOffset, to: Date()) ?? Date()
            let randomVariation = Double.random(in: -0.03...0.03)
            let value = baseValue * (1 + randomVariation * Double(dayOffset) / Double(days))
            return ChartDataPoint(date: date, value: value)
        }
    }
}
