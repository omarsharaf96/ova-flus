import Foundation

struct Portfolio: Codable {
    let id: String
    var totalValue: Double
    var totalCost: Double
    var dayChange: Double
    var dayChangePercent: Double
    var holdings: [Holding]
    var lastUpdated: Date
}

struct Holding: Codable, Identifiable {
    let id: String
    var symbol: String
    var companyName: String
    var shares: Double
    var averageCost: Double
    var currentPrice: Double
    var currentValue: Double
    var dayChange: Double
    var dayChangePercent: Double
    var totalReturn: Double
    var totalReturnPercent: Double
}

struct StockQuote: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let companyName: String
    var price: Double
    var change: Double
    var changePercent: Double
    var open: Double
    var high: Double
    var low: Double
    var volume: Int
    var marketCap: Double
    var peRatio: Double?
    var week52High: Double
    var week52Low: Double
}
