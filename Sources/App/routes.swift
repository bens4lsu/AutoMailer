import Fluent
import Vapor
import Foundation

func routes(_ app: Application) throws {
        
   
    
    app.get() { req -> Response in
        return try await "ok".encodeResponse(for: req)
    }

}
