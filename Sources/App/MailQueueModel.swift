//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/4/22.
//

import Foundation
import Fluent
import FluentMySQLDriver
import SMTPKitten

class MailQueueModel: Model {
    typealias IDValue = Int
    
    static var schema = "MailQueue"
    
    @ID(custom: "MailID")
    var id: Int?
    
    @Field(key: "EmailAddressFrom")
    var addressFrom: String
    
    @Field(key: "EmailAddressTo")
    var addressTo: String
    
    @Field(key: "Subject")
    var subject: String
    
    @Field(key: "Body")
    var body: String
    
    @Field(key: "Status")
    var status: String
    
    @Field(key: "FromName")
    var fromName: String?
    
    @Field(key: "ToName")
    var toName: String?
    
    @Field(key: "PlainOrHtml")
    var plainOrHtml: String
    
    @Field(key: "RequestDate")
    var requestDate: Date
    
    @Field(key: "StatusDate")
    var statusDate: Date
    
    var contentType: SMTPKitten.Mail.ContentType {
        if self.plainOrHtml == "H" {
            return .html
        }
        else {
            return .plain
        }
    }
    
    required init() {

    }
    
}
