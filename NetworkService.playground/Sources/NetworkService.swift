import Foundation

/*
 
 The layer should be independent of the models so the transformation should take
 place in the datasource, in the data layer of the app. Following the SOLID
 principles and the clean architecture, the network service should be the one
 responsible on ask for data and return it back
 
 */

public protocol NetworkServiceProtocol { // Allows us to test the datasource
    func request(
        endpoint: String,
        headers: [String: String],
        queryItems: [String : String],
        body: [String:Any]?,
        httpMethod: HTTPMethod
    ) async throws -> Data
}

public final class NetworkService: NetworkServiceProtocol {
    
    private let url: String
    private let defaultHeaders: [String: String]
    private let urlSession: URLSession

    public init(
        url: String,
        defaultHeaders: [String:String] = [:],
        urlSession: URLSession = URLSession.shared
    ) {
        self.url = url
        self.defaultHeaders = defaultHeaders
        self.urlSession = urlSession
    }

    public func request(
        endpoint: String,
        headers: [String: String] = [:],
        queryItems: [String : String] = [:],
        body: [String:Any]? = nil,
        httpMethod: HTTPMethod
    ) async throws -> Data {
        let urlRequest = try createURLRequest(
            endpoint: endpoint,
            headers: headers,
            queryItems: queryItems,
            body: body,
            httpMethod: httpMethod)
        return try await request(urlRequest)
    }

}

// MARK: - Private methods

private extension NetworkService {
    
    func createURLRequest(
        endpoint: String,
        headers: [String: String],
        queryItems: [String : String],
        body: [String:Any]? = nil,
        httpMethod: HTTPMethod
    ) throws -> URLRequest {
        
        guard var urlComponent = URLComponents(string: url + "\(endpoint)") else {
            throw APIError.wrongUrl(description: url)
        }
        
        if !queryItems.isEmpty {
            var urlQueryItems: [URLQueryItem] = []
            
            queryItems.forEach {
                let urlQueryItem = URLQueryItem(name: $0.key, value: $0.value)
                urlComponent.queryItems?.append(urlQueryItem)
                urlQueryItems.append(urlQueryItem)
            }
            
            urlComponent.queryItems = urlQueryItems
        }
        
        guard let url = urlComponent.url else {
            throw APIError.urlComponentsFailure(description: urlComponent.url?.absoluteString ?? "No URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        
        let queryHeaders = defaultHeaders.merging(headers, uniquingKeysWith: { (first, _) in first })
        urlRequest.allHTTPHeaderFields = queryHeaders
        
        if let body = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                urlRequest.httpBody = jsonData
            } catch {
                throw APIError.jsonConversionFailure(description: "Error parsing the request body")
            }
        }

        return urlRequest
    }
    
    func request(
        _ request: URLRequest
    ) async throws -> Data {

        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(description: "Unvalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw handleApiErrors(httpResponse: httpResponse, data: data)
        }

        return data
    }

    func handleApiErrors(
        httpResponse: HTTPURLResponse,
        data: Data
    ) -> Error {
        
        guard (500...599).contains(httpResponse.statusCode) else {
            return APIError.serverError
        }
        
        guard httpResponse.statusCode != 401 else {
            return APIError.notAuthorized
        }
        
        let errorData = String(decoding: data, as: UTF8.self)
        return APIError.responseUnsuccessful(description: "Status code: \(httpResponse.statusCode), description: \(errorData)")
    }
}
