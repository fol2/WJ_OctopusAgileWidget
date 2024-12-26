import SwiftUI
import Foundation
import CoreData

class OctopusAPIService {
    static let shared = OctopusAPIService()
    
    private init() {}
    
    func fetchAgileRates(completion: @escaping (Result<[AgileRate], Error>) -> Void) {
        // First try to load data from Core Data
        let storedRates = CoreDataService.shared.fetchAgileRates().map { entity -> AgileRate in
            return AgileRate(validFrom: entity.validFrom ?? Date(), validTo: entity.validTo ?? Date(), valueExcVat: entity.valueExcVat, valueIncVat: entity.valueIncVat)
        }
        
        // If we have stored rates, return them immediately and then fetch fresh data in background
        if !storedRates.isEmpty {
            completion(.success(storedRates))
        }
        
        // Check API key before making the request
        guard let apiKey = UserDefaults.standard.string(forKey: "apiKey"), !apiKey.isEmpty else {
            if storedRates.isEmpty {
                completion(.failure(NSError(domain: "OctopusAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not set or empty"])))
            }
            return
        }
        
        let urlString = "https://api.octopus.energy/v1/products/AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-H/standard-unit-rates/"
        guard var urlComponents = URLComponents(string: urlString) else {
            if storedRates.isEmpty {
                completion(.failure(NSError(domain: "OctopusAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            }
            return
        }
        
        // Add timezone parameter
        urlComponents.queryItems = [URLQueryItem(name: "timezone", value: "Europe/London")]
        
        guard let url = urlComponents.url else {
            if storedRates.isEmpty {
                completion(.failure(NSError(domain: "OctopusAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Basic \(Data("\(apiKey):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        
        print("Sending request to: \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                if storedRates.isEmpty {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code: \(httpResponse.statusCode)")
                // Check for non-200 status codes
                if !(200...299).contains(httpResponse.statusCode) {
                    if storedRates.isEmpty {
                        completion(.failure(NSError(domain: "OctopusAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                if storedRates.isEmpty {
                    completion(.failure(NSError(domain: "OctopusAPI", code: 204, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                }
                return
            }
            
            print("Received data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let agileRates = try decoder.decode(AgileRatesResponse.self, from: data)
                
                // Save newly fetched data to Core Data
                CoreDataService.shared.saveAgileRates(agileRates.results)
                
                // Only send completion if we didn't have stored rates
                if storedRates.isEmpty {
                    completion(.success(agileRates.results))
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                if storedRates.isEmpty {
                    completion(.failure(error))
                }
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