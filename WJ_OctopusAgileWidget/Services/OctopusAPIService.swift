import SwiftUI
import Foundation

class OctopusAPIService {
    static let shared = OctopusAPIService()
    
    private init() {}
    
    func fetchAgileRates(completion: @escaping (Result<[AgileRate], Error>) -> Void) {
        // 首先嘗試從Core Data加載數據
        let storedRates = CoreDataService.shared.fetchAgileRates().map { entity -> AgileRate in
            return AgileRate(validFrom: entity.validFrom ?? Date(), validTo: entity.validTo ?? Date(), valueExcVat: entity.valueExcVat, valueIncVat: entity.valueIncVat)
        }
        
        if !storedRates.isEmpty {
            completion(.success(storedRates))
        }
        
        // 然後繼續獲取新數據
        guard let apiKey = UserDefaults.standard.string(forKey: "apiKey"), !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "OctopusAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "API密鑰未設置或為空"])))
            return
        }
        
        let urlString = "https://api.octopus.energy/v1/products/AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-H/standard-unit-rates/"
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NSError(domain: "OctopusAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "無效的URL"])))
            return
        }
        
        // 添加時區參數
        urlComponents.queryItems = [URLQueryItem(name: "timezone", value: "Europe/London")]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "OctopusAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "無效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Basic \(Data("\(apiKey):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        
        print("發送請求到: \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("網絡錯誤: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP狀態碼: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("沒有接收到數據")
                completion(.failure(NSError(domain: "OctopusAPI", code: 204, userInfo: [NSLocalizedDescriptionKey: "沒有數據"])))
                return
            }
            
            print("接收到的數據: \(String(data: data, encoding: .utf8) ?? "無法解碼")")
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let agileRates = try decoder.decode(AgileRatesResponse.self, from: data)
                
                // 保存新獲取的數據到Core Data
                CoreDataService.shared.saveAgileRates(agileRates.results)
                
                completion(.success(agileRates.results))
            } catch {
                print("解碼錯誤: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

struct AgileRatesResponse: Codable {
    let results: [AgileRate]
}

struct AgileRate: Codable, Identifiable {
    let id = UUID()
    let validFrom: Date
    let validTo: Date
    let valueExcVat: Double
    let valueIncVat: Double
    
    enum CodingKeys: String, CodingKey {
        case validFrom = "valid_from"
        case validTo = "valid_to"
        case valueExcVat = "value_exc_vat"
        case valueIncVat = "value_inc_vat"
    }
}