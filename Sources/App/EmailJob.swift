//
//  File.swift
//  
//
//  Created by Ben Schultz on 10/9/22.
//

import Vapor
import Foundation
import Queues
import Fluent
import FluentMySQLDriver
import QueuesFluentDriver


struct EmailJob: AsyncScheduledJob {

    let cmail: ConcordMail
    let logger: Logger

    init(settings: ConfigurationSettings){
        self.cmail = ConcordMail(configKeys: settings)
        var logger = Logger(label: "email.job.logger")
        logger.logLevel = settings.loggerLogLevel
        
        #if DEBUG
        if logger.logLevel != .trace {
            logger.logLevel = .debug
        }
        #endif
        
        self.logger = logger
    }
    
    func run(context: Queues.QueueContext) async throws {
        logger.debug("\(Date()) - Begin email job run.")
        let queue = try await MailQueueModel.query(on: context.application.db).filter(\.$status == "P").all()
        await withThrowingTaskGroup(of: ConcordMail.Result.self) { taskGroup in
            for mailreq in queue {
                taskGroup.addTask {
                    return try await sendOneEmail(db: context.application.db, mailreq: mailreq)
                }
            }
        }
        logger.debug ("\(Date()) - Completed email job run.")
            
    }
    
    private func sendOneEmail(db: Database, mailreq: MailQueueModel) async throws -> ConcordMail.Result {
        mailreq.status = "W" //working
        try await mailreq.save(on: db)
        var mail = ConcordMail.Mail(
            from: ConcordMail.Mail.User(name: mailreq.fromName, email: mailreq.addressFrom),
            to: ConcordMail.Mail.User(name: mailreq.fromName, email: mailreq.addressFrom),
            subject: mailreq.subject,
            contentType: mailreq.contentType,
            text: mailreq.body
        )
        
        #if DEBUG
            mail.to = ConcordMail.Mail.User(name: "ben@concordbusinessservicesllc.com", email: "ben@concordbusinessservicesllc.com")
        #endif
        
        
        logger.info("\(Date()) - Send \"\(mailreq.subject) to \(mailreq.addressTo)")
        let result = try await cmail.send(mail: mail)
        switch result {
        case .success:
            mailreq.status = "C"
            break
        case .failure(let err):
            mailreq.status = "F"
            logger.error("\(Date()) - Mail send error: \(err)")
        }
        mailreq.statusDate = Date()
        try await mailreq.save(on: db)
        return result
        
    }
}
