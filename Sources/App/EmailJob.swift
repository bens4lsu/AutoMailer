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
import SMTPKitten



struct EmailJob: AsyncScheduledJob {

    let logger: Logger
    let smtp: ConfigurationSettings.Smtp
    //let maxConcurrentEmailTasks: Int

    init(settings: ConfigurationSettings){
        
        var logger = Logger(label: "email.job.logger")
        logger.logLevel = settings.loggerLogLevel
        
        #if DEBUG
        if logger.logLevel != .trace {
            logger.logLevel = .debug
        }
        #endif
        
        self.logger = logger
        self.smtp = settings.smtp
        //self.maxConcurrentEmailTasks = settings.maxConcurrentEmailTasks
    }
    
    func run(context: Queues.QueueContext) async throws {
        logger.debug("\(Date()) - Begin email job run.")
        let queue = try await MailQueueModel.query(on: context.application.db).filter(\.$status == "P").all()
        
        for mailreq in queue {
            try await processOneEmail(context: context, mailreq: mailreq)
        }
        
        logger.debug ("\(Date()) - Completed email job run.")
            
    }
    
    private func processOneEmail(context: Queues.QueueContext, mailreq: MailQueueModel) async throws {
        do {
            mailreq.status = "W" //working
            try await mailreq.save(on: context.application.db)
            
            
            var mail = SMTPKitten.Mail(from: SMTPKitten.MailUser(name: mailreq.fromName, email: mailreq.addressFrom),
                                       to: [SMTPKitten.MailUser(name: mailreq.toName, email: mailreq.addressTo)],
                                       cc: Set<SMTPKitten.MailUser>(),
                                       subject: mailreq.subject,
                                       content: mailreq.content(mailreq.body)
            )
            
            #if DEBUG
            mail.to = [SMTPKitten.MailUser(name: mailreq.toName, email: "ben@concordbusinessservicesllc.com")]
            #endif
            
            logger.info("\(Date()) - Send \"\(mailreq.subject) to \(mailreq.addressTo)")
            try await send(mail)
            mailreq.status = "C"
            mailreq.statusDate = Date()
            mailreq.retryCount = 0
            try await mailreq.save(on: context.application.db)
        }
        catch(let error) {
            mailreq.status = "F"
            mailreq.statusDate = Date()
            logger.error("\(error)")
            try await mailreq.save(on: context.application.db)
        }
        
    }
    
    
    private func send(_ mail: SMTPKitten.Mail) async throws  {
        let client = try await SMTPClient.connect(hostname: smtp.hostname, ssl: .startTLS(configuration: .default))
        logger.debug("Starting SMTP login.  host: \(smtp.hostname)    user: \(smtp.username)")
        try await client.login(user: smtp.username, password: smtp.password)
        logger.debug("Starting SMTP send.")
        try await client.sendMail(mail)
        logger.debug("SMTP send complete.")

    }
}
