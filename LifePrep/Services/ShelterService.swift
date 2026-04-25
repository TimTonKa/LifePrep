import Foundation
import SwiftData

final class ShelterService {
    static let shared = ShelterService()

    // 內政部消防署 — 避難收容處所點位 (全台 ~6,000 筆)
    private let csvURL = URL(string: "https://opdadm.moi.gov.tw/api/v1/no-auth/resource/api/dataset/ED6CF735-6C03-4573-A882-72C1BEC799CB/resource/54550E2F-4567-4C8F-BD2E-E54E9D0386B8/download")!

    // Returns parsed Shelter objects without touching any ModelContext.
    // The caller (on @MainActor) is responsible for inserting into SwiftData.
    func fetchShelterData() async throws -> [Shelter] {
        let (data, _) = try await URLSession.shared.data(from: csvURL)

        var csv = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .init(rawValue: 950)) // Big5 fallback
        guard var csvString = csv else {
            throw ShelterError.invalidEncoding
        }

        if csvString.hasPrefix("\u{FEFF}") { csvString.removeFirst() }

        let shelters = parseCSV(csvString)
        guard !shelters.isEmpty else { throw ShelterError.emptyData }
        return shelters
    }

    // CSV columns (0-indexed):
    // 0: 序號  1: 縣市及鄉鎮市區  2: 村里  3: 地址
    // 4: 經度  5: 緯度  6: 名稱  7: 預計收容村里
    // 8: 容納人數  9: 適用災害  10: 管理人  11: 電話
    // 12: 室內  13: 室外  14: 適合弱勢
    private func parseCSV(_ csv: String) -> [Shelter] {
        var lines = csv.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }
        lines.removeFirst() // header

        var shelters: [Shelter] = []
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let fields = parseCSVLine(trimmed)
            guard fields.count >= 13 else { continue }

            guard let lng = Double(fields[4].trimmingCharacters(in: .whitespaces)),
                  let lat = Double(fields[5].trimmingCharacters(in: .whitespaces)),
                  lat > 20, lat < 27, lng > 119, lng < 123 else { continue } // Taiwan bounds

            let capacity = Int(fields[8].trimmingCharacters(in: .whitespaces)) ?? 0

            shelters.append(Shelter(
                id: "shelter-\(index)-\(fields[0].trimmingCharacters(in: .whitespaces))",
                name: fields[6].trimmingCharacters(in: .whitespaces),
                address: fields[3].trimmingCharacters(in: .whitespaces),
                county: fields[1].trimmingCharacters(in: .whitespaces),
                village: fields[2].trimmingCharacters(in: .whitespaces),
                latitude: lat,
                longitude: lng,
                capacity: capacity,
                disasterTypes: fields[9].trimmingCharacters(in: .whitespaces),
                indoor: fields.count > 12 ? parseBool(fields[12]) : false,
                outdoor: fields.count > 13 ? parseBool(fields[13]) : false,
                suitableForVulnerable: fields.count > 14 ? parseBool(fields[14]) : false
            ))
        }
        return shelters
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }

    private func parseBool(_ s: String) -> Bool {
        let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return v == "1" || v == "true" || v == "是" || v == "y" || v == "yes" || v == "v"
    }

    enum ShelterError: LocalizedError {
        case invalidEncoding
        case emptyData

        var errorDescription: String? {
            switch self {
            case .invalidEncoding: return "無法解析避難所資料（編碼錯誤）"
            case .emptyData: return "避難所資料為空，請稍後再試"
            }
        }
    }
}
