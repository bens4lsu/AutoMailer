//
//  File.swift
//  
//
//  Created by Ben Schultz on 10/9/22.
//

import Vapor
import NIOSSL

class ConfigurationSettings: Decodable {
    
    struct Database: Decodable {
        let hostname: String
        let port: Int
        let username: String
        let password: String
        let database: String
        let certificateVerificationString: String
    }
    
    struct Smtp: Codable {
        var hostname: String
        var port: Int32
        var username: String
        var password: String
        var timeout: UInt
    }
    
    let database: ConfigurationSettings.Database
    let smtp: ConfigurationSettings.Smtp
    let logLevel: String
    //let maxConcurrentEmailTasks: Int
    let timesToRetry: Int
    
    
    var certificateVerification: CertificateVerification {
        if database.certificateVerificationString == "noHostnameVerification" {
            return .noHostnameVerification
        }
        else if database.certificateVerificationString == "fullVerification" {
            return .fullVerification
        }
        return .none
    }
    
    var loggerLogLevel: Logger.Level {
        Logger.Level(rawValue: logLevel) ?? .error
    }
    
    init() {
        let path = DirectoryConfiguration.detect().resourcesDirectory
        let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
        do {
            let data = try Data(contentsOf: url)
            let decoder = try JSONDecoder().decode(ConfigurationSettings.self, from: data)
            self.database = decoder.database
            self.smtp = decoder.smtp
            self.logLevel = decoder.logLevel
            //self.maxConcurrentEmailTasks = decoder.maxConcurrentEmailTasks
            self.timesToRetry = decoder.timesToRetry
        }
        catch {
            print ("Could not initialize app from Config.json. \n \(error)")
            exit(0)
        }
    }
}

