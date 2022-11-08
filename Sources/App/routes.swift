import Fluent
import Vapor
import Foundation

func routes(_ app: Application) throws {
        
   
    
    app.get() { req -> Response in
        let settings = ConfigurationSettings()
        let cm = ConcordMail(configKeys: settings)
        let _ = try await cm.testMail()
        return try await "ok".encodeResponse(for: req)
    }

}
