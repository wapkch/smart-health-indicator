import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

extension URL {
    func appendingAPIPath(_ path: String) -> URL {
        var url = self
        for component in path.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        return url
    }
}
