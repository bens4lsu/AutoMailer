import Fluent
import FluentMySQLDriver
import Vapor
import QueuesFluentDriver
import Queues

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let settings = ConfigurationSettings()
    
    #if DEBUG
    var logger = Logger(label: "email.job.logger")
    logger.logLevel = settings.loggerLogLevel
    logger.warning("Running in debug.")
    #endif
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = settings.certificateVerification
    
    
    app.databases.use(.mysql(
        hostname: settings.database.hostname,
        port: settings.database.port,
        username: settings.database.username,
        password: settings.database.password,
        database: settings.database.database,
        tlsConfiguration: tls
    ), as: .mysql)
    
    app.queues.use(.fluent())
    app.migrations.add(JobMetadataMigrate())
    
    let emailJob = EmailJob(settings: settings)
    let retryJob = RetryJob(settings: settings)
    let cleanupJob = CleanupJob()
    
    // not running in-app
    // use 'swift run Run queues' from terminal

    app.queues.schedule(emailJob).minutely().at(5)   // doesn't run without the .at()
    app.queues.schedule(retryJob).hourly().at(01)
    app.queues.schedule(retryJob).hourly().at(31)
    app.queues.schedule(cleanupJob).daily().at(21, 12)
    try app.queues.startScheduledJobs()

    try routes(app)
}
