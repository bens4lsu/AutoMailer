//
//  File.swift
//  
//
//  Created by Ben Schultz on 2024-03-21.
//

import Vapor
import Foundation
import Queues
import Fluent
import FluentMySQLDriver
import QueuesFluentDriver
import SMTPKitten



struct CleanupJob: AsyncScheduledJob {
    func run(context: Queues.QueueContext) async throws {
        
        guard let deleteDate = Calendar.current.date(byAdding: .month, value: -2, to: Date()) else {
            return
        }
        
        try await MailQueueModel.query(on: context.application.db)
            .filter(\.$statusDate < deleteDate)
            .delete()
    }
    
    
}
