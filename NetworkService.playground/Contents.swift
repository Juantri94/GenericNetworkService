import Foundation
import _Concurrency
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - Api endpoints

// https://gorest.co.in/

enum GoRestApiEndpoints {
    case users(String?)
    
    var endpoint: String {
        switch self {
        case .users(let userId):
            if let userId = userId {
                return "users/\(userId)"
            }
            return "users"
        }
    }
}

// MARK: - User model

struct User: Codable {
    var id: Int
    var name: String
    var email: String
    var gender: String
    var status: String
}

// MARK: - Datasource

final class ApiDatasource {
    
    private let networkService: NetworkServiceProtocol
    private var token = "4c186d229582f7524b9d7cdd457f07fca3b9e50096eb2adde3326e38d176c9cb"
    
    init(
        networkService: NetworkServiceProtocol
    ) {
        self.networkService = networkService
    }
    
    func getUsers() async throws {
        let responseData = try await service.request(
            endpoint: GoRestApiEndpoints.users(nil).endpoint,
            httpMethod: .get)
        let users = try decodeData(responseData, type: [User].self)
        print(users.count)
    }

    func getUser() async throws {
        let responseData = try await service.request(
            endpoint: GoRestApiEndpoints.users("3527").endpoint,
            httpMethod: .get)
        let user = try decodeData(responseData, type: User.self)
        print(user)
    }

    func createUser() async throws {
        let params = [ "name":"My User", "gender":"male", "email":"my.user9@qwertyu.com", "status":"active" ]
        let responseData = try await service.request(
            endpoint: GoRestApiEndpoints.users(nil).endpoint,
            headers: ["Authorization": "Bearer \(token)"],
            body: params,
            httpMethod: .post)
        let user = try decodeData(responseData, type: User.self)
        print(user)
    }

    func deleteUser() async throws {
        let responseData = try await service.request(
            endpoint: GoRestApiEndpoints.users("2746").endpoint,
            headers: ["Authorization": "Bearer \(token)"],
            httpMethod: .delete)
        print("Delete success: \(responseData.isEmpty)")
    }

}

private extension ApiDatasource {
    
    private func decodeData<T: Decodable>(
        _ data: Data,
        type: T.Type
    ) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.jsonConversionFailure(description: "Error parsing the data: \(error.localizedDescription)")
        }
    }

}

// MARK: - Implementation

let defaultHeaders = [
    "Accept":"application/json",
    "Content-Type":"application/json"
]

let service = NetworkService(
    url: "https://gorest.co.in/public/v2/",
    defaultHeaders: defaultHeaders)

let datasource = ApiDatasource(networkService: service)

Task {
    do {
        try await datasource.getUsers()
    } catch {
        print(error)
    }
}
