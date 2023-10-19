//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-19.
//

import Foundation
import Vapor
import Queues
import Fluent
import FluentMySQLDriver
import QueuesFluentDriver
import SMTPKitten


struct RetryJob: AsyncScheduledJob {
    
    let logger: Logger
    let retryCount: Int
    
    init(settings: ConfigurationSettings){
        
        var logger = Logger(label: "email.job.logger")
        logger.logLevel = settings.loggerLogLevel
        
#if DEBUG
        if logger.logLevel != .trace {
            logger.logLevel = .debug
        }
#endif
        
        self.logger = logger
        self.retryCount = settings.timesToRetry
    }
    
    func run(context: Queues.QueueContext) async throws {
        logger.debug("\(Date()) - Begin retry job run.")
        let failRecords = try await MailQueueModel.query(on: context.application.db).filter(\.$status == "F").filter(\.$retryCount <= retryCount).all()
        logger.debug("\(failRecords.count) failed jobs to retry.")
        for row in failRecords {
            row.status = "P"
            row.retryCount = row.retryCount + 1
            try await row.save(on: context.application.db)
        }
        logger.debug ("\(Date()) - Completed retry job run.")
        
    }
}
