import Foundation

struct Holding: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let quantity: Double
    let avgCost: Double
    var currentPrice: Double

    var currentValue: Double { quantity * currentPrice }
    var totalCost: Double { quantity * avgCost }
    var gain: Double { currentValue - totalCost }
    var gainPercent: Double { totalCost > 0 ? (gain / totalCost) * 100 : 0 }
}

struct Portfolio: Identifiable, Codable {
    let id: String
    let name: String
    var holdings: [Holding]
    let createdAt: Date
    let updatedAt: Date

    var totalValue: Double { holdings.reduce(0) { $0 + $1.currentValue } }
    var totalGain: Double { holdings.reduce(0) { $0 + $1.gain } }
}
