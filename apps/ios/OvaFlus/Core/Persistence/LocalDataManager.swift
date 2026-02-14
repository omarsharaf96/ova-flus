import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()

    private let defaults = UserDefaults.standard
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("OvaFlusCache")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - UserDefaults storage

    func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - File-based cache for offline support

    func cacheData(_ data: Data, filename: String) {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try? data.write(to: fileURL)
    }

    func loadCachedData(filename: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    func cacheObject<T: Encodable>(_ object: T, filename: String) {
        if let data = try? encoder.encode(object) {
            cacheData(data, filename: filename)
        }
    }

    func loadCachedObject<T: Decodable>(filename: String) -> T? {
        guard let data = loadCachedData(filename: filename) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
